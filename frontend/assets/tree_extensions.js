
$(function () {
	$(document).on('loadedrecordform.aspace', function () {
		var bulk_btn = $('.btn.bulk-ingest:not(.myplugin-inited)');
		bulk_btn.on("click", function(e) {
			ao_obj = get_ao_info();
			if ($.isEmptyObject(ao_obj))
				 return;
		  alert("we got " + ao_obj.id + " ref_id: " + ao_obj.ref_id + " resource: " + ao_obj.resource + " position: " + ao_obj.position);
		  console.log("we got " + ao_obj.id + " ref_id: " + ao_obj.ref_id + " resource: " + ao_obj.resource + " position: " + ao_obj.position);
		    });
	       bulk_btn.addClass('myplugin-inited');

	    });
    });
/* returns a hash with information about the selected archival object */
function get_ao_info() {
    ret_obj = new Object;
    $form = $("#archival_object_form");
    if (!$.isEmptyObject($form)) {
	    ret_obj.id = $form.find("#id").val();
	    ret_obj.ref_id = $form.find("#archival_object_ref_id_").val();
	    ret_obj.resource = $form.find("#archival_object_resource_").val();
	    ret_obj.position = $form.find("#archival_object_position_").val();
    }
    return ret_obj;
}

