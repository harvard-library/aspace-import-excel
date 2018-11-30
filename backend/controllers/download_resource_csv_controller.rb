class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/repositories/:repo_id/resources/:id/csv')
    .description("Resource and objects as CSV")
    .params(*BASE_SEARCH_PARAMS,
            ["repo_id", :repo_id],
            ["resource", :id])
    .permissions([])
    .returns([200, ""]) \
  do


    [200, some_headers, content(params[:id])]

  end


  def some_headers
    {
      "Content-Type" => "text/csv; charset=UTF-8",
      "Content-Disposition" => "attachment; filename=\"resource_#{Time.now.iso
8601}.csv\""
    }
  end

  def content(id)
    resource = Resource.get_or_die(id)
    Log.debug("RESOURCE: #{resource.pretty_inspect}")
#    ordered = ordered_records(resource, true, true)
#    json = JSONModel(:resource_ordered_records).from_hash({:uris => resource.ordered_records(true,true), raise_errors = true, trusted = true})
#    Log.error(json.pretty_inspect)
  end
  # Return a depth-first-ordered list of URIs of a tree
  # allow for unpublished and/or suppressed records to be included
  def ordered_records(resource, unpublished = false, suppressed = false)
    if (resource.publish == 0 && !unpublished) || (resource.suppressed == 1 && !suppressed)
      # The whole resource is excluded.
      return []
    end

    id_positions = {}
    id_display_strings = {}
    id_depths = {nil => 0}
    parent_to_child_id = {}
    
    # Any record that is either suppressed or unpublished will be excluded from
    # our results.  Descendants of an excluded record will also be excluded.
    excluded_rows = {}
    
    self.class.node_model.filter(:root_record_id => self.id).select(:id, :position, :parent_id, :display_string, :publish, :suppressed).each do |row|
      id_positions[row[:id]] = row[:position]
      id_display_strings[row[:id]] = row[:display_string]
      parent_to_child_id[row[:parent_id]] ||= []
      parent_to_child_id[row[:parent_id]] << row[:id]
      
      if (row[:publish] == 0 && !unpublished) || (row[:suppressed] == 1 && !suppressed)
        excluded_rows[row[:id]] = true
      end
    end
    
    excluded_rows = apply_exclusions_to_descendants(excluded_rows, parent_to_child_id) if !excluded_rows.empty?
    
    # Our ordered list of record IDs
    result = []
    
    # Start with top-level records
    root_set = [nil]
    id_positions[nil] = 0
    
    while !root_set.empty?
      next_rec = root_set.shift
      if next_rec.nil?
        # Our first iteration.  Nothing to add yet.
      else
        unless excluded_rows[next_rec]
          result << next_rec
        end
      end
      
      children = parent_to_child_id.fetch(next_rec, []).sort_by {|child| id_positions[child]}
      children.reverse.each do |child|
        id_depths[child] = id_depths[next_rec] + 1
        root_set.unshift(child)
      end
    end

    extra_root_properties = self.class.ordered_record_properties([self.id])
    extra_node_properties = self.class.node_model.ordered_record_properties(result)
    
    [{'ref' => self.uri,
       'display_string' => self.title,
       'depth' => 0}.merge(extra_root_properties.fetch(self.id, {}))] +
      result.map {|id| {
        'ref' => self.class.node_model.uri_for(self.class.node_type, id),
        'display_string' => id_display_strings.fetch(id),
        'depth' => id_depths.fetch(id),
      }.merge(extra_node_properties.fetch(id, {}))}
      
  end

end
