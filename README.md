# aspace-import-excel
An [ArchivesSpace ](http://archivesspace.org/) [plugin](https://github.com/archivesspace/archivesspace/blob/master/plugins/PLUGINS_README.md) to support the bulk uploading via Excel SpreadSheet of Archival Objects and (optionally) their associated Creator Agents, Top Containers, Subjects, Digital Objects etc.

## Current Version
{Branch **support_ASpace_1**} **v1.7.3**  This supports ArchivesSpaces versions **before** 2.2.2

## Initial development

The initial version supports interactive selection of an archival object (or resource) as the starting point of the bulk upload.  


The Excel template will be found in the templates/ folder as [**aspace_import_excel_template.xlsx**](/templates/aspace_import_excel_template.xlsx).  As we expand this plugin to support background job bulk-ingest, there may be more templates provided, or this template will be refined.


The intention is not to completely reproduce a Finding Aid as presented in an EAD XML, or to allow for every permutation of Archival Object creation within ArchivesSpace.  We are aiming for the "80% rule"; that is, at least 80% of the work that would be done interactively can be replaced by an excel spreadsheet; additional refinements to individual archival objects (such as addition of agents-as-subjects, assignment of locations to top-level containers, etc.) would take place interactively.

## <a name="install">Installation</a>

This is a regular  [ArchivesSpace Plug-in](https://github.com/archivesspace/archivesspace/blob/master/plugins/PLUGINS_README.md).
To install this plug-in:  
1. Download or clone the plug-in from this [GitHub repository](https://github.com/archivesspace/archivesspace/blob/master/plugins/PLUGINS_README.md) into the ArchivesSpace **/plugin/** directory.
2. Run the **scripts/initialize-plugin script**
   * for Linux, that's `scripts/initialize-plugin.sh aspace-import-excel`
   * for Windows, that's `scripts/initialize-plugin.bat aspace-import-excel`
3. In the **common/config/config.rb** file, add 'aspace-import-excel' to the `AppConfig[:plugins]` array.
4. Stop and restart ArchivesSpace

## User Documentation

User documentation is [available](user_documentation/USER_DOCUMENTATION.md) 

## Contributors

* Bobbi Fox: https://github.com/bobbi-SMR (maintainer)
* Robin Wendler: https://github.com/rwendler

