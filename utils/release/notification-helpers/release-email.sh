#!/bin/bash

ConfigFile=~/.lsmb-release

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

createEmail() {
    prj_url_dir='Releases'
    if [[ $release_type == preview ]]; then prj_url_dir='Beta%20Releases'; fi
    #HTML email is possible. Just add these lines after the subject:
    #Mime-Version: 1.0
    #Content-type: text/html; charset=”iso-8859-1″
    cat <<-EOF >/tmp/msg.txt
	To: $1
	From: ${cfgValue[mail_FromAddress]}
	Subject: LedgerSMB $release_version released

	The LedgerSMB development team is happy to announce yet another new
	version of its open source ERP and accounting application. This release
	contains the following fixes and improvements:

	$release_changelog

	The release can be downloaded from sourceforge at
	  https://sourceforge.net/projects/ledger-smb/files/$prj_url_dir/$release_version/

	These are the sha256 checksums of the uploaded files:
	$release_sha256sums

EOF
    $Editor /tmp/msg.txt
    GetKey "Yn" "Send email Now? "
    if TestKey "y"; then return `true`; else return `false`; fi
}

sendEmail() {
    Sender=${EMAIL};
    [[ -n $EMAIL ]] && scrape_config_files_for_Sender;

    MTA="${cfgValue[mail_MTAbinary]}";
    [[ -z $MTA ]] && MTA=`which ssmtp`;
    [[ -z $MTA ]] && MTA=`which sendmail`;
    [[ -x `which $MTA` ]] || { echo "Exiting: No Known MTA"; exit 1; }

    local defaultRecipient="${cfgValue[mail_FromAddress]}"

    if [[ $MTA =~ ssmtp ]] && [[ $MTA =~ '-t' ]]; then # ssmtp can't handle a commandline recipient if -t is used
        unset defaultRecipient;
    fi

    if createEmail "${cfgValue[mail_AnnounceList]}"; then
        $MTA $defaultRecipient < /tmp/msg.txt
    fi

    if createEmail "${cfgValue[mail_UsersList]}"; then
        $MTA $defaultRecipient < /tmp/msg.txt
    fi

    if createEmail "${cfgValue[mail_DevelList]}"; then
        $MTA $defaultRecipient < /tmp/msg.txt
    fi
}

RunAllUpdates() {
    sendEmail;
}


ValidateEnvironment() {
    ############
    #  Select an editor. (function is in bash-lib.sh
    ############
        SelectEditor;

    ############
    #  Test Config to make sure we have everything we need
    ############
        while true; do
            TestConfigInit;
            TestConfig4Key 'mail'   'AnnounceList'  'ledger-smb-announce@lists.sourceforge.net'
            TestConfig4Key 'mail'   'UsersList'     'ledger-smb-users@lists.sourceforge.net'
            TestConfig4Key 'mail'   'DevelList'     'ledger-smb-devel@lists.sourceforge.net'
            TestConfig4Key 'mail'   'FromAddress'   'release@ledgersmb.org'
            TestConfig4Key 'mail'   'MTAbinary'     'ssmtp'
            if TestConfigAsk "Send List Mail"; then break; fi
        done

    ############
    #  Test Environment to make sure we have everything we need
    ############
        local _envGOOD=true;
        [[ -z $release_version    ]] && { _envGOOD=false; echo "release_version is unavailable"; }
        [[ -z $release_date       ]] && { _envGOOD=false; echo "release_date is unavailable"; }
        [[ -z $release_type       ]] && { _envGOOD=false; echo "release_type is unavailable"; } # one of stable | preview
        [[ -z $release_branch     ]] && { _envGOOD=false; echo "release_branch is unavailable"; } # describes the ????
        [[ -z $release_changelog  ]] && { _envGOOD=false; echo "release_changelog is unavailable"; }
        [[ -z $release_sha256sums ]] && { _envGOOD=false; echo "release_sha256sums is unavailable"; }
        $_envGOOD || exit 1;
}


main() {
    clear;
        cat <<-EOF
	     ___________________________________________________________
	    /__________________________________________________________/|
	    |                                                         | |
	    |  Ready to                                               | |
	    |                                                         | |
	    |   *  Send Release Emails to                             | |
	    |           *  $(printf "%-43s" "${cfgValue[mail_AnnounceList]}";)| |
	    |           *  $(printf "%-43s" "${cfgValue[mail_UsersList]}";)| |
	    |           *  $(printf "%-43s" "${cfgValue[mail_DevelList]}";)| |
	    |                                                         | |
	    |                                                         | |
	    |_________________________________________________________|/


	EOF

    ValidateEnvironment;

    GetKey 'Yn' "Continue and send Emails";
    if TestKey "Y"; then sendEmail; fi

    echo
    echo
}


main;

exit;





