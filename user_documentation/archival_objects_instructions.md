# Import Archival Objects

## <a name="spreadsheet">Using the Template to Create a Spreadsheet</a>

**aspace-import-excel v3.0** introduces an [expanded Excel Spreadsheet template](../templates/extended_aspace_import_excel_template.xlsx) with new functionality for importing Archival Objects.  

The new functionality consists of support for:

* Individually setting the publish/unpublish flags for <a href="#note">Notes</a>.
* Ability to add <a href="#agent">Agents</a>  as Source and Subject, not just Creator.
* Expanded the number of <a href="#agent">Agents</a>  for each type, including <a href="#increase_agent">directions</a> for adding even more agents.
* Support for more than one <a href="#dates">Date</a>, with the ability to <a href="#increase_dates">add more dates</a>.

The code is backward-compatible with the the original [Excel Spreadsheet template](../templates/aspace_import_excel_template.xlsx) so you may continue using the original if it meets your needs.

Once you've opened the tempate, use **Save as**  *(your new filename}*.xlsx to begin filling in your spreadsheet.


The template is designed to be flexible enough to accommodate different workflows.  The *first row* is the place where you can put identifying information, such as "Foo Collection".

As long as you **don't edit** the **row** marked *"ArchivesSpace field code"*, you may hide, delete, or rearrange **columns** to suit your workflow.  Indeed, you will see that there are a few already-hidden columns; these are not currently used, but may be used in future enhancements. **_DO NOT_** hide required columns.

