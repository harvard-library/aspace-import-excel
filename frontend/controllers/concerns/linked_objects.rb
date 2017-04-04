module LinkedObjects
  extend ActiveSupport::Concern
# This module incorporates all the classes needed to handle objects that must be linked to
# Archival Objects, such as Subjects, Top Containers, etc.

# a lot of this is adapted from Hudson Mlonglo's Arrearage plugin:
#https://github.com/hudmol/nla_staff_spreadsheet_importer/blob/master/backend/converters/arrearage_converter.rb

  class DigitalObjectHandler < Handler
    @@digital_object_types ||= EnumList.new('digital_object_digital_object_type')

    def self.renew
      clear(@@digital_object_types)
    end
  end  # DigitalObjectHandler

# one of the differences is that we don't care about location, and we do lookup against the database

  class ContainerInstanceHandler < Handler

    @@top_containers = {}
    @@container_types ||= EnumList.new('container_type')
    @@instance_types ||= EnumList.new('instance_instance_type') # for when we move instances over here


    def self.renew
      clear( @@container_types)
      clear(@@instance_types)
    end

    def self.key_for(top_container)
      key = "#{top_container[:type]}: #{top_container[:indicator]}"
      key += " #{top_container[:barcode]}" if top_container[:barcode]
      key
    end
    
    def self.build(row)
      {
        :type => @@container_types.value(row.fetch('type_1', 'Box')),
        :indicator => row.fetch('indicator_1', 'Unknown'),
        :barcode => row.fetch('barcode',nil)
      }
    end
    
    # returns a top container JSONModel
    def self.get_or_create(row, resource)
      top_container = build(row)
      tc_key = key_for(top_container)
#      Pry::ColorPrinter.pp " tc key: #{tc_key}"
      # check to see if we already have fetched one from the db, or created one.
      if !(existing_tc = @@top_containers.fetch(tc_key, false))
        if !(existing_tc = get_db_tc(top_container, resource))
          tc = JSONModel(:top_container).new._always_valid!
          tc.type = top_container[:type]
          tc.indicator = top_container[:indicator]
          tc.barcode = top_container[:barcode] if top_container[:barcode] 
          tc.repository = {'ref' => resource.split('/')[0..2].join('/')}
#          UpdateUtils.test_exceptions(tc,'top_container')
#          Pry::ColorPrinter.pp ["About to save", tc]
          tc.save
          existing_tc = tc
        end
#        Pry::ColorPrinter.pp "Existing tc key: #{tc_key}"
        @@top_containers[tc_key] = existing_tc
      end
# Pry::ColorPrinter.pp ["exisiting tc", existing_tc]
      existing_tc
    end

    def self.get_db_tc(top_container, resource_uri)
      repo_idnum = resource_uri.split('/')[2]
      ret_tc = nil
      tc_str = "#{top_container[:type]} #{top_container[:indicator]}"
      tc_str += " [#{top_container[:barcode]}]" if top_container[:barcode]
      tc_params = {}
      tc_params["type[]"] = 'top_container'
      tc_params["q"] = "display_string:\"#{tc_str}\" AND collection_uri_u_sstr:\"#{resource_uri}\""
      ret_tc = search(repo_idnum,tc_params, :top_container)
      Pry::ColorPrinter.pp "FOUND NADA in the DB" if !ret_tc
      ret_tc
    end

    def self.create_container_instance(row, resource_uri)
      instance = nil
      if row['type']
        begin
          tc = get_or_create(row, resource_uri)
          sc = {'top_container' => {'ref' => tc.uri},
            'jsonmodeltype' => 'sub_container'}
          %w(2 3).each do |num|
            if row["type_#{num}"]
              sc["type_#{num}"] = @@container_types.value(row["type_#{num}"])
              sc["indicator_#{num}"] = row["indicator_#{num}"]
            end
          end
          instance = JSONModel(:instance).new._always_valid!
          instance.instance_type = @@instance_types.value(row['type'])
          instance.sub_container = JSONModel(:sub_container).from_hash(sc)
        rescue ExcelImportException => ee
          instance = nil
          raise ExcelImportException.new(I18n.t('plugins.aspace-import-excel.no_container_instance', :why => ee.message))
        rescue Exception => e
          msg = e.message + "\n" + e.backtrace()[0]
          instance = nil
          ExcelImportException.new(I18n.t('plugins.aspace-import-excel.no_container_instance', :why => msg))
        end
      end
      instance
    end

  end  # of container handler

  #shamelessly stolen (and adapted from HM's nla_staff_spreadsheet plugin :-)
  class ParentTracker
    require 'pry'
    def set_uri(hier, uri)
      @current_hierarchy ||= {}
      @current_hierarchy = Hash[@current_hierarchy.map {|k, v|
                                  if k < hier
                                    [k, v]
                                  end
                                }.compact]

      # Record the URI of the current record
      @current_hierarchy[hier] = uri
    end
    def parent_for(hier)
      # Level 1 parent may  be a resource record and therefore nil, 
      if hier > 0
        parent_level = hier - 1
        @current_hierarchy.fetch(parent_level)
      else
        nil
      end
    end
  end #of ParentTracker

end
