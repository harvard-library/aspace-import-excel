# The extras/ Directory
This directory contains files that may need to be copied to another directory upon installation.

## modified_initialize-plugin.bat

This DOS batch file is used to overcome a problem with **\scripts\initialize-plugin.bat**, which is currently downloading into the **\plugins\aspace-import-excel** the latest version of [Bundler](https://bundler.io/) that is incompatible with the version of Bundler that the core ArchivesSpace uses.