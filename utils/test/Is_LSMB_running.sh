#!/bin/bash

[[ -r utils/test/sysexits.shlib ]] && source utils/test/sysexits.shlib || {
    [[ -r sysexits.shlib ]] && source sysexits.shlib
}

if [[ -z $EX_NOHOST ]]; then
    echo '=================================='
    echo '=================================='
    echo "== sysexits.shlib wasn't loaded =="
    echo '=================================='
    echo '=================================='
    exit 99;
fi


# This script tests the plack/Starman application server.
# By default this is assumed to listen on http://localhost:5001,
# but can be overridden with the $PSGI_BASE_URL environment variable.
#
# Note that this may be different to the address used to serve users,
# which is often provided by a proxy and specified as $LSMB_BASE_URL.
psgi_base_url=${PSGI_BASE_URL:-http://localhost:5001}

# Extract the port to check Starman
url_without_port=${psgi_base_url%:[[:digit:]]*}
psgi_port=${psgi_base_url#$url_without_port}
psgi_port=${psgi_port#:}  # strip colon

# Default to port 5001
psgi_port=${psgi_port:-5001}


# You can add to either of these two variables to skip this test during travis setup.
# If it's skipped during this early run, it should also be run later in xt/60 which will never be skipped.
Repo_early_skip_list+=('https://github.com/ylavoie/LedgerSMB.git');
#Repo_early_skip_list+=('https://github.com/sbts/LedgerSMB.git');
Repo_owner_early_skip_list+=('ylavoie');
#Repo_owner_early_skip_list+=('sbts');

[[ -x `which git` ]] && Repo_URL=`git config --get remote.origin.url` || Repo_URL='unknown'
[[ "${Repo_URL,,}" == "unknown" ]] && {
    [[ -r .git/config ]] && {
        InSection=false;
        while read -srt5 A B C; do
            [[ "${A}${B}${C}" =~ .*[[].*[]] ]] && InSection=false;
            $InSection && {
                [[ "${A,,}" == 'url' ]] && Repo_URL="$C"
                break;
            }
            [[ "${A,,}${B,,}${C,,}" =~ remote.*origin ]] && InSection=true;
        done < .git/config
    }
}
Repo_Slug_Owner="${TRAVIS_REPO_SLUG%%/*}"; Repo_Slug_Owner="${Repo_Slug_Owner:-unknown}"

HELP() {
    E=${1:-$EX_USAGE}; shift;
    cat <<-EOF
	$@
	Script Is_LSMB_running.sh
	    Checks that Starman/Plack is running
	    and that the static html for setup.pl hasn't changed significantly.
	    Significant changes could indicate an error page instead of setup.pl
	
	USAGE:
	    utils/test/Is_LSMB_running.sh [--help]
	    utils/test/Is_LSMB_running.sh [--update] [MaxDiff]
	
	          --help : This Help message
	         --early : Slightly different handling of failures.
	                   Used on travis to prevent the entire test run from
	                   failing hard in the first pass for certain users
	        --update : update the reference file 't/data/Is_LSMB_running.html'
	         MaxDiff : Maximum number of lines the Current setup.pl
	                     and 't/data/Is_LSMB_running.html' may differ by
	                   Current thinking is this should always be 0
	                   Which holds true while the list of available
	                     db admin users is statically assigned.
	                   If the list of db admin users becomes dynamic a different
	                     arrangement will be needed.
	                     - see the NOTE in the src below HELP()

	ENVIRONMENT VARIABLES
	    PSGI_BASE_URL : Sets the base url used to check lsmb
	                    default: http://localhost:5001
	EOF
    exit $E;
}

##########
## NOTE:
##########
#  If the list of db admin users gets changed via manual config or becoming a dynamically set list
#  we need to process the list when generating the template and running the test to ensure it NEVER contains any dynamically assigned entries
#  Simply filtering out the entire select WILL NOT be enough as we need to ensure it doesn't contain unwanted entries as well.
##########

if [[ $1 == '--help' ]]; then HELP $EX_OK; shift; fi
if [[ $1 == '--update' ]]; then UPDATE=true; shift; else UPDATE=false; fi
if [[ $1 == '--early' ]]; then EARLY=true; shift; else EARLY=false; fi
if (( ${#@} >1 )); then shift; HELP $EX_USAGE "unknown argument $@"; fi # we should have zero or one arguments left at this point.
MaxDiff=${1:-0};    # maximum number of added or removed lines allowed in the setup.pl static html
if [[ $MaxDiff =~ "^[0-9]+$" ]]; then HELP $EX_USAGE "Final Argument 'MaxDiff' ($MaxDiff) must be a number $MaxDiff"; fi # MaxDiff Must be an integer

src='t/data/Is_LSMB_running.html'
current='/tmp/Is_LSMB_running.html'

printf -v LF "\n";

DUMPfile() {
    echo "== $1";
    if [[ -r "$1" ]]; then
        cat -v "$1";
    fi
    echo '=============================';
}

DIE() {
    E=$1; shift;
    T=$1; shift
    echo '=============================================';
    echo "$T";
    echo '=============================================';
    echo "$@";
    echo '=============================================';
    DUMPfile /tmp/Is_LSMB_running.log
    DUMPfile /tmp/Is_LSMB_running.html
    DUMPfile /tmp/plackup-error.log;
    DUMPfile /tmp/plackup-access.log;

    exit $E;
}

SkipEarly() {
    if $EARLY; then
        if [[ "${Repo_early_skip_list[@]}" =~ ${Repo_URL} ]]; then DIE 0 "Skipping Test Is_LSMB_running" "repo $Repo_URL is in the 'skip early' list"; fi
        if [[ "${Repo_owner_early_skip_list[@]}" =~ ${Repo_Slug_Owner} ]]; then DIE 0 "Skipping Test Is_LSMB_running" "Repo Owner $Repo_Slug_Owner is in the 'owner skip early' list"; fi
    fi
    echo "Commencing Early test for LSMB IS RUNNING"
}

[[ -e /tmp/Is_LSMB_running.log ]] && rm /tmp/Is_LSMB_running.log
[[ -e /tmp/Is_LSMB_running.html ]] && rm /tmp/Is_LSMB_running.html

WaitForPlackup() {
    local -i seconds=0;
    local processrunning=false;
    local httpdrunning=false;
    while (( i++ < 100 )); do # wait up to 10 seconds for plack or starman process to start
        pgrep -f 'plackup' >/dev/null && { processrunning=true; echo "plackup started after $i * 0.1 seconds"; break; }
        pgrep -f "starman.*$psgi_port" >/dev/null && { processrunning=true; echo "starman started after $i * 0.1 seconds"; break; }
        sleep 0.1;
    done
    if ! $processrunning; then
        echo "The starman/plack process didn't start before the timeout";
        return 1;
    fi
    i=0;
    while (( i++ < 100 )); do # wait up to 10 seconds for plack or starman server to respond to a curl
        pgrep -f 'plackup' >/dev/null
        curl --max-time 60 --connect-timeout 60 --fail --silent $psgi_base_url/setup.pl 2>&1 >/dev/null && {
            httpdrunning=true;
            echo "starman/plackup responded after $i * 0.1 seconds"; 
            break;
        } #|| echo -en "\r$i"
        sleep 0.1;
    done
    if ! $httpdrunning; then
        echo "The starman/plack httpd didn't respond before the timeout";
        return 1;
    fi
}

SkipEarly
WaitForPlackup || DIE $EX_NOHOST "ERROR: plackup or starman didn't start for some reason" "Check these logs for more info"


if curl --max-time 60 --connect-timeout 60 --progress-bar $psgi_base_url/setup.pl 2>/tmp/Is_LSMB_running.log >/tmp/Is_LSMB_running.html ; then
    echo "Starman/Plack is Running";
else    # fail early if starman is not running
    E=$?;
    DIE $E "ERROR: Starman/plack Not running";
fi

if $UPDATE; then
    echo 'Capturing new version of setup.pl'
    if grep -c '="js-src' >/dev/null /tmp/Is_LSMB_running.html; then
        DIE $EX_DATAERR "ERROR: ledgersmb.conf sets 'dojo_built = 0'" "change it to 'dojo_built = 1' and try again"; fi
    cp $current $src
fi

# fail if the static html generated by setup.pl has changed by more than $MaxDiff Lines
  # convert js-src to js so we don't care (for this test) if dojo is built or not
sed -i 's|="js-src/|="js/|' $current
DIFF=`diff -u0 $src $current`
CNTadd=`echo -e "$DIFF" | grep -c '^[+][^+].*$'`
CNTdel=`echo -e "$DIFF" | grep -c '^[-][^-].*$'`
if (( CNTadd > MaxDiff )); then DIE $EX_DATAERR "Added too many Lines ($CNTadd) to setup.pl.html${LF}Resolve any issues and run${LF}utils/test/Is_LSMB_running.sh --update" "$DIFF"; fi
if (( CNTdel > MaxDiff )); then DIE $EX_DATAERR "Removed too many Lines ($CNTdel) from setup.pl.html${LF}Resolve any issues and run${LF}utils/test/Is_LSMB_running.sh --update" "$DIFF"; fi

