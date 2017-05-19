# An Example of Using aspace-import-exel

Included in this directory are two spreadsheets which you can use to follow the step-by-step description below, where you create an empty Resource, populate it with the first spreadsheet, then add to it with the second.

## Create a new Resource

Create a new Resource of type **Collection**. You make it as minimal as you like, but you must assign an EAD ID of **hl_test_ingest**.  Don't create any archival objects for it.
<img alt="the empty resource" src="images/empty_collection_view.png"/>

## Loading the First Spreadsheet

<img alt="the empty resource in edit mode" src="images/empty_collection_edit.png"/>


### Select the Spreadsheet

With your new Resource in *edit* mode, click on the "Load via Spreadsheet" button.

<img alt="the 'Load Spreadsheet Popup'" src="images/load_popup.png"/>


Click on the **Add File** button, and select the **empty_test_collection.xlsx** file, that you've downloade from <a href="empty_test_collection.xlsx">here</a> . This spreadsheet creates two top level "Series" Archival Objects; the second Archival Object will also have a child "Item" object.  There are a few errors in the spreadsheet, so that you can see the error reporting mechanism.

Here's what it looks like from an MS Windows view:
<img alt="Selecting the first spreadsheet" src="images/empty_test_file_selection.png"/>

### Click "Import From Spreadsheet"

The importer will "gray out" that button, and begin processing.  When it is completed, you will see a confirmation pop-up:
<img alt="the confirmation popup" src="images/empty_collection_finished_popup.png"/>

Click "OK", and you will be presented with the report of the results:
<img alt="results of the first load" src="images/empty_collection_results.png"/>

### Copying the results

If you click on the "Copy to Clipboard" button, you will get a "Copied" confirmation popup.  You will now have
 get a tabbed copy of the results in your clipboard, which you can then paste into a text file, Word document, Excel spreadsheet, etc.  We've pasted it into an Excel spreadsheet, which we've also <a href="results/first_ss_report.xlsx">uploaded to GitHub</a>:
<img alt="image of spreadsheet paste" src="images/first_ss_report.png"/>

## Adding Children and Siblings to the new Resource
