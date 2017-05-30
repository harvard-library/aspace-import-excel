module UpdatesUtils
  extend  ActiveSupport::Concern

# contains methods needed to support validation and other processing of various classes


  # returns true if the input object validates, otherwise raises an erro
  def self.test_exceptions(obj, what = '')
#    Pry::ColorPrinter.pp "TESTING #{what}: #{obj.jsonmodel_type}"
    ret_val = false
    begin
      obj._exceptions
      true
    rescue Exception => e
#      Pry::ColorPrinter.pp e.message
#      Pry::ColorPrinter.pp ASUtils.jsonmodels_to_hashes(obj)
#      Pry::ColorPrinter.pp  e.backtrace[1..2]
      raise ExcelImportException.new("editable?") if e.message.include?("editable?")
      raise e
    end
  end
end
