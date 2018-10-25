# set this to true if you don't want to allow the digital object loading functionality
AppConfig[:hide_do_load] = false

# handle the spreadsheet  load
my_routes = File.join(File.dirname(__FILE__), "routes.rb")
# ArchivesSpace::Application.config.paths['config/routes'].concat(my_routes)
if ArchivesSpace::Application.respond_to?(:extend_aspace_routes)
  ArchivesSpace::Application.extend_aspace_routes(my_routes)
else
  ArchivesSpace::Application.config.paths['config/routes'].concat([my_routes])
end
# create a special exception for this import

class ExcelImportException < Exception
end

# create a "stop everything" exception

class StopExcelImportException < Exception
end

# override the editable? method so errors end up rescued as ValidationExceptions
Rails.application.config.after_initialize do
  class ClientEnumSource
    def editable?(name)
      begin
        MemoryLeak::Resources.get(:enumerations).fetch(name).editable?
      rescue Exception => e
        Rails.logger.error("Blowup for #{name}! #{e.message}")
      end
    end
  end
end
   

# Work around small difference in rubyzip API (from https://github.com/hudmol/nla_staff_spreadsheet_importer/blob/2a28e6379a6748877ab433735153bba96be09b12/backend/plugin_init.rb)
module Zip
  if !defined?(Error)
    class Error < StandardError
    end
  end
end
