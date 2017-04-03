class ResourcesUpdatesController < ApplicationController

START_MARKER = /ArchivesSpace field code \(please don't edit this row\)/

  set_access_control "update_resource_record" => [:new, :edit, :create, :update, :rde, :add_children, :publish, :accept_children, :load_ss, :get_file]

  require 'pry'
  require 'rubyXL'
  require 'asutils'
  require 'enum_list'
  include UpdatesUtils
  include LinkedObjects
  
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

  # load in a spreadsheet
  def load_ss
    @container_types = EnumList.new('container_type')
    @extent_types = EnumList.new('extent_extent_type')
    @extent_portions = EnumList.new('extent_portion')
    @instance_types ||= EnumList.new('instance_instance_type')
    @parents = ParentTracker.new
    @orig_position
    @first_sibling_position
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
          begin
            ao = process_row
            @rows_processed += 1
          rescue StopExcelImportException => se
            @report_out.push se.message
            @report_out.push I18n.t('plugins.aspace-import-excel.error.stopped', :row => @counter)
            raise StopIteration.new
          rescue ExcelImportException => e
            @error_rows += 1
            @report_out.push e.message
            @report_out.push ' '
          end
        end
      rescue StopIteration
        # we just want to catch this without processing further
      end
      if @rows_processed == 0
        raise ExcelImportException.new( I18n.t('plugins.aspace-import-excel.error.no_data') + '\n' + @report_out.join('\n')) 
      end
    rescue Exception => e
      errors = []
      if e.is_a?( ExcelImportException) || e.is_a?( StopExcelImportException)
        errors = e.message.split('\n')
        errors.unshift I18n.t('plugins.aspace-import-excel.error.excel', :file => @orig_filename)
      else # something else went wrong
        errors = @report_out if !@report_out.blank?
        errors.unshift I18n.t('plugins.aspace-import-excel.error.system',:row => @counter, :msg => e.message)
        Pry::ColorPrinter.pp "EXCEPTION!" 
        Pry::ColorPrinter.pp e.backtrace
      end
      return render_aspace_partial :status => 400,  :partial => "resources/bulk_response", :locals => {:rid => params[:rid],
        :errors =>  errors}
    end
    return render_aspace_partial :partial => "resources/bulk_response", :locals => {:rid => params[:rid], :report => @report_out}
  end

  private  

  # look for all the required fields to make sure they are legit
  # strip all the strings and turn publish into true/false
  def check_row
    err_arr = []
    begin
      err_arr.push I18n.t('plugins.aspace-import-excel.error.title') if @row_hash['title'].blank?
      # tree hierachy
      hier = @row_hash['hierarchy']
      if !hier 
        err_arr.push I18n.t('plugins.aspace-import-excel.error.hier_miss')
      else
        hier = hier.to_i
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
      err_arr.push I18n.t('plugins.aspace-import-excel.error.level') if @row_hash['level'].blank?
      #date stuff
      err_arr.push I18n.t('plugins.aspace-import-excel.error.date') if [@row_hash['begin'],@row_hash['end'],@row_hash['expression']].compact.empty?
      # extent
      err_arr.push I18n.t('plugins.aspace-import-excel.error.number') if @row_hash['number'].blank?
      err_arr.push I18n.t('plugins.aspace-import-excel.error.extent_type') if @row_hash['extent_type'].blank?
    rescue StopExcelImportException => se
      raise
    rescue Exception => e
      Pry::ColorPrinter.pp ["UNEXPLAINED EXCEPTION", e.message, e.backtrace, @row_hash]
    end
    if err_arr.blank?
      @row_hash.each do |k, v|
        @row_hash[k] = v.strip if !v.blank?
        if k == 'publish'
          @row_hash[k] = (v == '1')
        end
      end
    end
    err_arr.join('; ')
  end

  # create an archival_object
  def create_archival_object(parent_uri)
    ao = JSONModel(:archival_object).new._always_valid!
    ao.resource = {'ref' => @resource['uri']}
    ao.title = @row_hash['title']
    ao.level = @row_hash['level'].downcase
    ao.publish = @row_hash['publish']
    ao.parent = {'ref' => parent_uri} if !parent_uri.blank?

# For some reason, I need to save/create the smallest possible  amount of information first!
    begin
      ao.save
      @parents.set_uri(@hier, ao.uri)
      if @hier == 1
        if @first_one && @position
        Pry::ColorPrinter.pp "Hierarchy: #{@hier}" 
          a_test_hash = ASUtils.jsonmodels_to_hashes(ao)
          pos = a_test_hash['position']
          Pry::ColorPrinter.pp "Input position: #{@position} this position: #{pos}"
          Pry::ColorPrinter.pp "Difference: #{pos - @position }"
          Pry::ColorPrinter.pp "we'd have to move stuff" if (pos - @position) > 1
          @first_one = false
          @position = pos
        end
      end
    rescue Exception => e
      Pry::ColorPrinter.pp "INITIAL SAVE FAILED!!!"
Pry::ColorPrinter.pp ASUtils.jsonmodels_to_hashes(ao)
      raise I18n.t('plugins.aspace-import-excel.error.system',:row => @counter, :msg => e.message)
    end
    ao.dates = create_date
#    test_exceptions(ao, "with date")
    begin
      ao.extents = create_extent
    rescue Exception => e
      @report_out.push e.message
    end
#    test_exceptions(ao, "and extent")
    instance = create_top_container_instance
    ao.instances = [instance] if instance
    ao
  end
  
  def create_date
    date =  { 'date_type' => (@row_hash['date_type'] || 'inclusive').downcase,
              'label' => (@row_hash['dates_label'] || 'creation').downcase}
    date['certainty']= @row_hash['date_certainty'].downcase if @row_hash['date_certainty']
    %w(begin end expression).each do |w|
      date[w] = @row_hash[w] if @row_hash[w]
    end
    d = JSONModel(:date).new(date)
    begin
#       Pry::ColorPrinter.pp "DATE EXCEPTIONS?"
      d._exceptions
 #     Pry::ColorPrinter.pp "\t passed"
    rescue Exception => e
       Pry::ColorPrinter.pp ['DATE VALIDATION', e.message]
    end
    [d]
  end

  def create_extent
    extent = {'portion' => @extent_portions.value(@row_hash['portion'] || 'whole'),
      'extent_type' => @extent_types.value((@row_hash['extent_type']))}
    %w(number container_summary physical_details dimensions).each do |w|
      extent[w] = @row_hash[w] || nil
    end
    ex = JSONModel(:extent).new(extent)
    begin
      if UpdatesUtils.test_exceptions(ex, "Exceptions")
        return [ex]
      end
    rescue Exception => e
      raise ExcelImportException.new(I18n.t('plugins.aspace-import-excel.error.extent_validation', :msg => e.message))
    end
  end

  def create_top_container_instance
    instance = nil
    begin
      instance = ContainerInstanceHandler.create_container_instance(@row_hash, @resource['uri'])
    rescue ExcelImportException => ee
      @report_out.push ww.msg
    end
    instance
  end
  # set up all the @ variables (except for @header)
  def initialize_info(params)
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
      @position = @ao.position
      parent = @ao.parent # we need this for sibling/child disabiguation later on 
#       Pry::ColorPrinter.pp ASUtils.jsonmodels_to_hashes(parent) if parent
      @parents.set_uri(0, (parent ? ASUtils.jsonmodels_to_hashes(parent)['ref'] : nil))
      @first_one = true
#      Pry::ColorPrinter.pp ['archival object','position', @position]
#      test_exceptions(@ao, "BASE ARCHIVAL OBJECT")
    end
    dispatched_file = params[:file]
    @orig_filename = dispatched_file.original_filename
    @input_file = dispatched_file.tempfile
    @counter = 0
    @rows_processed = 0
    @report_out = []
    @error_rows = 0
    workbook = RubyXL::Parser.parse(@input_file)
    sheet = workbook[0]
 #   Pry::ColorPrinter.pp ["sheet size", sheet.sheet_data.size] 
    rows = sheet.enum_for(:each)
  end

  def process_row
#    Pry::ColorPrinter.pp @counter
    ret_str =  resource_match
    # mismatch of resource stops all other processing
    if ret_str.blank?
      ret_str = check_row
    end
    raise ExcelImportException.new( I18n.t('plugins.aspace-import-excel.row_error', :row => @counter, :errs => ret_str )) if !ret_str.blank?
    @report_out.push  I18n.t('plugins.aspace-import-excel.row', :row =>@counter)
    parent_uri = @parents.parent_for(@row_hash['hierarchy'].to_i)
    ao = create_archival_object(parent_uri)
  #  test_exceptions(ao, "CREATED ARCHIVAL OBJECT")
    begin
      saving = ao.save
    rescue  Exception => e
      Pry::ColorPrinter.pp e.message
      Pry::ColorPrinter.pp ASUtils.jsonmodels_to_hashes(ao)
      Pry::ColorPrinter.pp e.backtrace
    end
#    archival_object =  JSONModel(:archival_object).new
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

  def add_children
   #http://welling.hul.harvard.edu:8880/archival_objects/84957/accept_children
    # children[] = /repositories/2/archival_objects/84958
    #children[] = /repositories/2/archival_objects/84959
    # index = 0
    # this calls handle_accept_children in application_controller https://github.com/archivesspace/archivesspace/blob/c80d9b2205aa36474fe719f3599f83dad8e97bb4/frontend/app/controllers/application_controller.rb
   # unless params[:children]
      # Nothing to do
   #   return render :json => {
   #                   :position => params[:index].to_i
   #   }
   # end

   # response = JSONModel::HTTP.post_form(target_jsonmodel.uri_for(params[:id]) + "/accept_children",
   #                                      "children[]" => params[:children],
   #                                      "position" => params[:index].to_i)
   # if response.code == '200'
   #   render :json => {
   #     :position => params[:index].to_i
   #   }
   # else
   #   raise "Error setting parent of archival objects: #{response.body}"
   # end
    # 
  end
 
  def row_values(row)
#    Pry::ColorPrinter.pp "ROW!"
    (1...row.size).map {|i| (row[i] && row[i].value) ? row[i].value.to_s.strip : nil}
  end
end
