module LinkedObjects
  extend ActiveSupport::Concern


# This module incorporates all the classes needed to handle objects that must be linked to
# Archival Objects, such as Subjects, Top Containers, etc.

# a lot of this is adapted from Hudson Mlonglo's Arrearage plugin:
#https://github.com/hudmol/nla_staff_spreadsheet_importer/blob/master/backend/converters/arrearage_converter.rb


  class AgentHandler < Handler
    @@agents = {} 
    @@agent_relators ||= EnumList.new('linked_agent_archival_record_relators')
    AGENT_TYPES = { 'families' => 'family', 'corporate_entities' => 'corporate_entity', 'people' => 'person'}
    def self.renew
      clear(@@agent_relators)
    end
    def self.key_for(agent)
      key = "#{agent[:type]} #{agent[:name]}"
      key
    end
    
   def self.build(row, type, num)
     id = row.fetch("#{type}_agent_record_id_#{num}", nil)
     input_name = row.fetch("#{type}_agent_header_#{num}",nil)
     {
       :type => AGENT_TYPES[type],
       :id => id,
       :name => input_name || (id ? I18n.t('plugins.aspace-import-excel.unfound_id', :id => id, :type => 'Agent') : nil),
       :relator => row.fetch("#{type}_agent_relator_#{num}", nil),
       :id_but_no_name => id && !input_name
     }
   end

   def self.get_or_create(row, type, num, resource_uri, report)
     agent = build(row, type, num)
     agent_key = key_for(agent)
     if !(agent_obj = stored(@@agents, agent[:id], agent_key))
       unless agent[:id].blank?
         begin
           agent_obj = JSONModel("agent_#{agent[:type]}".to_sym).find(agent[:id])
         rescue Exception => e
           if e.message != 'RecordNotFound'
#             Pry::ColorPrinter.pp e
             raise ExcelImportException.new( I18n.t('plugins.aspace-import-excel.error.no_agent', :num => num, :why => e.message))
           end
         end
       end
       begin
       unless agent_obj || (agent_obj = get_db_agent(agent, resource_uri, num))
         agent_obj = create_agent(agent, num)
         report.add_info(I18n.t('plugins.aspace-import-excel.created', :what =>"#{I18n.t('plugins.aspace-import-excel.agent')}[#{agent[:name]}]", :id => agent_obj.uri))
       end
       rescue Exception => e
#         Pry::ColorPrinter.pp e.message
#         Pry::ColorPrinter.pp e.backtrace
         raise ExcelImportException.new( I18n.t('plugins.aspace-import-excel.error.no_agent', :num =>  num,  :why => e.message))
       end
     end
     agent_link = nil
     if agent_obj
       if agent[:id_but_no_name]
         @@agents[agent[:id].to_s] = agent_obj
       else
         @@agents[agent_obj.id.to_s] = agent_obj
       end
       @@agents[agent_key] = agent_obj
       agent_link = {"ref" => agent_obj.uri, "role" => 'creator'}
       begin
         agent_link["relator"] =  @@agent_relators.value(agent[:relator]) if !agent[:relator].blank?
       rescue Exception => e
         if e.message.start_with?("NOT FOUND")
           raise ExcelImportException.new(I18n.t('plugins.aspace-import-excel.error.bad_relator', :label => agent[:relator]))
         else
           raise ExcelImportException.new(I18n.t('plugins.aspace-import-excel.error.relator_invalid', :label => agent[:relator], :why => e.message))
         end
       end
     end
     agent_link
   end

  def self.create_agent(agent, num)
    begin
      ret_agent = JSONModel("agent_#{agent[:type]}".to_sym).new._always_valid!
      ret_agent.names = [name_obj(agent)]
      ret_agent.publish = !agent[:id_but_no_name]
      ret_agent.save
    rescue Exception => e
       raise Exception.new(I18n.t('plugins.aspace-import-excel.error.no_agent', :num => num, :why => e.message))
    end
    ret_agent
  end

  def self.get_db_agent(agent, resource_uri, num)
    ret_ag = nil
    if agent[:id]
      begin
        ret_ag = JSONModel("agent_#{agent[:type]}".to_sym).find(agent[:id])
      rescue Exception => e
        if e.message != 'RecordNotFound' 
