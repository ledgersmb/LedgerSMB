#!/bin/bash

# import some functions that we need, like reading values from our config file.
ConfigFile=~/.lsmb-release

############
#  Set internal variables so $1 and $2 are effectively available inside functions
############
export release_type="${1:-${release_type:-unknown}}"
export release_version="${2:-${release_version:-unknown}}"

############
#  Check our arguments are sane
############
    if ! [[ ${release_type} == 'stable' ]]; then
        printf "\n\n\n";
        printf "=====================================================================\n";
        printf "=====================================================================\n";
        printf "====  \$1 = %-10s                                            ====\n" "$1";
        printf "====      We can only make changes to the default link           ====\n";
        printf "====      when \$1 = stable                                       ====\n";
        printf "=====================================================================\n";
        printf "=====================================================================\n";
        printf "Exiting Now....\n\n\n";
        exit 1;
    fi
    if [[ -z $release_version ]]; then
        printf "\n\n\n";
        printf "=====================================================================\n";
        printf "=====================================================================\n";
        printf "====  Essential Argument not available:                          ====\n";
        printf "====      One of the following must be set                       ====\n";
        printf "====          \$release_version = %-10s                      ====\n" "$release_version";
        printf "====                        \$2 = %-10s                      ====\n" "$2";
        printf "=====================================================================\n";
        printf "=====================================================================\n";
        printf "Exiting Now....\n\n\n";
        exit 1;
    fi

libFile=` readlink -f ./bash-functions.sh`
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

# set DEBUG=true to get dump of returned JSON for each command
DEBUG=${cfgValue[sourceforge_Debug]};
: ${DEBUG:+true};
: ${DEBUG:=false};

############
#  Test Config to make sure we have everything we need
############
HowToGetAPIkey() {
    cat <<-EOF
	Here is how to get your API key:
	
	    Go to your account page by....
	      * login
	      * click on down arrow next to "me" top right of page
	      * click on account settings
	      * at the bottom of the preferences tab
	    Click on the "Generate" button under the Releases API Key.
	    Copy and paste the key that appears into 
	        $ConfigFile
	            [sourceforge]
	            ApiKey    = YourKey
	
EOF
}

    while true; do
        # test for the apikey first so we can display help on getting it.
        if ( [[ ! -v cfgValue[sourceforge_ApiKey] ]] || [[ -z "${cfgValue[sourceforge_ApiKey]}" ]] ); then HowToGetAPIkey; fi #return; fi
        TestConfigInit;
        TestConfig4Key 'sourceforge' 'Project'             'ledgersmb'
        TestConfig4Key 'sourceforge' 'ReadlineHistory'     '/tmp/sourceforge.history'
        TestConfig4Key 'sourceforge' 'ApiKey'              'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
        TestConfig4Key 'sourceforge' 'DefaultFileTemplate' 'Releases/${release_version}/ledgersmb-${release_version}.tar.gz'
        TestConfig4Key 'sourceforge' 'download_label'      'Download Latest ($release_version)'
        TestConfig4Key 'sourceforge' 'OS_List'             'windows mac linux bsd solaris others'
        if TestConfigAsk "Sourceforge Default Link Update"; then break; fi
    done


getCurrentProjectInfo() { # Stores result in Project_JSON   stores release.filename in Project_Filename    stores release.sf_platform_default in Project_OS_list
    # {"release": null, "platform_releases": {"windows": null, "mac": null, "linux": null}}
    local _URL="http://sourceforge.net/projects/${cfgValue[sourceforge_Project]}/best_release.json"
    declare -g Project_JSON=''
    declare -g Project_Filename=''
    printf "===================================================\n"
    printf "===================================================\n"
    printf "====   Retrieving Default Link for Project     ====\n"
    printf "====     %-35s   ====\n" "${cfgValue[sourceforge_Project]}"
    printf "===================================================\n"
    printf "===================================================\n\n"
    Project_JSON=`curl -s -X GET "$_URL"`
    ${DEBUG:-false} && {
        echo "\n==================================================="
        echo "==================================================="
        echo "==== Debug Output from getCurrentProjectInfo() ===="
        echo "==================================================="
        echo "==================================================="
        jq . <<< "$Project_JSON"
        echo
    }

    Project_Filename=`jq -c .release.filename <<< "$Project_JSON"`
    Project_OS_list=`jq -c .release.sf_platform_default <<< "$Project_JSON"`
    printf "filename ='%s'\n" "$Project_Filename"
    printf "OS list  ='%s'\n" "$Project_OS_list"
    echo
}


