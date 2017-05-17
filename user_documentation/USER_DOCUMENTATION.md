# Using the Excel Spreadsheet Template to add Archival Objects to a Resource
**Note** *that the Resource must already be defined.*

## Initiating the ingest
1. In ArchivesSpace, where you invoke the ingest depends on what you are trying to do.
   + **If** the resource has no Archival Objects, or you want your Archival Objects to be appended to the end of the list of first-level Archival Objects, locate the desired Resource record. </li>
   + **Otherwise**, if you want the first Archival Object in your list to be inserted as a sibling/child (see <a href="#hier">Hierarchical Relationship</a>, below) of an *already-existing* Archival Object, locate the Archival Object where you want to begin your insertion. You can either search for it or select it from the tree that displays on the Resource record. In the latter case, the page will reload to that Archival Object.
   
2. When you have displayed the Resource or the Archival Object as appropriate, make sure you are in *edit* mode. A "Load via Spreadsheet" button will appear. <img src="EmptyResource.png" alt="Finding the Load via Spreadsheet button on an empty resource"/>

3. Click on the button.  You will see a Load Spreadsheet modal window, with the rest of the page "greyed out". <img src="OpenLoadSpreadsheet.png" alt="the Load Spreadsheet modal window"/>

4. Click on "Add File" to browse and locate a file on your system.  Select the Excel File.
5. Once you've identified the file, click on **"Import from SpreadSheet"**. The Ingester will start; the rest of the page will continue to be "greyed out". 
6. When the ingest is finished, there will be an alert pop-up. 
7. Click to close the popup, and you will be presented with a report of the processing.
8. You can click on "Copy to clipboard" to get a tabbed version of the report to examine and/or save.

## Using the Template to Create a Spreadsheet

The template is designed to be flexible enough to accommodate different workflows.

As long as you **don't edit** the **row** marked *"ArchivesSpace field code"*, you may hide, delete, or rearrange **columns** to suit your workflow.  Indeed, you will see that there are a few already-hidden columns; these are not currently used, but may be used in future enhancements.

