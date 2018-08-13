/*
   Copyright 2017 Harvard Library
   License: MIT license (https://opensource.org/licenses/MIT )
   Author: Bobbi Fox
   Version: 1.04

   This script supports the ingest into ArchivesSpace of Excel Spreadsheet data.  It currently supports both
   ArchivesSpace 1.* and ArchivesSpace 2.*
 */


$(function () {
	var aspace_version = (typeof(TreeToolbarConfiguration) === 'undefined')? 1 : 2;
	var file_modal_html = '';
	var $file_form_modal;

	/* used in aspace v1.* */
	var bulk_btn_str = '<a class="btn btn-xs btn-default bulk-ingest" id="bulk-ingest" rel="archival_object" href="javascript:void(0);" data-record-label="Archival Object" title="Load via Spreadsheet">Load via Spreadsheet</a>';

	
/* returns a hash with information about the selected archival object or resource */
	var get_object_info = function() {
	    var ret_obj = new Object;
	    var $tree = $("#archives_tree");
	    var $obj_form = $("#archival_object_form");
	    if (typeof $obj_form.attr("action") !== 'undefined') {
		ret_obj.type = "archival_object";
		ret_obj.aoid = $obj_form.find("#id").val();
		ret_obj.ref_id = $obj_form.find("#archival_object_ref_id_").val();
		ret_obj.resource = $obj_form.find("#archival_object_resource_").val();
		ret_obj.rid = (aspace_version === 1)? $tree.attr("data-root-id") : ret_obj.resource.split('/').pop();
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
		    ret_obj.rid =  (aspace_version === 1)? $tree.attr("data-root-id"): $obj_form.find("#id").val();
		}
	    }
	    return ret_obj;
	}
   
	/* adds the spreadsheet load button in AS V1.* */
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
		$("#bulk-ingest").on('click', function() {
			file_modal_html = '';
			fileSelection();
		    });
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
	    $form.attr("action", APP_PATH + "resources/" + rid + "/ssload");
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
			alert("The file has been processed");
			$("#bulk_messages").html(data);
			modalSuccess($file_form_modal);
		    },
		error: function(xhr, status, err) {
			alert("ERROR: " + status + "; Error detected");
			$("#bulk_messages").html(xhr.responseText);
			/* console.log(xhr);
			   console.log(err); */
			/* display error */
			modalError($file_form_modal);
		    }
		});
	    $modal.on("hidden.bs.modal", function (event){
		    /*console.log("hide hit"); */
		    $modal.hide();
		    $("body").css("overflow", "auto");
		});
	}

    
	/* link switching in the tree in AS v1.*  means we have to do some initializing */
	$(document).on('treesingleselected.aspace', function() { 
		add_bulk_button();
		file_modal_html = '';
	    });

    

	var openFileModal = function() {
	    $file_form_modal = AS.openCustomModal("bulkIngestFileModal", "Load Spreadsheet",  file_modal_html, 'large', null, $("#bulkFileButton").get(0));
	    initExcelFileUploadSection();
	    $("#bulkFileButton").on("click",  function(event) {
		    event.stopPropagation();
		    event.preventDefault();
		    handleFileUpload($file_form_modal);
		});
	    var clipboard = new Clipboard('.clip-btn');
	    clipboard.on('success', function(e) {
		    /* console.log('Action:', e.action);
		    console.log('Text:', e.text);
		    console.log('Trigger:', e.trigger); */
		    alert('Copied!');
		});

	    clipboard.on('error', function(e) {
		    console.error('Action:', e.action);
		    console.error('Trigger:', e.trigger);
		    alert("Unable to copy");
		});

	    $file_form_modal.show();
	}
	var modalError = function($modal) {
	    $(".bulkbtn").removeClass("disabled");
            $(".bulkbtn.btn-cancel").text("Close").removeClass("disabled").addClass("close")
	    $(".clip-btn").removeClass("disabled");
	    $modal.find(".close").click(function(event) {
		    $("input").each(function() { 
			    /*console.log($(this).val()); */
			    $(this).val("");
			});
		    $("#bulk_messages").html("");
		    $("#excel_filename").html("");
		    $modal.hide();
		    $("body").css("overflow", "auto");
		});
	}

	var modalSuccess = function($modal) {
	    $(".bulkbtn.btn-cancel").text("Close").removeClass("disabled").addClass("close")
	    $(".clip-btn").removeClass("disabled");
	    $modal.find(".close").click(function(event) {
		    window.location.reload(true);
		});
	}
	
	var toggleTreeSpinner = function(){
	    $(".archives-tree-container .spinner").toggle();
	}
	
 
	$(document).on('loadedrecordform.aspace', function () {
	/* adding the button to the tree on the resource page */
		add_bulk_button();
	    });

    
	var fileSelection = function() { 
	    toggleTreeSpinner();
	    obj = get_object_info();
	    if ($.isEmptyObject(obj)) {
		toggleTreeSpinner();
		return;
	    }
	    file_modal_html = '';
	    if (typeof($file_form_modal) !== 'undefined') {
                   /* console.log("Remove"); */
                   $file_form_modal.remove();
            }
	    /*console.log("we got rid: " + obj.rid + " "  + obj.aoid + " ref_id: " + obj.ref_id + " resource: " + obj.resource + " position: " + obj.position); */
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
	    toggleTreeSpinner();
	};

      var bulkbtnArr = {
            label: 'Load via Spreadsheet',
            cssClasses: 'btn-default',
            onClick: function(event, btn, node, tree, toolbarRenderer) {
                fileSelection();
            },
            isEnabled: function(node, tree, toolbarRenderer) {
                return true;
            },
            isVisible: function(node, tree, toolbarRenderer) {
                return !tree.large_tree.read_only;
            },
            onFormLoaded: function(btn, form, tree, toolbarRenderer) {
                $(btn).removeClass('disabled');
            },
            onToolbarRendered: function(btn, toolbarRenderer) {
                $(btn).addClass('disabled');
            },
        }
    
      if (aspace_version !== 1) {
	  var res = TreeToolbarConfiguration["resource"];
	  TreeToolbarConfiguration["resource"] = [].concat(res).concat([bulkbtnArr]);
	  var arch = [];
	  var new_val;
	  $.each(TreeToolbarConfiguration["archival_object"], function(index,value) {
		  if ($.type(value) !== "array") {
		       new_val = value ;
		  }
		  else {
		      new_val = value;
		      $.each(value,function(i, v){
			      if (typeof(v['label']) !== 'undefined' && v['label'] === 'Add Child') {
				  new_val = [].concat(value).concat([bulkbtnArr]);
			      }
			  });
		  }
		  arch.push(new_val);
		      
	      });
	  TreeToolbarConfiguration["archival_object"] = arch;
      }
    });
