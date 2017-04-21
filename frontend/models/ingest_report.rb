# In order to have robust reporting, I'm separating out the report

class IngestReport
  require 'pry'

  def initialize
    @rows = []
    @current_row = nil
    @terminal_error = ''
    @file_name = nil
    @error_rows = 0
    Pry::ColorPrinter.pp "REPORT INITIALIZE: #{@error_rows}"
  end

  def add_errors(errors)
      @error_rows += 1 if @current_row.errors.blank?
      @current_row.add_errors(errors)
  end

  def add_info(info)
    @current_row.add_info(info)
  end

  def add_archival_object_id(id)
    @current_row.archival_object(id)
  end


  # If we stop processing before getting to the end of the spreadsheet, we want that reported out special
  def add_terminal_error(error, counter)
    if counter
      @terminal_error = I18n.t('plugins.aspace-import-excel.error.stopped', :row => counter, :msg => error)
    else
      @terminal_error = I18n.t('plugins.aspace-import-excel.error.initialize', :msg => error)
    end
  end

  def row_count
    @rows.length
  end

  def end_row
    @rows.push @current_row if @current_row
    @current_row = nil
  end

  def file_name
    @file_name
  end

  def new_row(row_number)
    @rows.push @current_row if @current_row
    @current_row = Row.new(row_number)
  end


  def set_file_name(file_name)
    @file_name = file_name || I18n.t('plugins.aspace-import-excel.error.file_name')
  end


  def rows
    @rows
  end

  def terminal_error
    @terminal_error
  end

  Row = Struct.new(:archival_object_id, :row, :errors, :info) do

    def initialize(row_number)
      self.row = I18n.t('plugins.aspace-import-excel.row', :row => row_number)
      self.errors = []
      self.info = []
      self.archival_object_id = nil
    end
    
    # if other structures (top_container, agent, etc.) were created along the way
    def add_info(info)
      self.info.push info
    end

    def add_errors(errors)
Pry::ColorPrinter.pp errors
      if errors.is_a? Array
        self.errors.concat(errors)
      else
        self.errors.push errors
      end
    end
    
    def archival_object(id)
      self.archival_object_id = id
    end
  end
end
