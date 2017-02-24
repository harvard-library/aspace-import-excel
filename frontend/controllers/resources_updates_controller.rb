class ResourcesUpdatesController < ApplicationController

  set_access_control "update_resource_record" => [:new, :edit, :create, :update, :rde, :add_children, :publish, :accept_children, :load_ss, :get_file],
                      "delete_archival_record" => [:delete],
                      "merge_archival_record" => [:merge],
                      "suppress_archival_record" => [:suppress, :unsuppress],
                      "transfer_archival_record" => [:transfer],
                      "manage_repository" => [:defaults, :update_defaults]


  include ExportHelper


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
#    @parent = Resource.find(params[:rid])
#    @archival_object =  JSONModel(:archival_object).new
#    @archival_object.resource = {'ref' => JSONModel(:resource).uri_for(params[:rid]) }
#    @archival_object.title = 'Created by load_ss take 4'
#    @archival_object.level = 'item'
#    test_ao = JSONModel(:archival_object).find('84944', {})
#     Pry::ColorPrinter.pp ['arch_obj', @archival_object]
#    Pry::ColorPrinter.pp ['found ao', test_ao]
#    Pry::ColorPrinter.pp ['exception checking:', @archival_object._exceptions]
#    top_container = 'box 144'
#    uri = '/repositories/2/resources/382'
#    repo_id = 2
#    tc_params = {}
#    tc_params["type[]"] = 'top_container'
#    tc_params["q"] = "display_string:\"#{top_container}\" AND collection_uri_u_sstr:\"#{uri}\""
#    tc_params["filter"] = AdvancedQueryBuilder.new.and('collection_uri_u_sstr', uri, 'text', true).build.to_json
#    search = Search.all(repo_id, tc_params)
#    Pry::ColorPrinter.pp ['top_container search', tc_params,search['total_hits'], search['results'][0]['uri']]
#    if search['total_hits'] = 1
#      @archival_object['instances'] = {}
#    end

#    begin
#      @archival_object.save
#      Pry::ColorPrinter.pp @archival_object
#    rescue Exception => e
#      Pry::ColorPrinter.pp ["EXCEPTION", @archival_object._exceptions, e.backtrace]
#    end
    return render_aspace_partial :partial => "resources/bulk_response", :locals => {:rid => params[:rid]}
  end


  def setup
    
  end


  def defaults
    defaults = DefaultValues.get 'resource'

    values = defaults ? defaults.form_values : {:title => I18n.t("resource.title_default", :default => "")}

    @resource = Resource.new(values)._always_valid!

    @form_title = I18n.t("default_values.form_title.resource")


    render "defaults"
  end


  def update_defaults

    begin
      DefaultValues.from_hash({
                                "record_type" => "resource",
                                "lock_version" => params[:resource].delete('lock_version'),
                                "defaults" => cleanup_params_for_schema(
                                                                        params[:resource], 
                                                                        JSONModel(:resource).schema
                                                                        )
                              }).save

      flash[:success] = "Defaults updated"

      redirect_to :controller => :resources, :action => :defaults
    rescue Exception => e
      flash[:error] = e.message
      redirect_to :controller => :resources, :action => :defaults
    end

  end

  private

  def fetch_tree
    flash.keep # keep the flash... just in case this fires before the form is loaded

    tree = []

    limit_to = if  params[:node_uri] && !params[:node_uri].include?("/resources/") 
                 params[:node_uri]
               else
                 "root"
               end

    if !params[:hash].blank?
      node_id = params[:hash].sub("tree::", "").sub("#", "")
      if node_id.starts_with?("resource")
        limit_to = "root"
      elsif node_id.starts_with?("archival_object")
        limit_to = JSONModel(:archival_object).uri_for(node_id.sub("archival_object_", "").to_i)
      end
    end

    tree = JSONModel(:resource_tree).find(nil, :resource_id => params[:id], :limit_to => limit_to).to_hash(:validated)

    prepare_tree_nodes(tree) do |node|

      node['text'] = node['title']
      node['level'] = I18n.t("enumerations.archival_record_level.#{node['level']}", :default => node['level'])
      node['instance_types'] = node['instance_types'].map{|instance_type| I18n.t("enumerations.instance_instance_type.#{instance_type}", :default => instance_type)}
      node['containers'].each{|container|
        container["type_1"] = I18n.t("enumerations.container_type.#{container["type_1"]}", :default => container["type_1"]) if container["type_1"]
        container["type_2"] = I18n.t("enumerations.container_type.#{container["type_2"]}", :default => container["type_2"]) if container["type_2"]
        container["type_3"] = I18n.t("enumerations.container_type.#{container["type_3"]}", :default => container["type_3"]) if container["type_3"]
      }
      node_db_id = node['id']

      node['id'] = "#{node["node_type"]}_#{node["id"]}"

      if node['has_children'] && node['children'].empty?
        node['children'] = true
      end

      node['type'] = node['node_type']

      node['li_attr'] = {
        "data-uri" => node['record_uri'],
        "data-id" => node_db_id,
        "rel" => node['node_type']
      }
      node['a_attr'] = {
        "href" => "#tree::#{node['id']}",
        "title" => node["title"]
      }

      if node['node_type'] == 'resource' || node['record_uri'] == limit_to
#        node['state'] = {'opened' => true}
      end

    end

    tree

  end


  # refactoring note: suspiciously similar to accessions_controller.rb
  def fetch_resolved(id)
    resource = JSONModel(:resource).find(id, find_opts)

    if resource['classifications'] 
      resource['classifications'].each do |classification|
        next unless classification['_resolved']
        resolved = classification["_resolved"] 
        resolved['title'] = ClassificationHelper.format_classification(resolved['path_from_root'])
      end 
    end

    resource
  end

  # read CSV file
  def read_csv(file)
    csv = CSV.parse(csv_text, :headers => true)
    csv.each do |row|
      Moulding.create!(row.to_hash)
    end
    csv
  end

  # create archival object from the csv.. similar to accession..
  def csv_resource(csv) 
  @resource = Resource.new(:title => I18n.t("resource.title_default", :default => ""))._always_valid!

    if params[:accession_id]
      acc = Accession.find(params[:accession_id], find_opts)

      if csv
        @resource.populate_from_accession(csv)
        flash.now[:info] = I18n.t("resource._frontend.messages.spawned", JSONModelI18nWrapper.new(:accession => csv))
        flash[:spawned_from_accession] = acc.id
      end

    elsif user_prefs['default_values']
      defaults = DefaultValues.get 'resource'

      if defaults
        @resource.update(defaults.values)
        @form_title = "#{I18n.t('actions.new_prefix')} #{I18n.t('resource._singular')}"
      end

    end

    return render_aspace_partial :partial => "resources/new_inline" if params[:inline]
    
  end
 
end
