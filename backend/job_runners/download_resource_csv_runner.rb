class DownloadResourceCsvJobRunner  < JobRunner
  include JSONModel
  require 'pp'

  register_for_job_type('download_resource_csv_job')

  def run
     begin
      RequestContext.open(:repo_id => @job.repo_id) do
         @job.write_output("job: #{@job.class.name}  #{@job.pretty_inspect}")
         @job.write_output("@json.job: #{@json.job.pretty_inspect}")
        @job.write_output("job values: #{@job.values}")
        @job.write_output("jobblob: #{@job.values[:job_blob].class.name} #{@job.values[:job_blob].pretty_inspect}")
#        parsed = JSONModel.parse_reference(@json.job["source"])
#        Log.debug("parsed: #{parsed.pretty_inspect}")
        ref = @json.job.ref
        resource_id = ref.split('/').last
        resource = Resource.get_or_die(resource_id)
        resource_jsonmodel = Resource.to_jsonmodel(resource)
        @job.write_output("Downloading CSV for  Resource #{resource_jsonmodel["title"]}  ")
        obj = URIResolver.resolve_references(resource_jsonmodel,
                                           [ "repository", "linked_agents", "subjects", "digital_objects",
                                             'top_container', 'top_container::container_profile'])
        Log.debug("Resource: #{resource.pretty_inspect}")
        Log.debug("'obj': #{obj.pretty_inspect}")
        # csv = whatever
        # job_file = @job.add_file(csv)
        # @job.write_output("File generated at #{job_file[:file_path].inspect} ")
        # csv.unlink
#        @job.record_modified_uris( [@json.job["source"]] )
        @job.write_output("All done. Please click refresh to view your download link.")
        self.success!
        job_file
      end
     rescue Exception => e
       terminal_error = e
       @job.write_output(terminal_error.message)
       @job.write_output(terminal_error.backtrace)
     end
  end

end
