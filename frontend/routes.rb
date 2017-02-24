# aspace-import-csv routes
ArchivesSpace::Application.routes.draw do
   match 'resources/:rid/getfile' => 'resources_updates#get_file', :via => [:post]
   match 'resources/:rid/getfile' => 'resources_updates#get_file', :via => [:get]
#   match 'resources/ssload'  => 'resources_updates#load_ss', :via => [:post]
   match 'resources/:id/ssload' => 'resources_updates#load_ss', :via => [:post]
   match 'resources/:id/ssload' => 'resources_updates#load_ss', :via => [:get]
end
