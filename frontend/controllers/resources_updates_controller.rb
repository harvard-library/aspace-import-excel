class ResourcesUpdatesController < ApplicationController
  require 'nokogiri'

START_MARKER = /ArchivesSpace field code \(please don't edit this row\)/

  set_access_control "update_resource_record" => [:new, :edit, :create, :update, :rde, :add_children, :publish, :accept_children, :load_ss, :get_file, :get_do_file, :load_dos]

  require 'pry'
  require 'rubyXL'
  require 'asutils'
  require 'enum_list'
  include NotesHelper
  include UpdatesUtils
  include LinkedObjects
  require 'ingest_report'

  # create the file form for the digital object spreadsheet
  def get_do_file
    rid = params[:rid]
    id = params[:id]
  end
  
  # create the file form for the spreadsheet
  def get_file
    rid = params[:rid]
    type = params[:type]
    aoid = params[:aoid] || ''
    ref_id = params[:ref_id] || ''
    resource = params[:resource]
    position = params[:position] || '1'
    return render_aspace_partial :partial => "resources/bulk_file_form",  :locals => {:rid => rid, :aoid => aoid, :type => type, :ref_id => ref_id, :resource => resource, :position => position} 
  end

  # load the digital objects
  def load_dos
     #first time out of the box:
Pry::ColorPrinter.pp "\t**** LOAD DOS ***"
    get_uri = "/repositories/#{params[:rid]}/find_by_id/archival_objects"
Pry::ColorPrinter.pp get_uri
Pry::ColorPrinter.pp params
    response = JSONModel::HTTP::get_json(URI(get_uri),{"ref_id[]" => params["ref_id"], "resolve[]" => "archival_objects"})
Pry::ColorPrinter.pp "RESPONSE"
Pry::ColorPrinter.pp response
    response
  end

  # load in a spreadsheet
  def load_ss
    @report_out = []
    @report = IngestReport.new
    @created_ao_refs = []
    @first_level_aos = []
    @archival_levels = EnumList.new('archival_record_level')
    @container_types = EnumList.new('container_type')
    @date_types = EnumList.new('date_type')
    @date_labels = EnumList.new('date_label')
    @date_certainty = EnumList.new('date_certainty')
    @extent_types = EnumList.new('extent_extent_type')
    @extent_portions = EnumList.new('extent_portion')
    @instance_types ||= EnumList.new('instance_instance_type')
    @parents = ParentTracker.new
    @start_position
    @need_to_move = false
    begin
      rows = initialize_info(params)
      while @headers.nil? && (row = rows.next)
        @counter += 1
        if row[0] && row[0].value =~ START_MARKER
          @headers = row_values(row)
        # Skip the human readable header too
          rows.next
          @counter += 1 # for the skipping
        end
      end
      raise ExcelImportException.new(I18n.t('plugins.aspace-import-excel.error.no_header')) if @headers.nil?
      begin
        while (row = rows.next)
          @counter += 1 
          values = row_values(row)
          next if values.compact.empty?
          @row_hash = Hash[@headers.zip(values)]
          ao = nil
          begin
            @report.new_row(@counter)
            ao = process_row
            @rows_processed += 1
            @error_level = nil
#            Pry::ColorPrinter.pp "no ao" if !ao
          rescue StopExcelImportException => se
            @report.add_errors([se.message, I18n.t('plugins.aspace-import-excel.error.stopped', :row => @counter)])
            raise StopIteration.new
          rescue ExcelImportException => e
            @error_rows += 1
            @report.add_errors( e.message)
            @error_level = @hier
#            Pry::ColorPrinter.pp "Error level: #{@error_level}"
          end
          @report.end_row
        end
      rescue StopIteration
        # we just want to catch this without processing further
      end
      if @rows_processed == 0
        raise ExcelImportException.new( I18n.t('plugins.aspace-import-excel.error.no_data'))
      end
    rescue Exception => e
      if e.is_a?( ExcelImportException) || e.is_a?( StopExcelImportException)
        @report.add_terminal_error(I18n.t('plugins.aspace-import-excel.error.excel', :errs => e.message), @counter)
      else # something else went wrong
        @report.add_terminal_error(I18n.t('plugins.aspace-import-excel.error.system', :msg => e.message), @counter)
        Pry::ColorPrinter.pp "UNEXPECTED EXCEPTION!"
        Pry::ColorPrinter.pp e.message
        Pry::ColorPrinter.pp e.backtrace
      end
      @report.end_row
      return render_aspace_partial :status => 400,  :partial => "resources/bulk_response", :locals => {:rid => params[:rid],
        :report =>  @report}
    end
    move_archival_objects if @need_to_move
    @report.end_row
#    Pry::ColorPrinter.pp "Number of Archival Object created: #{@created_ao_refs.length}"
    return render_aspace_partial :partial => "resources/bulk_response", :locals => {:rid => params[:rid], :report => @report}
  end

  private  

  # look for all the required fields to make sure they are legit
  # strip all the strings and turn publish and restrictions_flaginto true/false
  def check_row
    err_arr = []
    begin
      # we'll check hierarchical level first, in case there was a parent that didn't get created
      hier = @row_hash['hierarchy']
      if !hier 
        err_arr.push I18n.t('plugins.aspace-import-excel.error.hier_miss')
      else
        hier = hier.to_i
        # we bail if the parent wasn't created!
        return I18n.t('plugins.aspace-import-excel.error.hier_below_error_level') if (@error_level && hier > @error_level)
        err_arr.push I18n.t('plugins.aspace-import-excel.error.hier_zero') if hier < 1
        # going from a 1 to a 3, for example
        if (hier - 1) > @hier
          err_arr.push I18n.t('plugins.aspace-import-excel.error.hier_wrong')
          if @hier == 0
            err_arr.push I18n.t('plugins.aspace-import-excel.error.hier_wrong_resource')
            raise StopExcelImportException.new(err_arr.join(';'))
          end
        end
        @hier = hier
      end 
      missing_title = @row_hash['title'].blank?
      #date stuff: if already missing the title, we have to make sure the date label is valid
      missing_date = [@row_hash['begin'],@row_hash['end'],@row_hash['expression']].compact.empty? 
      if !missing_date
        begin
          label = @date_labels.value((@row_hash['dates_label'] || 'creation'))
        rescue Exception => e
          err_arr.push I18n.t('plugins.aspace-import-excel.error.invalid_date', :what => e.message)
          missing_date = true
        end
      end
      err_arr.push  I18n.t('plugins.aspace-import-excel.error.title_and_date') if (missing_title && missing_date)
      # tree hierachy
      begin
        level = @archival_levels.value(@row_hash['level'])
      rescue Exception => e
        err_arr.push I18n.t('plugins.aspace-import-excel.error.level')
      end
    rescue StopExcelImportException => se
      raise
    rescue Exception => e
      Pry::ColorPrinter.pp ["UNEXPLAINED EXCEPTION", e.message, e.backtrace, @row_hash]
    end
    if err_arr.blank?
      @row_hash.each do |k, v|
        @row_hash[k] = v.strip if !v.blank?
        if k == 'publish'  || k == 'restrictions_flag'
          @row_hash[k] = (v == '1')
        end
      end
    end
    err_arr.join('; ')
  end

  # create an archival_object
  def create_archival_object(parent_uri)
    ao = JSONModel(:archival_object).new._always_valid!
    ao.title = @row_hash['title'] if  @row_hash['title']
    unless [@row_hash['begin'],@row_hash['end'],@row_hash['expression']].compact.empty?
      begin
        ao.dates = create_date 
      rescue Exception => e
#        Pry::ColorPrinter.pp "We gots a date exception! #{e.message}"
        @report.add_errors(I18n.t('plugins.aspace-import-excel.error.invalid_date', :what => e.message))
      end
    end
    #because the date may have been invalid, we should check if there's a title, otherwise bail
    if ao.title.blank? && ao.dates.blank?
      raise ExcelImportException.new(I18n.t('plugins.aspace-import-excel.error.title_and_date'))
    end
    ao.resource = {'ref' => @resource['uri']}
    ao.component_id =  @row_hash['unit_id'] if @row_hash['unit_id']
    ao.repository_processing_note = @row_hash['processing_note'] if @row_hash['processing_note']
    ao.level =  @archival_levels.value(@row_hash['level'])
    ao.other_level = @row_hash['other_level'] || 'unspecified' if ao.level == 'otherlevel'
    ao.publish = @row_hash['publish']
    ao.restrictions_apply = @row_hash['restrictions_flag']
    ao.parent = {'ref' => parent_uri} unless parent_uri.blank?
    begin
      ao.extents = create_extent unless [@row_hash['number'],@row_hash['extent_type'], @row_hash['portion']].compact.empty?
    rescue Exception => e
      @report.add_errors(e.message)
    end
    errs =  handle_notes(ao)
    @report.add_errors(errs) if !errs.blank?
    # we have to save the ao for the display_string
    begin
      ao.save # if there's a problem, the exception flows upward...
    rescue Exception => e
      Pry::ColorPrinter.pp "UNEXPECTED save error: #{e.message}"
      Pry::ColorPrinter.pp ASUtils.jsonmodels_to_hashes(ao) if ao
      raise e
    end
    instance = create_top_container_instance
    ao.instances = [instance] if instance
    if (dig_instance = DigitalObjectHandler.create(@row_hash, ao, @report))
      ao.instances ||= []
      ao.instances << dig_instance
    end
    subjs = process_subjects
    subjs.each {|subj| ao.subjects.push({'ref' => subj.uri})} unless subjs.blank?
    links = process_agents
    ao.linked_agents = links
    ao
  end
  
  def create_date
    date_type = 'inclusive'
    begin
      date_type = @date_types.value(@row_hash['date_type'] || 'inclusive')
    rescue Exception => e
      @report.add_errors(I18n.t('plugins.aspace-import-excel.error.date_type', :what => @row_hash['date_type']))
    end
    date =  { 'date_type' => date_type,
      'label' =>  @date_labels.value((@row_hash['dates_label'] || 'creation')) }
    if @row_hash['date_certainty']
      begin
        date['certainty'] = @date_certainty.value(@row_hash['date_certainty'])
      rescue Exception => e
        @report.add_errors(I18n.t('plugins.aspace-import-excel.error.certainty', :what => e.message))
      end
    end
    %w(begin end expression).each do |w|
      date[w] = @row_hash[w] if @row_hash[w]
    end
    invalids = JSONModel::Validations.check_date(date)
    unless invalids.blank?
      err_msg = ''
      invalids.each do |inv|
        err_msg << " #{inv[0]}: #{inv[1]}"
      end
      raise Exception.new(err_msg)
    end
    d = JSONModel(:date).new(date)
    [d]
  end

  def create_extent
    begin
      extent = {'portion' => @extent_portions.value(@row_hash['portion'] || 'whole'),
        'extent_type' => @extent_types.value((@row_hash['extent_type']))}
      %w(number container_summary physical_details dimensions).each do |w|
        extent[w] = @row_hash[w] || nil
      end
      ex = JSONModel(:extent).new(extent)
      if UpdatesUtils.test_exceptions(ex, "Extent")
        return [ex]
      end
    rescue Exception => e
      raise ExcelImportException.new(I18n.t('plugins.aspace-import-excel.error.extent_validation', :msg => e.message))
    end
  end

  def create_top_container_instance
    instance = nil
    unless @row_hash['cont_instance_type'].blank? && @row_hash['type_1'].blank?
      begin
        instance = ContainerInstanceHandler.create_container_instance(@row_hash, @resource['uri'], @report)
      rescue ExcelImportException => ee
        @report.add_errors(I18n.t('plugins.aspace-import-excel.error.no_container_instance', :why =>ee.message))
      rescue Exception => e
        @report.add_errors(I18n.t('plugins.aspace-import-excel.error.no_tc', :why => e.message))
#        Pry::ColorPrinter.pp e.message
      end
    end
#Pry::ColorPrinter.pp "instance"
#Pry::ColorPrinter.pp instance
    instance
  end

  def handle_notes(ao)
    publish = ao.publish
    errs = []
    notes_keys = @row_hash.keys.grep(/^n_/)
    notes_keys.each do |key|
      unless @row_hash[key].blank?
        content = @row_hash[key]
        type = key.match(/n_(.+)$/)[1]
        note_type = @note_types[type]
#        Pry::ColorPrinter.pp "content for #{key}: |#{content}|  type: #{type} note_type#{note_type}"
        note = JSONModel(note_type[:target]).new
        note.publish = publish
        note.type = note_type[:value]
        begin 
          wellformed(content)
# if the target is multipart, then the data goes in a JSONMODEL(:note_text).content;, which is pushed to the note.subnote array; otherwise it's just pushed to the note.content array
          if note_type[:target] == :note_multipart
            inner_note = JSONModel(:note_text).new
            inner_note.content = content
            inner_note.publish = publish
            note.subnotes.push inner_note
          else
            note.content.push content
          end
          ao.notes.push note
        rescue Exception => e
          errs.push(I18n.t('plugins.aspace-import-excel.error.bad_note', :type => note_type[:value] , :msg => CGI::escapeHTML( e.message)))
        end
      end
    end
    errs
  end

  # this refreshes the controlled list enumerations, which may have changed since the last import
  def initialize_handler_enums
    ContainerInstanceHandler.renew
    DigitalObjectHandler.renew
    SubjectHandler.renew
  end
  
  # set up all the @ variables (except for @header)
  def initialize_info(params)
    dispatched_file = params[:file]
    @orig_filename = dispatched_file.original_filename
    @report.set_file_name(@orig_filename)
    initialize_handler_enums
    @note_types =  note_types_for(:archival_object)
    tree = JSONModel(:resource_tree).find(nil, :resource_id => params[:rid]).to_hash
#Pry::ColorPrinter.pp tree
    @resource = Resource.find(params[:rid])
    @repository = @resource['repository']['ref']
    @ao = nil
    @hier = 1
    aoid = params[:aoid] 
    @resource_level = aoid.blank?
    @first_one = false  # to determine whether we need to worry about positioning
    if @resource_level
      @parents.set_uri(0, nil)
      @hier = 0
    else
      @ao = JSONModel(:archival_object).find(aoid, find_opts )
      @start_position = @ao.position
      parent = @ao.parent # we need this for sibling/child disabiguation later on 
#       Pry::ColorPrinter.pp ASUtils.jsonmodels_to_hashes(parent) if parent
      @parents.set_uri(0, (parent ? ASUtils.jsonmodels_to_hashes(parent)['ref'] : nil))
      @parents.set_uri(1, @ao.uri)
      @first_one = true
#      Pry::ColorPrinter.pp ['archival object','position', @position]
#      test_exceptions(@ao, "BASE ARCHIVAL OBJECT")
    end

    @input_file = dispatched_file.tempfile
    @counter = 0
    @rows_processed = 0
    @error_rows = 0
    workbook = RubyXL::Parser.parse(@input_file)
    sheet = workbook[0]
 #   Pry::ColorPrinter.pp ["sheet size", sheet.sheet_data.size] 
    rows = sheet.enum_for(:each)
  end

  def move_archival_objects
    unless @first_level_aos.empty?
      uri = (@ao && @ao.parent) ? @ao.parent['ref'] : @resource.uri
#      Pry::ColorPrinter.pp "moving: URI: #{uri}"
      response = JSONModel::HTTP.post_form("#{uri}/accept_children",
                                           "children[]" => @first_level_aos,
                                           "position" => @start_position + 1)
      unless response.code == '200'
        Pry::ColorPrinter.pp "UNEXPECTED BAD MOVE! #{response.code}"
        Pry::ColorPrinter.pp response.body
        @report.errors(I18n.t('plugins.aspace-import-excel.error.no_move', :code => response.code))
      end
    end
  end

  def process_agents
    agent_links = []
    %w(people corporate_entities families).each do |type|
      (1..3).each do |num|
        id_key = "#{type}_agent_record_id_#{num}"
        header_key = "#{type}_agent_header_#{num}"
        unless @row_hash[id_key].blank? && @row_hash[header_key].blank?
          link = nil
          begin
            link = AgentHandler.get_or_create(@row_hash, type, num.to_s, @resource['uri'], @report)
            agent_links.push link if link
          rescue ExcelImportException => e
            @report.add_errors(e.message)
          end
        end
      end
    end
    agent_links
  end

  def process_row
#    Pry::ColorPrinter.pp @counter
    ret_str =  resource_match
    # mismatch of resource stops all other processing
    if ret_str.blank?
      ret_str = check_row
    end
    raise ExcelImportException.new( I18n.t('plugins.aspace-import-excel.row_error', :row => @counter, :errs => ret_str )) if !ret_str.blank?
    parent_uri = @parents.parent_for(@row_hash['hierarchy'].to_i)
    begin
      ao = create_archival_object(parent_uri)
  #  test_exceptions(ao, "CREATED ARCHIVAL OBJECT")
      saving = ao.save
      @report.add_archival_object(ao)
      @parents.set_uri(@hier, ao.uri)
      @created_ao_refs.push ao.uri
      if @hier == 1
        @first_level_aos.push ao.uri 
        if @first_one && @start_position
          @need_to_move = (ao.position - @start_position) > 1
          @first_one = false
#          Pry::ColorPrinter.pp "Need to move: #{@need_to_move}"
        end
      end
    rescue JSONModel::ValidationException => ve
      # ao won't have been created
      raise ExcelImportException.new(ve.message)
    rescue  Exception => e
      Pry::ColorPrinter.pp "UNEXPECTED #{e.message}"
      Pry::ColorPrinter.pp e.backtrace
      Pry::ColorPrinter.pp ASUtils.jsonmodels_to_hashes(ao)
      raise ExcelImportException.new(e.message)
    end
  end

  def process_subjects
    ret_subjs = []
    (1..2).each do |num|
      unless @row_hash["subject_#{num}_record_id"].blank? && @row_hash["subject_#{num}_term"].blank?
        subj = nil
        begin
          subj = SubjectHandler.get_or_create(@row_hash, num, @repository.split('/')[2], @report)
          ret_subjs.push subj if subj
        rescue ExcelImportException => e
          @report.add_errors(e.message)
        end
      end
    end
    ret_subjs
  end

  # make sure that the resource ead id from the form matches that in the spreadsheet
  # throws an exception if the designated resource ead doesn't match the spreadsheet row ead
  def resource_match
    ret_str = ''
    ret_str = I18n.t('plugins.aspace-import-excel.error.res_ead') if @resource['ead_id'].blank?
    ret_str =  ' ' +  I18n.t('plugins.aspace-import-excel.error.row_ead')  if @row_hash['ead'].blank?
    if ret_str.blank?
      ret_str =  I18n.t('plugins.aspace-import-excel.error.ead_mismatch', :res_ead => @resource['ead_id'], :row_ead => @row_hash['ead']) if @resource['ead_id'] != @row_hash['ead']
    end
    ret_str.blank? ? nil : ret_str
  end

  def find_subject(subject,source, ext_id)
    #title:subject AND primary_type:subject AND source:#{source} AND external_id:#{ext_id}
  end

  def find_agent(primary_name, rest_name, type, source, ext_id)
    #title: #{primary_name}, #{rest_name} AND primary_type:agent_#{type}  AND source:#{source} AND external_id:#{ext_id}
  end

  # use nokogiri if there seems to be an XML element (or element closure); allow exceptions to bubble up
  def wellformed(note)
    if note.match("</?[a-zA-Z]+>")
      frag = Nokogiri::XML("<root>#{note}</root>") {|config| config.strict}
    end
  end

 
  def row_values(row)
#    Pry::ColorPrinter.pp "ROW!"
    (1...row.size).map {|i| (row[i] && row[i].value) ? row[i].value.to_s.strip : nil}
  end
end