#          Pry::ColorPrinter.pp e.message
#          Pry::ColorPrinter.pp e.backtrace
          raise ExcelImportException.new( I18n.t('plugins.aspace-import-excel.error.no_agent', :num => num, :why => e.message))
        end
      end
    end
    if !ret_ag
      a_params = {"q" => "title:\"#{agent[:name]}\" AND primary_type:agent_#{agent[:type]}"}
      repo = resource_uri.split('/')[2]
      ret_ag = search(repo, a_params, "agent_#{agent[:type]}".to_sym)
    end
    ret_ag
  end

   def self.name_obj(agent)
     obj = JSONModel("name_#{agent[:type]}".to_sym).new._always_valid!
     obj.source = 'ingest'
     obj.authorized = true
     obj.is_display_name = true
     if agent[:type] == 'family'
       obj.family_name = agent[:name]
     else
       obj.primary_name = agent[:name]
       obj.name_order = 'direct' if agent[:type] == 'person'
     end
     obj
   end
  end # agent

  class DigitalObjectHandler < Handler
    @@digital_object_types ||= EnumList.new('digital_object_digital_object_type')
    
    def self.create(row, archival_object, report)
      dig_o = nil
      dig_instance = nil
      thumb = row['thumbnail'] || row['Thumbnail']
      unless !thumb && !row['digital_object_link']
        files = []
        if !row['digital_object_link'].blank? && row['digital_object_link'].start_with?('http')
          fv = JSONModel(:file_version).new._always_valid!
          fv.file_uri = row['digital_object_link']
          fv.publish = row['publish']
          fv.xlink_actuate_attribute = 'onRequest'
          fv.xlink_show_attribute = 'new'
          files.push fv
        end
        if !thumb.blank? && thumb.start_with?('http')
          fv = JSONModel(:file_version).new._always_valid!
          fv.file_uri = thumb
          fv.publish = row['publish']
          fv.xlink_actuate_attribute = 'onLoad'
          fv.xlink_show_attribute = 'embed'
          fv.is_representative = true
          files.push fv
        end
        osn = row['digital_object_id'].blank? ? (archival_object.ref_id + 'd') : row['digital_object_id']
        dig_o = JSONModel(:digital_object).new._always_valid!
        dig_o.title = row['digital_object_title'].blank? ? archival_object.display_string : row['digital_object_title']
        dig_o.digital_object_id = osn
        dig_o.file_versions = files
        dig_o.publish = row['publish']
        begin
          dig_o.save
        rescue ValidationException => ve
          report.add_errors(I18n.t('plugins.aspace-import-excel.error.dig_validation', :err => ve.errors))
          return  nil
        rescue Exception => e
          raise e
        end
        report.add_info(I18n.t('plugins.aspace-import-excel.created', :what =>I18n.t('plugins.aspace-import-excel.dig'), :id => "'#{dig_o.title}' #{dig_o.uri} [#{dig_o.digital_object_id}]"))
        dig_instance = JSONModel(:instance).new._always_valid!
        dig_instance.instance_type = 'digital_object'
        dig_instance.digital_object = {"ref" => dig_o.uri}
      end
      dig_instance
    end

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

    def self.key_for(top_container, resource)
      key = "'#{resource}' #{top_container[:type]}: #{top_container[:indicator]}"
      key += " #{top_container[:barcode]}" if top_container[:barcode]
      key
    end

    
    def self.build(row)
      {
        :type => @@container_types.value(row.fetch('type_1', 'Box') || 'Box'),
        :indicator => row.fetch('indicator_1', 'Unknown') || 'Unknown',
        :barcode => row.fetch('barcode',nil)
      }
    end
    
    # returns a top container JSONModel
    def self.get_or_create(row, resource, report)
      begin
        top_container = build(row)
        tc_key = key_for(top_container, resource)
        # check to see if we already have fetched one from the db, or created one.
        existing_tc = @@top_containers.fetch(tc_key, false) ||  get_db_tc(top_container, resource)
        if !existing_tc
          tc = JSONModel(:top_container).new._always_valid!
          tc.type = top_container[:type]
          tc.indicator = top_container[:indicator]
          tc.barcode = top_container[:barcode] if top_container[:barcode] 
          tc.repository = {'ref' => resource.split('/')[0..2].join('/')}
          #          UpdateUtils.test_exceptions(tc,'top_container')
          tc.save
          report.add_info(I18n.t('plugins.aspace-import-excel.created', :what =>"#{I18n.t('plugins.aspace-import-excel.tc')} [#{tc.type} #{tc.indicator}]", :id=> tc.uri))
          existing_tc = tc
        end
      rescue Exception => e
        report.add_errors(I18n.t('plugins.aspace-import-excel.error.no_tc', :why => e.message + " in linked_objects"))
        existing_tc = nil
      end
      @@top_containers[tc_key] = existing_tc if existing_tc
      existing_tc
    end

    def self.get_db_tc(top_container, resource_uri)
      repo_id = resource_uri.split('/')[2]
      if !(ret_tc = get_db_tc_by_barcode(top_container[:barcode], repo_id))
        tc_str = "#{top_container[:type]} #{top_container[:indicator]}"
        tc_str += ": [#{top_container[:barcode]}]" if top_container[:barcode]
        tc_params = {}
        tc_params["type[]"] = 'top_container'
        tc_params["q"] = "display_string:\"#{tc_str}\" AND collection_uri_u_sstr:\"#{resource_uri}\""
        ret_tc = search(repo_id,tc_params, :top_container)
      end
      ret_tc
    end
    
    def self.get_db_tc_by_barcode(barcode, repo_id)
      ret_tc = nil
      if barcode
        tc_params = {}
        tc_params["type[]"] = 'top_container'
        tc_params["q"] = "barcode_u_sstr:#{barcode}"
        ret_tc = search(repo_id,tc_params, :top_container)
      end
      ret_tc
    end


    def self.create_container_instance(row, resource_uri,report)
      instance = nil
      raise  ExcelImportException.new(I18n.t('plugins.aspace-import-excel.error.missing_instance_type')) if row['cont_instance_type'].blank?
      if row['type_1']
        begin
          tc = get_or_create(row, resource_uri, report)
          sc = {'top_container' => {'ref' => tc.uri},
            'jsonmodeltype' => 'sub_container'}
          %w(2 3).each do |num|
            if row["type_#{num}"]
              sc["type_#{num}"] = @@container_types.value(row["type_#{num}"])
              sc["indicator_#{num}"] = row["indicator_#{num}"] || 'Unknown'
            end
          end
          instance = JSONModel(:instance).new._always_valid!
          instance.instance_type = @@instance_types.value(row['cont_instance_type'])
          instance.sub_container = JSONModel(:sub_container).from_hash(sc)
        rescue ExcelImportException => ee
          instance = nil
          raise ee
        rescue Exception => e
          msg = e.message #+ "\n" + e.backtrace()[0]
          instance = nil
          raise ExcelImportException.new(msg)
        end
      end
      instance
    end

  end  # of container handler

  #shamelessly stolen (and adapted from HM's nla_staff_spreadsheet plugin :-)
  class ParentTracker
    require 'pp'
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

  class SubjectHandler < Handler
    @@subjects = {} # will track both confirmed ids, and newly created ones.
    @@subject_term_types ||= EnumList.new('subject_term_type')
    @@subject_sources ||=  EnumList.new('subject_source')

    def self.renew
      clear(@@subject_term_types)
      clear(@@subject_sources)
    end

    def self.key_for(subject)
      key = "#{subject[:term]} #{subject[:source]}: #{subject[:type]}"
      key
    end
    def self.build(row, num)
      id =  row.fetch("subject_#{num}_record_id", nil)
      input_term = row.fetch("subject_#{num}_term", nil)
      {
        :id => id,
        :term =>  input_term || (id ? I18n.t('plugins.aspace-import-excel.unfound_id', :id => id, :type => 'subject') : nil),
        :type =>   @@subject_term_types.value(row.fetch("subject_#{num}_type") || 'topical'),
        :source => @@subject_sources.value( row.fetch("subject_#{num}_source") || 'ingest'),
        :id_but_no_term => id && !input_term
      }
    end
 
    def self.get_or_create(row, num, repo_id, report)
      subject = build(row, num)
      subject_key = key_for(subject)
      if !(subj = stored(@@subjects, subject[:id], subject_key))
        unless subject[:id].blank?
          begin
            subj = JSONModel(:subject).find( subject[:id])
          rescue Exception => e
             if e.message != 'RecordNotFound'
               raise ExcelImportException.new( I18n.t('plugins.aspace-import-excel.error.no_subject',:num => num, :why => e.message))
             end
          end
        end
        begin
          unless subj || (subj = get_db_subj(subject))
            subj = create_subj(subject, num)
            report.add_info(I18n.t('plugins.aspace-import-excel.created', :what =>"#{I18n.t('plugins.aspace-import-excel.subj')}[#{subject[:term]}]", :id => subj.uri))
          end
        rescue Exception => e
          raise ExcelImportException.new( I18n.t('plugins.aspace-import-excel.error.no_subject',:num => num, :why => e.message))
        end
        if subj
          if subj[:id_but_no_term]
            @@subjects[subject[:id].to_s] = subj
          else
            @@subjects[subj.id.to_s] = subj
          end
          @@subjects[subject_key] = subj
        end
      end
      subj
    end

    def self.create_subj(subject, num)
      begin
        term = JSONModel(:term).new._always_valid!
        term.term =  subject[:term]
        term.term_type = subject[:type]
        term.vocabulary = '/vocabularies/1'  # we're making a gross assumption here
        subj = JSONModel(:subject).new._always_valid!
        subj.terms.push term
        subj.source = subject[:source]
        subj.vocabulary = '/vocabularies/1'  # we're making a gross assumption here
        subj.save
      rescue Exception => e
        raise ExcelImportException.new(I18n.t('plugins.aspace-import-excel.error.no_subject',:num => num, :why => e.message))
      end
      subj
    end   

    def self.get_db_subj(subject)
      s_params = {}
      s_params["q"] = "title:\"#{subject[:term]}\" AND first_term_type:#{subject[:type]}"

      ret_subj = search(nil, s_params, :subject, 'subjects')
    end
  end
end
