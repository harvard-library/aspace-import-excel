# Add Digital Objects to Archival Objects

This functionality supports the creation of Digital Objects, associating them with already-existing Archival Objects.

## Constraints
With this plugin:
  + Only one Digital Object can be associated with a single Archival Object
  + The Digital Object can have up to two files associated with it: 
     + a File with an *Xlink Actuate Attribute* of **onLoad** and an *Xlink Show Attribute* of **embed**
     + a File with an Xlink Actuate Attribute of **onRequest** and an *Xlink Show Attribute* of **new**
  + If the Archival Object *already* has a Digital Object associated with it, that row is skipped.    
     
## <a name="spreadsheet">Using the Template to Create a Spreadsheet</a>

The Excel Spreadsheet template is at https://github.com/harvard-library/aspace-import-excel/blob/master/templates/aspace_import_excel_DO_template.xlsx .

Use **Save as**  *(your new filename}*.xlsx to begin creating your spreadsheet.


The template is designed to be flexible enough to accommodate different workflows.  The first row is the place where you can put identifying information, such as "Foo Collection".

As long as you **don't edit** the **row** marked *"ArchivesSpace field code"*, you may hide, delete, or rearrange **columns** to suit your workflow.  Indeed, you will see that there are a few already-hidden columns; these are not currently used, but may be used in future enhancements.

**Note**  that the **Publish Digital Record** column already has in-column drop down data validation defined. 

### <a name="required">Required Columns</a>

The following columns __must__ be filled in:

* EAD ID -- of the Resource to which you're adding Digital Objects.This will be used to confirm that you are trying to add your spreadsheet information to the correct resource. 
* REF ID -- of the Archival Object that you want to associate the new Digital Object with

## <a name="defs">Column Definitions</a>

Below is a discussion of each used column in the spreadsheet. 

Column | Value | Default | Comment
-------|-------|---------|---------
EAD ID | String || **REQUIRED**
REF ID | String || **REQUIRED**
Digital Object ID | String|| Leave blank to get a automatically-assigned Digital Object ID based on the REF ID.  You can override this, but make sure it's unique
Digital Object Title | String|| If blank, the Archival Object's Title will be assigned
Publish Digital Object Record|TRUE or FALSE|FALSE|This value will be inherited by each File, as well as the Digital Object
File URL of Linked-to digital object|URL String||This will be assigned an Xlink Actuate Attribute of **onRequest** and an *Xlink Show Attribute* of **new**
File URL of Thumbnail|URL String||This will be assigned an *Xlink Actuate Attribute* of **onLoad** and an *Xlink Show Attribute* of **embed**; the "is representative" flag is set to TRUE



