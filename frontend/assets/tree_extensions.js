
$(function () {

	var bulk_btn_str = '<a class="btn btn-xs btn-default bulk-ingest" id="bulk-ingest" rel="archival_object" href="javascript:void(0);" data-record-label="Archival Object" title="Load via Spreadsheet">Load via Spreadsheet</a>';

/* returns a hash with information about the selected archival object */
	var get_object_info = function() {
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
	var add_bulk_button = function() {
	    var $tmpBtn = $("#bulk-ingest");
	    if ($tmpBtn.length == 1) {
		//		    alert("we got it already!");
	    }
	    else {
		var $next = $('.btn.add-child');
		if ($next.length == 1) {
		    $next.parent().append(bulk_btn_str);
		    //	alert("created!");
		}
	    }
	}

	add_bulk_button();

	$(document).on('treesingleselected.aspace', function() { 
		add_bulk_button();
	    });

	var toggleTreeSpinner = function(){
	    $(".archives-tree-container .spinner").toggle();
	}
	var file_form = function(obj) {
	    $f_form = $("<form/>", {
		    action: "/resources_update",
		    method: "post",
		    enctype: "multipart/form-data",
		    "class": "form-horizontal aspace-record-form",
		    id: "spreadsheet_form"
		});
	
	    $f_form.append( '<section id="job_filenames_"> <span class="btn btn-success btn-sm fileinput-button"> <span class="glyphicon glyphicon-plus icon-white"></span> <span>Add file</span> <input name="files[]" multiple="multiple" type="file"></span> <div id="files"> <div class="hint"><span class="plus">+</span> Drag and drop files here</div> </div> </section>');
	};
 
	$(document).on('loadedrecordform.aspace', function () {
		add_bulk_button();
	    });

	$(document).on('click', '#bulk-ingest', function(e) {
		toggleTreeSpinner();
		obj = get_object_info();
		if ($.isEmptyObject(obj)) {
		    return;
		}
			/* here's where we add the ajax, deity help us */
		alert("we got " + obj.id + " ref_id: " + obj.ref_id + " resource: " + obj.resource + " position: " + obj.position);
		console.log("we got " + obj.id + " ref_id: " + obj.ref_id + " resource: " + obj.resource + " position: " + obj.position);
		toggleTreeSpinner();

	    });
    });