# handle the csv load
my_routes = [File.join(File.dirname(__FILE__), "routes.rb")]
 ArchivesSpace::Application.config.paths['config/routes'].concat(my_routes)

# create a special exception for this import

class ExcelImportException < Exception
end


# Work around small difference in rubyzip API (from https://github.com/hudmol/nla_staff_spreadsheet_importer/blob/2a28e6379a6748877ab433735153bba96be09b12/backend/plugin_init.rb)
module Zip
  if !defined?(Error)
    class Error < StandardError
    end
  end
end
