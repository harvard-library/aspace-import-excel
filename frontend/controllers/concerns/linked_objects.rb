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
