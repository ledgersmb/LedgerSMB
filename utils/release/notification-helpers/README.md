# ledgersmb-release-scripts
Tools to assist LedgerSMB developers release a new version

######Copyright (c) 20015 SB Tech Services info@sbts.com.au

    Exclusively Licensed for use in the LedgerSMB Project
    Use in whole or part outside of the LedgerSMB Project is Not Permitted

For more information about any of these files, Read The Source Luke

============================
release-irc.sh
============================
    Updates the IRC #ledgersmb TOPIC
    Requires 2 or 3 command line arguments
        * $1 = Type of Release:  stable | preview | both
        * $2 = New version number:
                if $1=stable or both then $2 is stable version number;
                if $1=preview then $2 is preview version number
        * $3 = New version number for preview IF $1 = both

    Two override arguments can be supplied (as the first 2 arguments).
    they are removed from the arg list before normal argument processing.
        *  --aq true|false    # override AutoQuit config setting
        *  --at true|false    # override auto_TOPIC_change config setting
    These are intended mainly for testing rather than normal use.

    Readline support is enabled for user input, including history
    By default history is in /tmp/irc.history
    This can be changed in the config file (~/.lsmb-release)

============================
release-sourceforge.sh
============================
    Updates the default download link on SourceForge.
    This Script is not yet complete


============================
release-wikipedia.pl
============================
    Updates the version information in the Software Sidebar
    at LedgerSMB's wikipedia page
    It updates the English and the Spanish pages

