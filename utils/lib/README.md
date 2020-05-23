# ledgersmb-release-scripts

Tools to assist LedgerSMB users and developers

```plain
Copyright (c) 2006 - 2020 LedgerSMB Project
Written by SB Tech Services info@sbts.com.au
```

For more information about any of these files, Read The Source Luke

## bash-functions.sh

A library of functions that are common to most of the scripts

If you are intending to use the configuration file functions
One Environment Variable MUST be set before sourcing this file.

e.g.:

`ConfigFile="$HOME/.lsmb-release"`

This can be set to any location/file you want as long as it is readable by
the library.
