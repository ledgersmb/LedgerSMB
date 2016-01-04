# ledgersmb-release-scripts
Tools to assist LedgerSMB developers release a new version

######Copyright (c) 2015 SB Tech Services info@sbts.com.au

    Exclusively Licensed for use in the LedgerSMB Project
    Use in whole or part outside of the LedgerSMB Project is Not Permitted

For more information about any of these files, Read The Source Luke

============================
.lsmb-release.sample
============================
    Sample config file.
    You WILL need to edit it for your environment
    Should be renamed to ~/.lsmb-release
    
    The config file is in inifile format with [sections] and key = value pairs.
    eg:
        [irc]
        Server = chat.freenode.net
        Port   = 6667


============================
release-notifications.sh
============================
    The main script that will call all of the others.
    This script requires several arguments to be set and exported in the calling shell
        * $release_version
        * $release_date
        * $release_type
        * $release_branch

        $release_type MUST have a value of "old" or "stable" or "preview" or "both"
          * old     - Only sends Release Emails
          * stable  - Updates Stable Release information
          * preview - Updates Preview Release information
          * both    - Updates Stable and Preview Release information


============================
bash-functions.sh
============================
    A library of functions that are common to most of the scripts
    One Environment Variable MUST be set before sourcing this file.
    eg:
        ConfigFile="$HOME/.lsmb-release"
    This can be set to any location/file you want as long as it is readable by the library.

