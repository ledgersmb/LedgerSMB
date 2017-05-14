#!/bin/bash

defaultURL='https://github.com/ledgersmb/LedgerSMB'
defaultFILE=''

HELP() {
    cat <<-EOF
	usage: github-badge-cache-buster.sh [ -h | --help | [ repoURL | "auto"   [ badgeFile ] ] ]
	
	       repoURL   defaults to '$defaultURL'
	       badgeFile defaults to '$defaultFILE'
	
	EOF
    exit 1;
}

[[ "$@" =~ --help|-h ]] && HELP;

paramURL="${1:-auto}"
paramFile="$2"

init() {
    [[ -x `which curl` ]] || {
        cat <<-EOF
		===============================
		===============================
		==        FATAL ERROR        ==
		===============================
		===============================
		== we need to be able to run ==
		== curl                      ==
		===============================
		== please install it         ==
		== then rerun this script    ==
		===============================
	EOF
        exit 9
    }

    # try reading a repo url from the current repo. otherwise default to ledgersm/LedgerSMB
    read -t30 autoURL < <( git config --get remote.origin.url ) || autoURL="$defaultURL"

    # if a URL was passed on the command line use it, otherwise use $autoURL
    [[ "${paramURL:-auto}" == "auto" ]] && unset paramURL;
    repoURL="${paramURL:-$autoURL}";

    # if a URL was passed on the command line use it, otherwise use $autoURL
    badge_mdFILE="${paramFile:-$defaultFILE}"

    COLUMNS=`tput cols`
    UserAgentString='KLUDGE (Linux;) (please fix github tickets 224 116 111 218 414 etc)'
}

GetBadgeURLs() {
    curl --silent --user-agent "$UserAgentString" --output /dev/stdout "${repoURL}${badge_mdFILE}" | grep -o 'https://camo.githubusercontent.com.*alt="[^"]*'
}

PurgeBadges() {
    rm -f results.txt
    while read -t5 URL Badge; do
        URL="${URL%\"*}";
        Badge="'${Badge#*\"}'                                        "
        echo -n "Purging Badge ${Badge:0:25}: ";
        read -t60 result < <( curl --silent --request 'PURGE' -H 'Content-Type:application/json' --user-agent "$UserAgentString" --output '/dev/stdout' $URL | jq .status )
        result="${result//\"/}"
        echo "${result:-???}"
    done
}

main() {
    init;
    cat <<-EOF
	
	============================================
	== about to purge cached badge images for ==
	============================================
	 ${repoURL}${badge_mdFILE}
	============================================
	
	EOF

    PurgeBadges < <( GetBadgeURLs )

    echo
}

main;