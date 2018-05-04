Dojo source files are no longer included in LedgerSMB.

The directories here are git submodules. To load them from the upstream git sources, make sure you are in the project root
and enter:

```
git submodule init
git submodule update
```

This will check out current releases of Dojo, Dijit, and Utils.

To rebuild the dojo and lsmb javascript, you should have node.js installed. Change into
the UI/js-src/lsmb directory, and run:

```
../util/buildscripts/build.sh --profile lsmb.profile.js
```

This command will clear out the UI/js/ directory, and create a new build of all Javascript files.
