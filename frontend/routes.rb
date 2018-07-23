# aspace-import-csv routes
ArchivesSpace::Application.routes.draw do
  scope AppConfig[:frontend_proxy_prefix] do
    match 'resources/:rid/getfile' => 'resources_updates#get_file', :via => [:post]
    match 'resources/:rid/getfile' => 'resources_updates#get_file', :via => [:get]
    # match 'resources/ssload'  => 'resources_updates#load_ss', :via => [:post]
    match 'resources/:id/ssload' => 'resources_updates#load_ss', :via => [:post]
    match 'resources/:id/ssload' => 'resources_updates#load_ss', :via => [:get]
    match 'resources/:id/getdofile' => 'resources_updates#get_do_file', :via => [:get]
    match 'resources/:id/getdofile' => 'resources_updates#get_do_file', :via => [:post]
    match 'resources/:id/digital_load' => 'resources_updates#load_dos', :via => [:get]
    match 'resources/:id/digital_load' => 'resources_updates#load_dos', :via => [:post]
  end
end

