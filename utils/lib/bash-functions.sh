#!/bin/bash

############
##
## A library of functions to assist with bash scripts
##      Copyright (c) 20015 SB Tech Services info@sbts.com.au
##
## Exclusively Licensed for use in the LedgerSMB Project
## Use in whole or part outside of the LedgerSMB Project is Not Permitted
##
############


############
# when this file is sourced it will automatically load the config file in $ConfigFile if it exists
# storing the results in the associative array $cfgValue[]
# to see what key names are available run dump_cfgValue_array() from your code.
############


# NOTE: envsubst allows variables in a stored string to be substituted.
#       eg:
#          _TOPIC="$(envsubst '$Version_Stable:$Version_Preview' <<<$TOPIC_template)"
#       The variables must have been exported.
#       The : seperated list if supplied limits what substitutions can occur

############
############
# Enable extended globbing. things like *(<Pattern>) to match zero or more instances of pattern.
# this is normally enabled anyway. but force it as we rely on it for correct processing.
shopt -s extglob;
############

############
# example use of whiptail
############
whiptail_available() {
    if [[ "`whiptail 2>&1`" =~ ^.*--msgbox ]]; then true; else false; fi
}

whiptail_example() {
    clear; 
    SECONDS=0; 
    while (( SECONDS < 10 )); do 
        echo $(( 10 * SECONDS )); 
    done | whiptail --title "Sample Fuel Gauge" --backtitle "" --gauge "fuel" 0 30 50 --topleft;
    whiptail --title title --backtitle "" --msgbox "some info" 0 30;
}

############
#  GetKey, GetKey2, and Test Key functions for handling user input
############
declare -a -r MenuKeys_1=({{0..9},{a..z}});
declare -a -r MenuKeys_2=({{0..9},{a..z}}{{0..9},{a..z}});
#i=0; time declare -A -r MenuKeys_1_Lookup=([{{0..9},{a..z}}]='"'$((i++))'"');
#i=0; time declare -A -r MenuKeys_2_Lookup=([{{0..9},{a..z}}{{0..9},{a..z}}]='"'$((i++))'"');
i=0; declare -A MenuKeys_1_Lookup; eval MenuKeys_1_Lookup[{{0..9},{a..z}}]="$((i++))";
i=0; declare -A MenuKeys_2_Lookup; eval MenuKeys_2_Lookup[{{0..9},{a..z}}{{0..9},{a..z}}]="$((i++))";