**Note**  that some columns already have in-column drop down data validation defined.  You may of course add more of these, or edit the ones that are already defined. See [The Excel help page](https://support.office.com/en-us/article/Apply-data-validation-to-cells-29FECBCC-D1B9-42C1-9D76-EFF3CE5F7249) to learn how to create these. 

<a href="#defs">Column Definitions</a> \| <a href="#dates">Dates</a> \| <a href="#extent">Extent</a> \| <a href="#contain">Container</a> \| <a href="#digital">Digital Objects</a> \| <a href="#agent">Agents</a> \| <a href="#subject">Subjects</a> \| <a href="#note">Notes</a>

### <a name="required">Required Columns</a>

There are very few columns that _must_ be filled in:

* **EAD ID**  - of the resource to which you're adding Archival Objects. This will be used to confirm that you are trying to add your spreadsheet information to the correct resource. 
* The **<a name="hier">Hierarchical Relationship</a>** of the new Archival Object to the selected resource or selected Archival Object: If you've selected a Resource, **1** indicates that this is the first level of Archival Objects.  If you have selected an Archival Object, use **1** if you're adding a sibling to a selected Archival Object, **2** if a child, etc. You can therefore describe several levels of Archival Objects in a single spreadsheet.
* **The Description Level**  This is an in-column drop-down. <img src="descriptionLevelDropDown.png" alt="The Description Level in-column drop down"/>
* EITHER the **Title** OR a **valid Date** having at least a begin date or a date expression.

## <a name="defs">Column Definitions</a>

Below is a discussion of each used column in the spreadsheet. 

For columns where the value is from a Controlled Value List, you can fill in either the controlled list's **Value** *or* the **Translation**.  It must be entered **exactly** as it is written (lower case, title case, etc.). As an example (for English), in the *Extent Extent Type* controlled list, "cubic feet" is represented as the **value** `cubic_feet` or the **translation** `Cubic Feet`.  Entering `cubic feet` would result in an error message.

**Notes:** 
1. The application compares the input first against the **Translation**, then, failing that, against the **Value**.
2. In the case that your list has more than one entry with the same **Translation**, the **Value** for the first (lowest position) entry is used.  A **WARN** message will appear in the frontend log file when this application encounters this situation.


Column | Value | Default | Comment
-------|-------|---------|---------
EAD ID | String | | **REQUIRED**
Title  | String| |Title of the Archival Object; required if no Creation Date information
Component Unit Identifier| String | |
Hierarchical Relationship| Number | | **REQUIRED**
Description Level| in column drop-down || **REQUIRED** *from the Archival Record Level controlled value list*
Other Level| String | *unspecified*| This is used if *Other Level* was specified in the **Description Level**
Publish?| in column drop-down | **False** | This is applied to any information (such as subject, note) created with this Archival Object
Restrictions Apply? | in column drop-down | **False** | 
Processing Note | String | | No markup allowed

<a href="#defs">Column Definitions</a> \| <a href="#dates">Dates</a> \| <a href="#extent">Extent</a> \| <a href="#contain">Container</a> \| <a href="#digital">Digital Objects</a> \| <a href="#agent">Agents</a> \| <a href="#subject">Subjects</a> \| <a href="#note">Notes</a>

### <a name="dates">Dates</a>

<span style="color:rebeccapurple">New in version 3.0:</span> Support for more than one Date.  The spreadsheet provides for two dates; you can add more by following the <a href="#increase_dates">instructions</a> for adding additional dates.

A Date must have **a valid label** and **at least** either a *begin date* or a *date expression.*

**NOTE:**  The cell format for cells containing values for *Date Begin* and *Date End* **MUST** be **Text**, not some date format like `yyyy-mm-dd`, if you don't want the hours, minutes, seconds appended (e.g.: *1969-17-17T00:00:00+00.00*).  Some versions of Excel will "helpfully" convert the cell to a date format if you are not watching.

Column | Value | Default | Comment
-------|-------|---------|---------
Dates Label | String | | from the *Date Label* controlled value list. **Note**: If the value given is *not* on the controlled value list, this date will not be processed.
Date Begin | a Date string || in one of the following: **YYYY, YYYY-MM, or YYYY-MM-DD**
Date End | a Date string || in one of the following: **YYYY, YYYY-MM, or YYYY-MM-DD**
Date Type | String| *inclusive*| from the *Date Type* controlled value list. **Note**: If the given value is *not* on the controlled value list, it will be overridden with the value 'inclusive'.
Date Expression |String||
Date Certainty |String | | from the *Date Certainty* controlled value list

### <a name="increase_dates">Adding more dates to the spreadsheet</a>

<span style="color:rebeccapurple">New in version 3.0:</span> 
The plugin supports your adding more than the two dates supplied on the spreadsheet.  To do this, you may edit, locally, the [extended_aspace_import_excel_template.xlsx](../templates/extended_aspace_import_excel_template.xlsx) by copying the set of columns for the second date, inserting them into the template, and editing the labels in Rows 4 and 5 to reflect the next integer number:
  * insert 6 columns next to the second date 
  * copy the six columns of the second date, then paste them into the blank colums
  * edit the labels in Row 4 to increment the number.  For example, for the first added date, you'd edit **dates_label_2** to **dates_label_3** . **NOTE**: it is *extremely important* that you ensure that the labels in Row 4 are edited; otherwise, you may not get the results you're expecting.
  * While not necessary for proper processing, it's recommended that you also update the numbers in Row 5 to avoid confusion.  For example, edit **Date (2) Label** to  **Date (3) Label**. 

<a href="#defs">Column Definitions</a> \| <a href="#dates">Dates</a> \| <a href="#extent">Extent</a> \| <a href="#contain">Container</a> \| <a href="#digital">Digital Objects</a> \| <a href="#agent">Agents</a> \| <a href="#subject">Subjects</a> \| <a href="#note">Notes</a>

### <a name="extent">Extent Information</a>

Extent information is not required, but if you are defining an extent, please note the required fields.

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


**NOTE:** if you want the object in this spreadsheet to be in a Top Container shared with *another Resource*, you must either specify the container by *barcode* or else make sure that at least one archival object in the spreadsheet's Resource with that container has already been created via the usual ArchivesSpace interface.  

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

The ingester allows you to link Agents to Archival objects.  The [extended_aspace_import_excel_template.xlsx](../templates/extended_aspace_import_excel_template.xlsx), as provided, allows for up to **5** Person Agents, up to **2** Family Agents, and up to **3** Corporate Agents per Archival object.  If you need more of any of these types, you can follow the <a href="#increase_agent">directions</a> for adding more agents.

If you have previously defined the Agent(s) you are using, you may use the Record ID number (e.g.:  for the Agent URI /agents */agent_person/1249*, you would use **1249**) OR the full header string, with all capitalization and punctuation.

Either the Record ID *or* the header string is **required**.

If you include both, or only the header, and the record isn't found, a new Agent record will be created.  The header string will be used as the **family_name** if it's a Family Agent, and the **primary_name**  
otherwise.

If you enter the header string *without* the ID, the ingester will try to do an **exact match** against the header; if it finds more than one match (for example, if the database contains two agents with identical headers, but different sources):

  * The ingester will create a **new** agent (with publish=false) containing the header with ' DISAMBIGUATE ME!' appended to it.  For example, given a person agent with a header of 'George Washington', a new person agent would be created with a primary name of 'George Washington DISAMBIGUATE ME!'.  
  * After ingest, you can  use the *merge* functionality to resolve the ambiguities.

If you enter a Record ID and **not** the header string, and that ID is not found, a new Agent record will be created with the name "PLACEHOLDER FOR *{agent type}* ID *{ id number}* NOT FOUND", so that you may easily find that record later and edit/merge it. In this case, the new Agent would be marked publish=false. When you correct the record, change publish to true if appropriate.



If you **only** enter the header string, and a record isn't found in the database, a new Agent will be created, with its Linked Agent Role of **Creator**.

If you enter a Record ID and **not** the header string, and that ID is not found, a new Agent record will be created with the name "PLACEHOLDER FOR *{agent type}* ID *{ id number}* NOT FOUND", so that you may easily find that record later and edit/merge it. In this case, the new Agent would be marked publish=false. When you correct the record, change publish to true if appropriate.



#### Person agents:

Column | Value | Default | Comment
-------|-------|---------|---------
Agent (1) Record ID  | Number||
Agent (1) header string  |String|| must be the entire header, including punctuation & capitalization
Agent Role(1)|String|Creator|<span style="color:rebeccapurple">New in v3.0</span>: from the *Linked Agent Role* controlled value list.
Agent (1) Relator|String|| If supplying relator, term must be from the *Linked Agent Archival Record Relators*  controlled value list.  The default list provided by ArchivesSpace maps to the [MARC Relator Code and Term List](http://www.loc.gov/marc/relators/relaterm.html).
Agent (2) Record ID  | Number||
Agent (2) header string  |String|| must be the entire header, including punctuation & capitalization
Agent Role(2)|String|Creator|<span style="color:rebeccapurple">New in v3.0</span>: from the *Linked Agent Role* controlled value list.
Agent (2) Relator|String||  If supplying relator, term must be from the *Linked Agent Archival Record Relators*  controlled value list.
Agent (3) Record ID  | Number||
Agent (3) header string  |String|| must be the entire header, including punctuation & capitalization
Agent Role(3)|String|Creator|<span style="color:rebeccapurple">New in v3.0</span>: from the *Linked Agent Role* controlled value list.
Agent (3) Relator|String||  If supplying relator, term must be from the *Linked Agent Archival Record Relators*  controlled value list.

#### Family Agents:
Column | Value | Default | Comment
-------|-------|---------|---------
Family Agent  Record ID  | Number||
Family Agent header string  |String|| must be the entire header, including punctuation & capitalization
Family Agent Role|String|Creator|<span style="color:rebeccapurple">New in v3.0</span>: from the *Linked Agent Role* controlled value list.
Family Agent Relator|String|| If supplying relator, term must be from the *Linked Agent Archival Record Relators*  controlled value list.

#### Corporate Agents:
Column | Value | Default | Comment
-------|-------|---------|---------
Corporate Agent  Record ID  | Number||
Corporate Agent header string  |String|| must be the entire header, including punctuation & capitalization
Corporate Agent Role|String|Creator|<span style="color:rebeccapurple">New in v3.0</span>: from the *Linked Agent Role* controlled value list.
Corporate Agent Relator|string||  If supplying relator, term must be from the *Linked Agent Archival Record Relators*  controlled value list.
Corporate Agent  Record ID (2)  | Number||
Corporate Agent header string (2)  |String|| must be the entire header, including punctuation & capitalization
Corporate Agent Role(2)|String|Creator|<span style="color:rebeccapurple">New in v3.0</span>: from the *Linked Agent Role* controlled value list.
Corporate Agent Relator (2)|String||  If supplying relator, term must be from the *Linked Agent Archival Record Relators*  controlled value list.

### <a name="increase_agent">Adding more agents to the spreadsheet</a>

The plugin supports your associating with an Archival Object even more agents of each type.  To do this, you may edit, locally, the [extended_aspace_import_excel_template.xlsx](../templates/extended_aspace_import_excel_template.xlsx) by copying the last set of columns of the particular type, inserting them into the template, and editing the labels in Rows 4 and 5 to reflect the next integer number.

For example, if you were to want *3* Family Agents, you would:
 * insert four blank columns next to the second Family Agent columns
 * copy the four columns of the second Family Agent, and paste them into the blank columns
 * edit the labels in Row 4, incrementing the number. For example, you would edit the label **families_agent_record_id_2** in the _copied_ column to **families_agent_record_id_3**.  **NOTE**: it is *extremely important* that you ensure that the labels in Row 4 are edited; otherwise, you may not get the results you're expecting.
 * While not necessary for proper processing, it's recommended that you also update the numbers in Row 5, to avoid confusion. For example, you would edit the label **Family Agent(2) header string** to **Family Agent(3) header string**


 **Note:** The plugin stops at the first set of columns that are blank.  This means that, if you've filled in the columns for Person Agent 1, and Person Agent 3, leaving Person Agent 2 blank, the plugin *will not*
 process Person Agent 3.

<a href="#defs">Column Definitions</a> \| <a href="#dates">Dates</a> \| <a href="#extent">Extent</a> \| <a href="#contain">Container</a> \| <a href="#digital">Digital Objects</a> \| <a href="#agent">Agents</a> \| <a href="#subject">Subjects</a> \| <a href="#note">Notes</a>

### <a name="subject">Subjects</a>

As with <a href="#agent">Agents</a>, you may associate Subjects with the Archival Object.  You may associate up to two Subject records.  If you know the Record ID, you may use that instead of the **term**, **type**, and **source** in a manner similar to the way that Agent specifications are made, with the same database lookup and handling done there.  Again, if you want the ingest to look up the **term** in the database, you must use the entire Subject header, including any punctuation or capitalization.

If you enter the subject header string *without* the ID, the ingester will try to do an **exact match** against the header; if it finds more than one match (for example, if the database contains two subjects with identical headers, but different sources):

  * The ingester will create a **new** agent (with publish=false) containing the header with ' DISAMBIGUATE ME!' appended to it.  For example, given a subject with a header of 'Black Lives Matter', a new subject  would be created with the header  'Black Lives Matter DISAMBIGUATE ME!'.  
  * After ingest, you can  use the *merge* functionality to resolve the ambiguities.

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

<span style="color:rebeccapurple">New in version 3.0:</span>
Each Note column is accompanied by a "Publish" column, which has in-column drop down data validation (TRUE/FALSE).  The publish flag will be set for that note (and any associated subnote) as follows:
* if the field is left blank, use the value of the Publish field for that Archival Object
* Otherwise, set to True or False as specified.


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
