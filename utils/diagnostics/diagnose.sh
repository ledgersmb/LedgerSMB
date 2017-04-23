#!/bin/bash

scriptpath=`readlink -f "$0"`
clear;

export TimeStamp=`date "+%Y%m%d%H%M%S"`
export installdir="${scriptpath%/utils/diagnostics*}"
export testdir="$installdir/utils/diagnostics/t"
export libdir="$installdir/utils/lib"
export matrixdir="$installdir/utils/matrix"

# create a tempdir and lockfile
trap EXIT EXIT
export tempdir=`mktemp -dt lsmb-diag.XXXX`
echo $$ > $tempdir/.lock

declare -a tests
SystemName="${USER}_${HOSTNAME}"
TarBall="$tempdir/$SystemName-$TimeStamp.tgz"

cd "$installdir"

source "$libdir/bash-functions.sh"

shopt -s globstar

CleanTempDirs() {
    TD=`mktemp -dut lsmb-diag.XXXX`
    TD="${TD%.*}"
    #echo $TD
    for D in ${TD}*; do
        if ! [[ -f "$D/.lock" ]]; then
            #echo "Removing $D"
            rm -f "$D/"*
            rmdir "$D"
        fi
    done
}


EXIT() {
    rm $tempdir/.lock
}

CollectTests() {
    for t in utils/diagnostics/t/**; do
        if ! [[ -d $t ]]; then
            if [[ ${t: -2} == '.t' ]]; then
                echo $t is a test
                tests+=($t)
            fi
        fi
    done
    declare -gi numberoftests=${#tests[@]}
}

runtest() {
    T="${tests[$1]}"
    cat <<-EOF | tee "$tempdir/${T##*/}";
	
	
	====================================================
	====================================================
	== Running test $(( $1 + 1 )) of $numberoftests : ${T##*/}
	====================================================
	== $(date)
	====================================================
	EOF
    echo "$1 ${T##*/}";
    "$T" 5>>"$tempdir/${T##*/}";
}

RunAllTests() {
    echo
    echo
    i=0
    while (( i < ${#tests[@]} )); do
        clear
        runtest "$(( i++ ))"
    done

    echo
    echo
}

CreateTarBall() {
    tar -czf "$TarBall" --exclude='.lock' --directory "$tempdir/" .
#    tar -tvf /tmp/lsmb-diag.*/*.tgz
}

# =============================================
# == Support Functions for Test Scripts
# =============================================
Log() {
    echo -e "$@" 1>&5
}
export -f Log


# =============================================
# =============================================

CleanTempDirs
CollectTests
RunAllTests
CreateTarBall


#echo "installdir = \"$installdir\""
#echo "number of tests : $numberoftests"
#echo "    ${tests[@]}"
cat <<-EOF
	
	
	Results have been written to
	$tempdir
	
	
	
	
EOF