GetKey() {  # $1=valid key list    $2=Prompt    Result is stored in global $Key
            # key list requires a single key to be upper case, this is used as the default
            # User input is case insensitive
            # prompt can contain and "echo" escape sequences. eg: \n for newline

        # -l arg to declare or local means convert to lowercase on assignment.
    declare -g -l Key=9999;                             # default to invalid key
    local -l validkeys="${1:-yn}"                       # use a default key list of yn
    local prompt="${2:-Press y to continue.}"           # use a sensible default prompt
    local -l defaultKey=${1//[[:lower:]]/};             # Remove all lower case chars from $1 (validkeys)
    defaultKey=${defaultKey:-${validkeys:0:1}};         # Incase there are no Uppercase chars use first char as default
    defaultKey=${defaultKey:0:1};                       # Only use the first upper case char as default
#    defaultKey=${defaultKey,,};                         # change DefaultKey to lowercase
#    validkeys=${validkeys,,};                           # We are case insensitive for our matches so convert to lowercase

    printf "$prompt [${validkeys^^${defaultKey}}] ";    # Prompt with the default key as uppercase
    while ! [[ ${validkeys} =~ ${Key} ]]; do            # loop until we get a valid key or null
        read -sn1 Key;
        #Key=${Key,,}; # force new key to be lowercase
    done
    : ${Key:=${defaultKey}}; 
    printf "\n";
}

GetKey2() {  # $1=valid 1st key list    $2=valid 2nd key list    $3=Prompt    Result is stored in global $Key
            # key list requires a single key to be upper case, this is used as the default
            # User input is case insensitive
            # prompt can contain and "echo" escape sequences. eg: \n for newline

        # -l arg to declare or local means convert to lowercase on assignment.
    declare -g -l Key=9999;                             # default to invalid key
    declare -l Key2=9999;                             # default to invalid key
    local -l validkeys1="${1:-yn}"                       # use a default key list of yn
    local -l validkeys2="${2:-yn}"                       # use a default key list of yn
    local prompt="${3:-Press y to continue.}"           # use a sensible default prompt
    local -l defaultKey1=${1//[[:lower:]]/};             # Remove all lower case chars from $1 (validkeys)
    local -l defaultKey2=${2//[[:lower:]]/};             # Remove all lower case chars from $1 (validkeys)
    defaultKey=${defaultKey:-${validkeys1:0:1}};         # Incase there are no Uppercase chars use first char as default
    defaultKey=${defaultKey:0:1};                       # Only use the first upper case char as default
    defaultKey2=${defaultKey2:-${validkeys2:0:1}};         # Incase there are no Uppercase chars use first char as default
    defaultKey2=${defaultKey2:0:1};                       # Only use the first upper case char as default

    printf "$prompt [${validkeys1^^${defaultKey1}}][${validkeys2^^${defaultKey2}}] ";    # Prompt with the default key as uppercase
    while ! [[ ${validkeys1} =~ ${Key} ]]; do            # loop until we get a valid key or null
        read -sn1 Key;
    done
    while ! [[ ${validkeys2} =~ ${Key2} ]]; do            # loop until we get a valid key or null
        read -sn1 Key2;
    done
    : ${Key:=${defaultKey1}};
    : ${Key2:=${defaultKey2}};
    Key+=${Key2};
    printf "\n";
}

TestKey() {
    local Z=${1:-8888};
    [[ ${Key:-9999} == "${Z,,}" ]];
}



############
#  Misc functions
############

    SetTerminalTitle() {
        echo -en "\033]0;${1:-No Title Supplied}\a"
    }

    safe_source() { # $1 is filename to include
        libFile=` readlink -f $1`
        [[ -f $libFile ]] && { [[ -r $libFile ]] && source $libFile; } || {
            printf "\n\n\n";
            printf "=====================================================================\n";
            printf "=====================================================================\n";
            printf "====  Essential Library not readable:                            ====\n";
            printf "====        %-51s  ====\n" $libFile;
            printf "=====================================================================\n";
            printf "=====================================================================\n";
            printf "Exiting Now....\n\n\n";
            exit 1;
        }
    }

    REQUIRE_bin() { # space or arg separated list of executables that are required
                    # if $MSG is set, print it, then unset MSG
        local result=true;
        for i in $@; do
            echo -n "testing '$i' : "
            [[ -x `which $i` ]] && echo "OK" || { echo "FAIL"; result=false; }
        done
        $result || {
            echo "Can't run $0 because you are missing required executables."
            [[ -n MSG ]] && echo "$MSG" && unset MSG;
            unset Key;
            while ! TestKey "y"; do GetKey " y" "Please install then press Y to continue"; done
            echo "Exiting Now...."
            exit 1;
        }
    }

    SelectEditor() {
        [[ -z $Editor ]] && Editor=`which $EDITOR`
        [[ -z $Editor ]] && Editor=`which $VISUAL`
        [[ -z $Editor ]] && Editor=`which mcedit`
        [[ -z $Editor ]] && Editor=`which nano`
        [[ -z $Editor ]] && Editor=`which pico`
        [[ -z $Editor ]] && Editor=`which vi`
        [[ -z $Editor ]] && Editor=`which less`
        [[ -z $Editor ]] && Editor="$(which more); read -n -p'Press Enter to Continue';"
        [[ -z $Editor ]] && Editor="$(which cat); read -n -p'Press Enter to Continue';"
    }


############
#  Config File functions
############

    unset configFile;
    if [[ -n $ConfigFile ]]; then
        configFile=` readlink -f $ConfigFile`

        [[ -f $configFile ]] && [[ -r $configFile ]] || {
            printf "\n\n\n";
            printf "=====================================================================\n";
            printf "=====================================================================\n";
            printf "====  config file not readable: %-31s  ====\n" $configFile;
            printf "=====================================================================\n";
            printf "=====================================================================\n";
            printf "Exiting Now....\n\n\n"
        }
    fi

    _storeCFGinArray() { # this is a private callback function for loadConfig()
        declare -g -A cfgValue;
        declare -g Section;
        local Key;
        local Value;
        local Idx;
    
        # read the Idx, Key and Value from $@
        read -t0.5 Idx Key Value < <( echo "$@" )
        if [[ $Key =~ ^[[] ]]; then Section="${Key//[][]/}"; return; fi #Update the Section Name
        if [[ $Key =~ ^[[:space:]]*$ ]]; then return; fi #blank key, so skip this entry
        Key="${Section}_${Key}";
        #printf "|%2d| %-20s| %s\n" "$Idx" "$Key" "$Value";
        Value="${Value/*([\=\ ])/}"; # strip leading '=' and whitespace from Value
        cfgValue[$Key]="$Value";
    }

    loadConfig() {
        readarray -n500 -t -c1 -C _storeCFGinArray <$configFile;
    #    for L in "${cfgLines[@]}"; do echo "$((i++)): $L"; done
    }

    dump_cfgValue_array() {
        echo "+++++++++++++++++++++++++++++++++++"
        echo "++++        cfgValue[@]        ++++";
        echo "+++++++++++++++++++++++++++++++++++"
        for i in "${!cfgValue[@]}"; do printf "key: %-20s= %s\n" "$i" "${cfgValue[$i]}"; done | sort
        echo "+++++++++++++++++++++++++++++++++++"
    }

############
#  Test Config Functions. Use before running a routine that needs to know if it's config is valid
############
## An example of using TestConfig Functions
#    while true; do
#        TestConfigInit;
#        TestConfig4Key 'irc' 'Server'   'chat.freenode.net'
#        TestConfig4Key 'irc' 'User'     'YourNick'
#        TestConfig4Key 'irc' 'Password' 'Password'
#        TestConfig4Key 'irc' 'Channel'  'ledgersmb'
#        if TestConfigAsk "Notifications"; then break; fi
#    done

    TestConfigInit() {
        unset ConfigOK; declare -g ConfigOK=true;
    }
    TestConfig4Key() { # $1 = Section    $2 = Key    $3 = SampleValue
        local Key;
        declare -g Bl_1='====                                                                  ===='$'\r'
        declare -g Bl_2='====    *                                                         *   ===='$'\r'
        Key="${1}_${2}";
        if ( [[ ! -v cfgValue[$Key] ]] || [[ -z "${cfgValue[$Key]}" ]] ); then
            if $ConfigOK; then
                ConfigOK=false;
##		$bl====    *   $(printf "%-9s" "[$1]";)                                        *   ====
                cat <<-EOF
		==========================================================================
		==========================================================================
		${Bl_1}====  We cant run $(printf "%-40s" "$0";)
		${Bl_1}====  because there are missing config options!
		${Bl_1}
		${Bl_1}====    Add The following Keys to ~/.lsmb-release
		${Bl_2}====    ***********************************************************
		${Bl_2}
		${Bl_2}====    *   $(printf "%-9s" "[$1]";)
EOF
            fi
            local fWidth=50;
            if (( ${#2} > 19 )); then (( fWidth = 50 - ${#2} )); fi
            if (( ${#3} < fWidth )); then
                printf "$Bl_2====    *   %-19s = %s\n" "$2" "$3";
            else
                fWidth=160;
    #            (( fWidth = ${#Bl_1} - 25 ));
                (( fWidth > ( COLUMNS -20 ) )) && (( fWidth = COLUMNS - 20 ));
                local Txt=`fmt -u -w $fWidth -g $fWidth <<<$3`
                printf "$Bl_2\n";
                printf "${Bl_2}====    *   # Entry %s must all be on one line\n" "$2";
                printf "====    *   %-19s = \\\\\n" "$2";
                while read T; do
                        printf "====    *      %s\n" "$T";
                done <<<"$Txt"
                printf "$Bl_2\n";
            fi
        fi
        $ConfigOK;
        return
    }
    TestConfigAsk() { # $1=Prompt (actually only the part after "[A]bort"
        if $ConfigOK; then
            true; return ; # config is OK
        else
                cat <<-EOF
		${Bl_2}
		${Bl_1}====    ***********************************************************
		${Bl_1}
		==========================================================================
		==========================================================================
EOF
            #GetKey "Rsa" "\n[R]eload config;  [S]kip this step;  [A]bort : " "$@";
            GetKey "Ra" "\n[R]eload config;  [A]bort $@ : ";
            echo -e "\n"; # a copule of blank lines for visual pleasure
            #if TestKey "s"; then false; return; fi
            if TestKey "a"; then false; exit; fi # user abort
            if TestKey "r"; then loadConfig; fi
        fi
        false; ## return false. config not OK;
    }


############
# Readline History Functions
############
    EnableHistory() { # Requires $1 to be a history filename
        HISTFILE="$1"
        shopt -s histappend
        set -o history
    }

    AddHistory() { # requires $1 to be line to add to history
        history -s "$@"; # store in history array
        history -a; #history -n; # append to history file, then reread any new entries # the reread may not be required.
    }




############
# initialise the library
############
    REQUIRE_bin tput
    [[ -z $COLUMNS ]] && COLUMNS=`tput cols`;
    export COLUMNS;
    loadConfig;

############
# Some tests that you can run
############

#dump_cfgValue_array;
############
# initialise the library
############
# nothing to do here yet

############
# Some tests that you can run
############

#