#### "${cfgValue[_]}"
updateSourceforge() { # $1 = New Version     $2 = New Date
    #https://sourceforge.net/p/forge/community-docs/Using%20the%20Release%20API/
    #https://sourceforge.net/p/forge/documentation/Allura%20API/

    local _DefaultFile="$(envsubst '$release_version' <<<${cfgValue[sourceforge_DefaultFileTemplate]})"
    local _OS_List='';
    local _Download_Label="sf_download_label=\"$(envsubst '$release_version' <<<${cfgValue[sourceforge_download_label]})\""
    declare -g Request_JSON=''
    declare -g Request_Filename=''
    declare -g Request_OS_list=''

    for i in ${cfgValue[sourceforge_OS_List]}; do
        _OS_List="${_OS_List:+${_OS_List}&}default=${i}";
    done

#echo done; return
    printf "===================================================\n"
    printf "===================================================\n"
    printf "====   Updating Sourceforge Default link       ====\n"
    printf "====   for project %-25s   ====\n" "${cfgValue[sourceforge_Project]}"
    printf "===================================================\n"
    printf "===================================================\n\n"
    Request_JSON=`curl -s -H "Accept: application/json" -X PUT \
        -d "$_OS_List" \
        -d "$_Download_Label" \
        -d "api_key=${cfgValue[sourceforge_ApiKey]}" \
        "https://sourceforge.net/projects/${cfgValue[sourceforge_Project]}/files/$_DefaultFile"`
    ${DEBUG:-false} && {
        echo "==================================================="
        echo "==================================================="
        echo "====   Debug Output from updateSourceforge()   ===="
        echo "==================================================="
        echo "==================================================="
        jq . <<< "$Request_JSON"
        echo "---------------------------------------------------"
        echo "Download_Label      : $_Download_Label"
        echo "OS_List             : $_OS_List"
        echo "api_key             : ${cfgValue[sourceforge_ApiKey]}"
        echo "DefaultFileTemplate : ${cfgValue[sourceforge_DefaultFileTemplate]}"
        echo "URL                 : https://sourceforge.net/projects/${cfgValue[sourceforge_Project]}/files/$_DefaultFile"
        echo "---------------------------------------------------"
        echo
    }
    Request_Filename=`jq -c .result.name <<< "$Request_JSON"`
    Request_OS_list=`jq -c .result.x_sf.default <<< "$Request_JSON"`
    printf "filename ='%s'\n" "$Request_Filename"
    printf "OS list  ='%s'\n" "$Request_OS_list"
    echo
}



RunAllUpdates() {
    getCurrentProjectInfo;
    updateSourceforge "$release_version";
}

ValidateEnvironment() {
    ############
    #  Require some binaries
    ############
        # envsubst lets us safely substitute envvars into strings that would other wise need eval running on them. it is part of gettext-base
        MSG="install with\n\tapt-get install gettext-base" REQUIRE_bin "envsubst"
        # jq is used to assist with Jason parsing. we could do away with it if it becomes a burdon
        MSG="install with\n\tapt-get install jq" REQUIRE_bin "jq"

    ############
    #  Test Config to make sure we have everything we need
    ############
        while true; do
            TestConfigInit;
            TestConfig4Key 'sourceforge' 'ApiKey'   'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
            if ! [[ "${cfgValue[sourceforge_ApiKey]}" =~ ^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$ ]]; then
                printf "%% your ApiKey looks like it could be invalid %%\n"
                printf "%%     xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx   %%\n"
                printf "%%     %36s   %%\n" "${cfgValue[sourceforge_ApiKey]}"
                GetKey " " "Press any key to continue"
            fi
            TestConfig4Key 'sourceforge' 'Project'  'ledger-smb'
            TestConfig4Key 'sourceforge' 'Debug'  '[true | false]'
            if TestConfigAsk "Sourceforge Default Download Update"; then break; fi
        done

    ############
    #  Test Environment to make sure we have everything we need
    ############
        local _envGOOD=true;
        [[ -z $release_version ]] && { _envGOOD=false; echo "release_version is unavailable"; }
#        [[ -z $release_date    ]] && { _envGOOD=false; echo "release_date is unavailable"; }
        [[ -z $release_type    ]] && { _envGOOD=false; echo "release_type is unavailable"; } # one of stable | preview
#        [[ -z $release_branch  ]] && { _envGOOD=false; echo "release_branch is unavailable"; } # describes the ????
        $_envGOOD || exit 1;
}


main() {
    clear;
        cat <<-EOF
	     _________________________________________________
	    /________________________________________________/|
	    |                                               | |
	    |  Ready update the Sourceforge default link    | |
	    |      for project                              | |
	    |           *  $(printf "%-33s" "${cfgValue[sourceforge_Project]}";)| |
	    |                                               | |
	    |  DEBUG=$DEBUG                                   | |
	    |_______________________________________________|/


	EOF

    GetKey 'Yn' "Continue and Update Sourceforge Default Link?";
    if TestKey "Y"; then RunAllUpdates $Version $Date; fi

    echo
    echo
}

main;

exit;
