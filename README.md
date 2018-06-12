# aspace-import-excel
An [ArchivesSpace ](http://archivesspace.org/) [plugin](https://github.com/archivesspace/archivesspace/blob/master/plugins/PLUGINS_README.md) to support the bulk uploading via Excel SpreadSheet of Archival Objects and (optionally) their associated Creator Agents, Top Containers, Subjects, Digital Objects etc.

Also supports the inport of spreadsheets that will allow for the creation of Digital Objects to be associated with already-created Archival Objects for **Version  2.2.2 and higher** of ArchiveSpace.

## Current Version

  For versions of ArchivesSpace **before** v2.2.2:  [v1.7.8](https://github.com/harvard-library/aspace-import-excel/releases/tag/v1.7.8)  **Note:** This version does *not* support the creation of Digital Objects to be associated with already-created Archival Objects.

  For ArchivesSpace **v2.2.2 and higher**: [v2.1.9](https://github.com/harvard-library/aspace-import-excel/releases/tag/v2.1.9)

## Development

The initial version supports interactive selection of an archival object (or resource) as the starting point of the bulk upload.  

### Bulk upload/creation of Archival Objects

The Excel template will be found in the templates/ folder as [**aspace_import_excel_template.xlsx**](/templates/aspace_import_excel_template.xlsx).  

The intention is not to completely reproduce a Finding Aid as presented in an EAD XML, or to allow for every permutation of Archival Object creation within ArchivesSpace.  We are aiming for the "80% rule"; that is, at least 80% of the work that would be done interactively can be replaced by an excel spreadsheet; additional refinements to individual archival objects (such as addition of agents-as-subjects, assignment of locations to top-level containers, etc.) would take place interactively.

See the [user documentation](user_documentation/USER_DOCUMENTATION.md) for more information. 

### Bulk upload/creation of Digital Objects associated with already-created Archival Objects

**This functionality is turned on by default** See the <a href="#installation">Installation</a> instructions for turning it off.

The Excel template will be found in the templates/ folder as [**aspace_import_excel_DO_template.xlsx**](/templates/aspace_import_excel_DO_template.xlsx). 

As with the original development, we are not completely reproducing all the functionality of ArchivesSpace: only one Digital Object, which can have either or both of one:
  + File with an *Xlink Actuate Attribute* of **onLoad** and an *Xlink Show Attribute* of **embed**
  + File with an Xlink Actuate Attribute of **onRequest** and an *Xlink Show Attribute* of **new**
    
See the [user documentation](user_documentation/USER_DOCUMENTATION.md) for more information. 

## <a name="install">Installation</a>

This is a regular  [ArchivesSpace Plug-in](https://github.com/archivesspace/archivesspace/blob/master/plugins/PLUGINS_README.md).

To install this plug-in:  
1. Download or clone the plug-in from this [GitHub repository](https://github.com/archivesspace/archivesspace/blob/master/plugins/PLUGINS_README.md) into the ArchivesSpace **/plugin/** directory.

2. (Optional) To turn **off** the functionality for creating Digital Objects associated with already-created Archival objects, you must edit **/plugin/aspace-import-excel/frontend/plugin_init.rb**. Change the line 
```bash 
    AppConfig[:hide_do_load] = false
```
to 
```bash 
    AppConfig[:hide_do_load] = true
```
3. Run the **scripts/initialize-plugin script**
   * for Linux, that's `scripts/initialize-plugin.sh aspace-import-excel`
   * for Windows, that's `scripts/initialize-plugin.bat aspace-import-excel`
4. In the **common/config/config.rb** file, add 'aspace-import-excel' to the `AppConfig[:plugins]` array.
5. Stop and restart ArchivesSpace

## User Documentation

User documentation is [available](user_documentation/USER_DOCUMENTATION.md) 

## Contributors

* Bobbi Fox: https://github.com/bobbi-SMR (maintainer)
* Robin Wendler: https://github.com/rwendler
* Julie Wetherill: https://github.com/juliewetherill
* h/t to Chintan Desai: https://github.com/cdesai-qi for catching inconsistencies

