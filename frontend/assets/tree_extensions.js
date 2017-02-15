
$(function () {
	var toggleTreeSpinner = function(){
	    $(".archives-tree-container .spinner").toggle();
	}



	$(document).on('loadedrecordform.aspace', function () {
		var bulk_btn = $('.btn.bulk-ingest:not(.myplugin-inited)');
		bulk_btn.on("click", function(e) {
			toggleTreeSpinner();
			obj = get_object_info();
			if ($.isEmptyObject(obj))
				 return;
			/* here's where we add the ajax, deity help us */
		  alert("we got " + obj.id + " ref_id: " + obj.ref_id + " resource: " + obj.resource + " position: " + obj.position);
		  console.log("we got " + obj.id + " ref_id: " + obj.ref_id + " resource: " + obj.resource + " position: " + obj.position);
		  toggleTreeSpinner();

		    });
	       bulk_btn.addClass('myplugin-inited');

	    });
    });
/* returns a hash with information about the selected archival object */
function get_object_info() {
    var ret_obj = new Object;
    var $form = $("#archival_object_form");
    if (typeof $form.attr("action") !== 'undefined') {
	ret_obj.type = "archival_object";
	ret_obj.id = $form.find("#id").val();
	ret_obj.ref_id = $form.find("#archival_object_ref_id_").val();
	ret_obj.resource = $form.find("#archival_object_resource_").val();
	ret_obj.position = $form.find("#archival_object_position_").val();
    }
    else {
	$form = $("#resource_form");
	if (typeof $form.attr("action") !== 'undefined') {
	    ret_obj.type = "resource";
	    ret_obj.resource = $form.attr("action");
	    ret_obj.id = '';
	    ret_obj.ref_id = '';
	    ret_obj.position = '';
	}
    }
    return ret_obj;
}