**Note**  that some columns already have in-column drop down data validation defined.  You may of course add more of these. See [The Excel help page](https://support.office.com/en-us/article/Apply-data-validation-to-cells-29FECBCC-D1B9-42C1-9D76-EFF3CE5F7249) to learn how to create these. 

<a href="#defs">Column Definitions</a> \| <a href="#dates">Dates</a> \| <a href="#extent">Extent</a> \| <a href="#contain">Container</a> \| <a href="#digital">Digital Objects</a> \| <a href="#agent">Agents</a> \| <a href="#subject">Subjects</a> \| <a href="#note">Notes</a>

### <a name="required">Required Columns</a>

There are very few columns that _must_ be filled in:

* **EAD ID**  - of the resource to which you're adding Archival Objects. This will be used to confirm that you are trying to add your spreadsheet information to the correct resource. 
* The **<a name="hier">Hierarchical Relationship</a>** of the new Archival Object to the selected resource or selected Archival Object: If you've selected a Resource, **1** indicates that this is the first level of Archival Objects.  If you have selected an Archival Object, use **1** if you're adding a sibling to a selected Archival Object, **2** if a child, etc. You can therefore describe several levels of Archival Objects in a single spreadsheet.
* **The Description Level**  This is an in-column drop-down. <img src="descriptionLevelDropDown.png" alt="The Description Level in-column drop down"/>
* EITHER the **Title** OR a **Creation Date** that must have at least a  begin date  or a date expression.

## <a name="defs">Column Definitions</a>

Below is a discussion of each used column in the spreadsheet. 

For columns where the value is from a Controlled Value List, you can fill in either the controlled list's Value **or** the Translation.  It must be entered **exactly** as it is written (lower case, title case, etc.). As an example (for English), in the *Extent Extent Type* controlled list, "cubic feet" is represented as the **value** "cubic_feet" or the **translation** "Cubic Feet".  Entering "cubic feet" would result in an error message.

Column | Value | Default | Comment
-------|-------|---------|---------
EAD ID | String | | **REQUIRED**
Title  | String| |Title of the Archival Object; required if no Creation Date information
Component Unit Identifier| String | |
Hierarchical Relationship| Number | | **REQUIRED**
Description Level| in column drop-down || **REQUIRED**
Publish?| in column drop-down | **False** | This is applied to any information (such as subject, note) created with this Archival Object
Restrictions Apply? | in column drop-down | **False** | 
Processing Note | String | | No markup allowed

<a href="#defs">Column Definitions</a> \| <a href="#dates">Dates</a> \| <a href="#extent">Extent</a> \| <a href="#contain">Container</a> \| <a href="#digital">Digital Objects</a> \| <a href="#agent">Agents</a> \| <a href="#subject">Subjects</a> \| <a href="#note">Notes</a>

### <a name="dates">Dates</a>

A Date must have **at least** either a *begin date* or a *date expression.*

Column | Value | Default | Comment
-------|-------|---------|---------
Dates Label | String | creation| from the *Date Label* controlled value list
Date Begin | a Date string || in one of the following: **YYYY, YYYY-MM, or YYYY-MM-DD**
Date End | a Date string || in one of the following: **YYYY, YYYY-MM, or YYYY-MM-DD**
Date Type | in column drop-down| *inclusive*| 
Date Expression |String||
Date Certainty |String | | from the *Date Certainty* controlled value list

<a href="#defs">Column Definitions</a> \| <a href="#dates">Dates</a> \| <a href="#extent">Extent</a> \| <a href="#contain">Container</a> \| <a href="#digital">Digital Objects</a> \| <a href="#agent">Agents</a> \| <a href="#subject">Subjects</a> \| <a href="#note">Notes</a>

### <a name="extent">Extent Information</a>

Please note the required fields.

Column | Value | Default | Comment
-------|-------|---------|---------
Extent portion | String| whole| from the *Extent Portion* controlled value list
Extent number | Number||**REQUIRED**
Extent type | String| |**REQUIRED** from the *Extent Extent Type* controlled value list
Container Summary|String||
Physical details |String||
Dimensions| String ||

<a href="#defs">Column Definitions</a> \| <a href="#dates">Dates</a> \| <a href="#extent">Extent</a> \| <a href="#contain">Container</a> \| <a href="#digital">Digital Objects</a> \| <a href="#agent">Agents</a> \| <a href="#subject">Subjects</a> \| <a href="#note">Notes</a>

### <a name="contain">Container Information  - Creating a Container Instance</a>

A Container instance associates the Archival Object with a Top Container, with additional information on Child and Grandchild sub-containers if present.

The ingester will try to find an already-created Top Container in the database.
+ If you have defined a barcode:
   + If there's a match for that repository, that Top Container will be used without further checking.
   + Otherwise, a new Top Container will be created.
+ If you have not defined a barcode:
   + The type and indicator will be used to search the database for a Top Container that is already associated with the resource;
   + Otherwise, a new Top Container will be created.


If you are specifying container information, note that both **type** and **indicator** are required for each level (top, child, and grandchild) you want to specify.

Column | Value | Default | Comment
-------|-------|---------|---------
Container Instance type| String | | **REQUIRED** if you are defining a Container Instance. Value from the *Instance Instance Type* controlled value list
Top Container type | String | Box| from the *Container Type* controlled value list
Top Container indicator|String | Unknown || **REQUIRED**
Child type | String||from the *Container Type* controlled value list
Child indicator|String |Unknown   || *only used if a Child type is specified*
Grandchild type | String||from the *Container Type* controlled value list
Grandchild indicator|String | Unknown  || *only used if a Grandchild type is specified*

<a href="#defs">Column Definitions</a> \| <a href="#dates">Dates</a> \| <a href="#extent">Extent</a> \| <a href="#contain">Container</a> \| <a href="#digital">Digital Objects</a> \| <a href="#agent">Agents</a> \| <a href="#subject">Subjects</a> \| <a href="#note">Notes</a>

### <a name="digital">Digital Objects</a>

Ingest allows you to create a Digital Object, and associate it with the Archival Object.  The "publish" state will be whatever the "publish" state of the Archival Object has been defined to be.

Column | Value | Default | Comment
-------|-------|---------|---------
Digital Object Title| String || If no Digital Object Title is provided, the display header string of the parent Archival Object will be used.
URL of Linked-out digital object| URL String ||  this becomes the File Version with the **actuate_attribute** set to "onRequest" and the **show_attribute** set to "new"
URL of thumbnail| URL String ||  if defined, this becomes the File version with the **actuate_attribute** set to "onLoad", the **show_attribute** set to "embed", and the "is representative" flag is set to TRUE.

<a href="#defs">Column Definitions</a> \| <a href="#dates">Dates</a> \| <a href="#extent">Extent</a> \| <a href="#contain">Container</a> \| <a href="#digital">Digital Objects</a> \| <a href="#agent">Agents</a> \| <a href="#subject">Subjects</a> \| <a href="#note">Notes</a>


### <a name="agent">Agent Objects</a>

The ingester allows you to link Agents (*CREATOR role only!*) to Archival objects.  You can specify up to 3 Person Agents, up to 2 Corporate Agents, and one Family Agent per Archival object.

If you have previously defined the Agent(s) you are using, you may use the Record ID number (e.g.:  for the Agent URI /agents */agent_person/1249*, you would use **1249**) OR the full header header string, with all capitalization and punctuation.

Either the Record ID *or* the header string is **required**; if you include both, and the record isn't found, a new Agent record will be created.  The header string will be used as the **family_name** if it's a Family Agent, and the **primary_name**  otherwise.

If for some reason you enter a Record ID and **not** the header string, and that ID is not found, a new Agent record will be created with the name "PLACEHOLDER FOR *{agent type}* ID *{ id number}* NOT FOUND", so that you may easily find that record later and edit/merge it. In this case, the new Agent would be marked publish=false. When you correct the record, change publish to true if appropriate.

#### Person agents:

Column | Value | Default | Comment
-------|-------|---------|---------
Agent/Creator (1) Record ID  | Number||
Agent/Creator (1) header string  |String|| must be the entire header, including punctuation & capitalization
Agent/Creator (1) Relator|String|| If supplying relator, term must be from the *Linked Agent Archival Record Relators*  controlled value list.
Agent/Creator (2) Record ID  | Number||
Agent/Creator (2) header string  |String|| must be the entire header, including punctuation & capitalization
Agent/Creator (2) Relator|String||  If supplying relator, term must be from the *Linked Agent Archival Record Relators*  controlled value list.
Agent/Creator (3) Record ID  | Number||
Agent/Creator (3) header string  |String|| must be the entire header, including punctuation & capitalization
Agent/Creator (3) Relator|String||  If supplying relator, term must be from the *Linked Agent Archival Record Relators*  controlled value list.

#### Family Agent:
Column | Value | Default | Comment
-------|-------|---------|---------
Family Agent/Creator  Record ID  | Number||
Family Agent/Creator header string  |String|| must be the entire header, including punctuation & capitalization
Family Agent/Creator Relator|String|| If supplying relator, term must be from the *Linked Agent Archival Record Relators*  controlled value list.

#### Corporate Agents:
Column | Value | Default | Comment
-------|-------|---------|---------
Corporate Agent/Creator  Record ID  | Number||
Corporate Agent/Creator header string  |String|| must be the entire header, including punctuation & capitalization
Corporate Agent/Creator Relator|string||  If supplying relator, term must be from the *Linked Agent Archival Record Relators*  controlled value list.
Corporate Agent/Creator  Record ID (2)  | Number||
Corporate Agent/Creator header string (2)  |String|| must be the entire header, including punctuation & capitalization
Corporate Agent/Creator Relator (2)|String||  If supplying relator, term must be from the *Linked Agent Archival Record Relators*  controlled value list.


<a href="#defs">Column Definitions</a> \| <a href="#dates">Dates</a> \| <a href="#extent">Extent</a> \| <a href="#contain">Container</a> \| <a href="#digital">Digital Objects</a> \| <a href="#agent">Agents</a> \| <a href="#subject">Subjects</a> \| <a href="#note">Notes</a>

### <a name="subject">Subjects</a>

As with <a href="#agent">Agents</a>, you may associate Subjects with the Archival Object.  You may associate up to two Subject records.  If you know the Record ID, you may use that instead of the **term**, **type**, and **source** in a manner similar to the way that Agent specifications are made, with the same database lookup and handling done there.  Again, if you want the ingest to look up the **term** in the database, you must use the entire Subject header, including any punctuation or capitalization.

Column | Value | Default | Comment
-------|-------|---------|---------
Subject (1) Record ID|Number||
Subject (1) Term |String ||
Subject (1) Type | String| topical|   from the *Subject Term Type*  controlled value list 
Subject (1) Source | String| ingest| from the *Subject Source* controlled value list 
Subject (2) Record ID|Number||
Subject (2) Term |String ||
Subject (2) Type | String| topical|   from the *Subject Term Type*  controlled value list 
Subject (2) Source | String| ingest| from the *Subject Source* controlled value list 

<a href="#defs">Column Definitions</a> \| <a href="#dates">Dates</a> \| <a href="#extent">Extent</a> \| <a href="#contain">Container</a> \| <a href="#digital">Digital Objects</a> \| <a href="#agent">Agents</a> \| <a href="#subject">Subjects</a> \| <a href="#note">Notes</a>


### <a name="note">Notes fields</a>

You may specify a variety of notes fields.

If the note type allows for subfields, what you specify will be put in the first subfield.

As does ArchivesSpace, you may used Mixed Content (EAD/XML markup).  The Ingester will check to make sure that the entry is "well formed" -- that is, that the opening and closing elements match -- but will **not** validate the text to make sure you're using the proper markup.

The following Notes fields are supported:

+ Abstract
+ Access Restrictions
+ Acquisition Information	
+ Arrangement
+ Biography/History
+ Custodial History
+ Dimensions
+ General	
+ Language of Materials
+ Physical Description
+ Physical Facet
+ Physical Location
+ Preferred Citation
+ Processing Information
+ Related Materials
+ Scope and Contents
+ Separated Materials
+ Use Restrictions

<a href="#defs">Column Definitions</a> \| <a href="#dates">Dates</a> \| <a href="#extent">Extent</a> \| <a href="#contain">Container</a> \| <a href="#digital">Digital Objects</a> \| <a href="#agent">Agents</a> \| <a href="#subject">Subjects</a> \| <a href="#note">Notes</a>
