
$(function () {
	var bulk_btn_str = '<a class="btn btn-xs btn-default bulk-ingest" id="bulk-ingest" rel="archival_object" href="javascript:void(0);" data-record-label="Archival Object" title="Load via Spreadsheet">Load via Spreadsheet</a>';
	var file_modal_html = '';
	var $file_form_modal;

/* returns a hash with information about the selected archival object */
	var get_object_info = function() {
	    var ret_obj = new Object;
	    var $tree = $("#archives_tree");
	    ret_obj.rid = $tree.attr("data-root-id"); 
	    var $obj_form = $("#archival_object_form");
	    if (typeof $obj_form.attr("action") !== 'undefined') {
		ret_obj.type = "archival_object";
		ret_obj.aoid = $obj_form.find("#id").val();
		ret_obj.ref_id = $obj_form.find("#archival_object_ref_id_").val();
		ret_obj.resource = $obj_form.find("#archival_object_resource_").val();
		ret_obj.position = $obj_form.find("#archival_object_position_").val();
	    }
	    else {
		$obj_form = $("#resource_form");
		if (typeof $obj_form.attr("action") !== 'undefined') {
		    ret_obj.type = "resource";
		    ret_obj.resource = $obj_form.attr("action");
		    ret_obj.aoid = '';
		    ret_obj.ref_id = '';
		    ret_obj.position = '';
		}
	    }
	    return ret_obj;
	}

	/* adds the spreadsheet load button */
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

	var initExcelFileUploadSection = function() {
	    var handleExcelFileChange = function() {
		var $input = $(this);
		var filename = $input.val().split("\\").reverse()[0];
		$("#excel_filename").html(filename);
	    };
	    $("#excel_file").on("change", handleExcelFileChange);
	    
	};

        /* submit the file for processing */
	var handleFileUpload = function($modal) {
	    /* don't let the modal disappear on submission */
	    $modal.on("hide.bs.modal", function (event){
		    event.preventDefault();
		    event.stopImmediatePropagation();
		});
	    /* submit via ajax */
	    $form = $("#bulk_ingest_form");
	    rid = $form.find("#rid").val();
	    /* I do this because ajaxSubmit doesn't like the URL property? */
	    $form.attr("action", "/resources/" + rid + "/ssload");
	    $form.ajaxSubmit({
	       type: "POST",
	       beforeSubmit:  function(arr, $form, options) {
			var names = "";
			var hasFile = false;
			var missingFile = 'You have not added a file';
			for (var i=0; i < arr.length; i++) {
			    if (arr[i].type === "file") {
				fileObj = arr[i].value; 
				if  (typeof(fileObj) === "object") {
				    if (typeof(fileObj.type) !== "undefined" && fileObj.type === 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' ) {
					hasFile = true; 
				    }
				    else {
					missingFile = 'The file you have chosen is not an Excel Spreadsheet';
				    }
				}
			    }
			}
			if (!hasFile) {
			    alert(missingFile);
			    $(".bulkbtn").removeClass("disabled");
			    return false;
			}
			$(".bulkbtn").addClass('disabled');
			return true;
		    },		
			/*		uploadProgress:  function(event, position, total, percentComplete) {
			var percentVal = percentComplete + '%';
                        console.log("Percent: " + percentVal);
			}, */
		success: function(data, status, xhr) {
			/*display? */
			alert("Success!");
			console.log("reset modal");
			$("#bulk_messages").html(data);
			modalSuccess($file_form_modal);
		    },
		error: function(xhr, status, err) {
			alert("ERROR: " + status + " " + xhr.responseText);
			console.log(xhr);
			console.log(err);
			/* display error */
			$modal.on("hide.bs.modal", function (event){
				console.log("hide hit");
				$modal.hide();
			    });
			$(".bulkbtn").removeClass("disabled");
		    }
		});
	    $modal.on("hide.bs.modal", function (event){
		    console.log("hide hit");
		    $modal.hide();
		});
	}


	/* link switching in the tree means we have to do some initializing */
	$(document).on('treesingleselected.aspace', function() { 
		add_bulk_button();
		file_modal_html = '';
	    });



	var openFileModal = function() {
	    $file_form_modal = AS.openCustomModal("bulkIngestFileModal", "Load Spreadsheet",  file_modal_html, false, null, $("#bulkFileButton").get(0));
	    initExcelFileUploadSection();
	    $("#bulkFileButton").on("click",  function(event) {
		    event.stopPropagation();
		    event.preventDefault();
		    handleFileUpload($file_form_modal);
		});
	    $file_form_modal.show();
	}

        var modalSuccess = function($modal) {
	    $(".bulkbtn.btn-cancel").text("Close").removeClass("disabled").addClass("close")
	    $modal.find(".close").click(function(event) {
		    window.location.href = APP_PATH+"resources/"+rid + "/edit";
		});
	}
	var toggleTreeSpinner = function(){
	    $(".archives-tree-container .spinner").toggle();
	}
	
 
	$(document).on('loadedrecordform.aspace', function () {
	/* adding the button to the tree on the resource page */
		add_bulk_button();
	    });

	$(document).on('click', '#bulk-ingest', function(e) {
		toggleTreeSpinner();
		obj = get_object_info();
		if ($.isEmptyObject(obj)) {
		    toggleTreeSpinner();
		    return;
		}
		console.log("we got rid: " + obj.rid + " "  + obj.aoid + " ref_id: " + obj.ref_id + " resource: " + obj.resource + " position: " + obj.position);
		if (file_modal_html  === '') {
		    $.ajax({
			url: APP_PATH + "resources/" + obj.rid + "/getfile",
			type: "POST",
  		        data: {aoid: obj.aoid, type: obj.type, ref_id: obj.ref_id, resource: obj.resource, position: obj.position},
			dataType: "html",
			success: function(data) {
				file_modal_html = data;
				openFileModal();
			},
			error: function(xhr,status,err) {
			    alert("ERROR: " + status + " " + err);
                        }

			});
		}
		else {
		    console.log("we have html already");
		    if (typeof($file_form_modal) !== 'undefined') {
			console.log("Remove");
			$file_form_modal.remove();
		    }
		    openFileModal();
		}
		toggleTreeSpinner();
	    });
    });