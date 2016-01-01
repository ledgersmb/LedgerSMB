#!/bin/bash

HELP() {
    cat <<-EOF
	usage:
	    $0 -h
	    $0 [-v] filename.pot
	-h  : show this help
	-v  : Verbose. Print word count and string for EVERY string
EOF
    exit 1;
}

if [[ $1 == '-h' ]]; then HELP; fi

if [[ $1 == '-v' ]]; then
    Verbose=true;
    shift;
else
    Verbose=false;
fi

if [[ -z $1 ]]; then HELP; fi

F="$1"

i=0;

{
    printf "Scanning $F for information\nThis may take a while\n"
    while read L; do
        L="${L/\%[0-9]/}"; # strip any %? field references so they don't skew the count
        L="${L/\[*]/}";    # strip any [_?] field references so they don't skew the count
        Wc=`wc -w <<<"$L"`;
        aWc[$(( i++ ))]=$Wc;
        if $Verbose; then printf "%2d: '%s'\n" $Wc "$L";
        else
            printf '.'
        fi
        case $Wc in
            1 ) (( One++ ));;
            2 ) (( Two++ ));;
            3 ) (( Three++ ));;
            4 ) (( Four++ ));;
            * ) (( Other++ ));;
        esac
        if (( Wc > Max )); then (( Max = Wc )); fi
    done
    printf '\n'
} < <(awk '/msgid/ {sub($1 FS,"" );print}' LedgerSMB.pot | sort -u; )

(( Count = i ));
while (( i-- >0 )); do
    (( Sum += ${aWc[$i]} ));
done

# print the repository status
echo -e "\n\n"
git show

# print a .pot summary
(( Avg = Sum / Count ));
printf "\n\n"
printf "Strings %d\n" $Count
printf "  Words %d\n" $Sum
echo -e '-----------------------------'
printf "Average Word Count %d\n" $Avg
printf "Longest String is %d words\n" $Max
echo -e '-----------------------------'
printf " # words  | count\n"
echo -e '----------+------------------'
printf "   One    | %4d\n" $One
printf "   Two    | %4d\n" $Two
printf "  Three   | %4d\n" $Three
printf "   Four   | %4d\n" $Four
printf "  Other   | %4d\n" $Other
echo -e '-----------------------------'
echo
echo

