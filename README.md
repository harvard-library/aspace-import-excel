# aspace-import-excel
An [ArchivesSpace ](http://archivesspace.org/) [plugin](https://github.com/archivesspace/tech-docs/blob/master/customization/plugins.md) to support the bulk uploading via Excel SpreadSheet of Archival Objects and (optionally) their associated Creator Agents, Top Containers, Subjects, Digital Objects etc.

Also supports the import of spreadsheets that will allow for the creation of Digital Objects to be associated with already-created Archival Objects for **Version  2.2.2 and higher** of ArchiveSpace.

## Current Version

  For versions of ArchivesSpace **before** v2.2.2:  [v1.7.8](https://github.com/harvard-library/aspace-import-excel/releases/tag/v1.7.8)

   **NOTE**: v1.7.8 does *not* support the creation of Digital Objects to be associated with already-created Archival Objects.

  For ArchivesSpace **v2.2.2 and higher**:  [v3.0.4](https://github.com/harvard-library/aspace-import-excel/releases/tag/v3.0.4)

## Development

This plugin supports interactive selection of an archival object (or resource) as the starting point of the bulk upload.

Version 3.0 incorporates new functionality for uploading archival objects (described in the [user documentation](user_documentation/archival_objects_instructions.md)), which supports the use of an [expansion](templates/extended_aspace_import_excel_template.xlsx) to the [original](templates/aspace_import_excel_template.xlsx) Excel template.  Version 3.0 is, however, backward compatible, so that users whose workflow is satisfied with the original template can continue to use it.

**Note:** If you have upgraded to ArchivesSpace v2.7 or higher, please be aware that information about the Language of Materials is handled differently. The changes are described in detail in the [user documentation](user_documentation/archival_objects_instructions.md) under **Language**.

The Excel templates will be found in the templates/ folder as
 *  *New in V3.0*: [**extended_aspace_import_excel_template**](templates/extended_aspace_import_excel_template.xlsx)

 * [**aspace_import_excel_template.xlsx**](templates/aspace_import_excel_template.xlsx).

The intention is not to completely reproduce a Finding Aid as presented in an EAD XML, or to allow for every permutation of Archival Object creation within ArchivesSpace.  We are aiming for the "80% rule"; that is, at least 80% of the work that would be done interactively can be replaced by an excel spreadsheet; additional refinements to individual archival objects (such as assignment of locations to top-level containers) would take place interactively.

See the [user documentation](user_documentation/USER_DOCUMENTATION.md) for more information.

### Bulk upload/creation of Digital Objects associated with already-created Archival Objects

**This functionality is turned on by default** See the <a href="#installation">Installation</a> instructions for turning it off.

The Excel template will be found in the templates/ folder as [**aspace_import_excel_DO_template.xlsx**](templates/aspace_import_excel_DO_template.xlsx).

As with the original development, we are not completely reproducing all the functionality of ArchivesSpace: only one Digital Object, which can have either or both of one:
  + File with an *Xlink Actuate Attribute* of **onLoad** and an *Xlink Show Attribute* of **embed**
  + File with an Xlink Actuate Attribute of **onRequest** and an *Xlink Show Attribute* of **new**

See the [user documentation](user_documentation/USER_DOCUMENTATION.md) for more information.



## <a name="install">Installation</a>

This is a regular  [ArchivesSpace Plug-in](https://github.com/archivesspace/tech-docs/blob/master/customization/plugins.md).

To install this plug-in:
1.  Either clone this plugin, or download the latest version:
    - Clone the plug-in from this [GitHub repository](https://github.com/harvard-library/aspace-import-excel) into the ArchivesSpace **/plugins/** directory.
    - Download the zipfile of the  appropriate version: see [Current Versions](#current_versions) for links to the appropriate release download. Unzip the download into the **/plugins/** directory.  You will probably need to rename the top folder/directory to **aspace-import-excel**.

2. (Optional) To turn **off** the functionality for creating Digital Objects associated with already-created Archival objects, you must edit **/plugin/aspace-import-excel/frontend/plugin_init.rb**. Change the line
```bash
    AppConfig[:hide_do_load] = false
```
to
```bash
    AppConfig[:hide_do_load] = true
```
3. **IF** you are running, on Windows, a version of ArchivesSpace that is *lower* than version **2.6.0**:

     There was a problem with Bundler versioning.

Copy
```
archivesspace\aspace-import-excel\extras\modified_initialize-plugin.bat
```
to
```
archivesspace\scripts
```

  **UPDATE**: You no longer need to use this modified .bat script **if** you are running ArchivesSpace 2.6.0 or higher.


4. Run the initializer script:
   * for Linux, that's
   ```bash
   scripts/initialize-plugin.sh aspace-import-excel
   ```
   * for Windows, running an ArchivesSpace version **lower than 2.6.0** ,that's
   ```
   scripts\modified_initialize-plugin.bat aspace-import-excel
   ```
   Otherwise, for Windows running ArchivesSpace version **2.6.0** and higher:
   ```
   scripts\initialize-plugin.bat aspace-import-excel
   ```


5. In the **common/config/config.rb** file, add 'aspace-import-excel' to the `AppConfig[:plugins]` array.
6. Stop and restart ArchivesSpace

### Why we don't include a Gemfile.lock in this repository

We have found that when we include a `Gemfile.lock` file in our plugin, some sites have found that, after initializing the plugin and trying to restart ArchivesSpace, they get errors like this:
```bash
[!] There was an error parsing Gemfile: You cannot specify the same gem twice with different version requirements.
You specified: rubyzip (~> 1.2.2) and rubyzip (= 1.0.0). Bundler cannot continue.
```

This problem does not seem to occur when the `Gemfile.lock` is created through the initialization instead.



## User Documentation

User documentation is [available](user_documentation/USER_DOCUMENTATION.md)

## Contributors

* Bobbi Fox: [@bobbi-SMR](https://github.com/bobbi-SMR) (maintainer)
* Robin Wendler: [@rwendler](https://github.com/rwendler)
* Julie Wetherill: [@juliewetherill](https://github.com/juliewetherill)
* Adrienne Pruitt: [@adriennepruitt2](https://github.com/adriennepruitt2)
* Dave Mayo: [@pobocks](https://github.com/pobocks)
* h/t to Chintan Desai: [@cdesai-qi](https://github.com/cdesai-qi) for catching inconsistencies
