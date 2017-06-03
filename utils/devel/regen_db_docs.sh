#!/bin/bash

export PGHOST PGUSER PGPORT PGDATABASE PGPASSWORD;

Init() {
    #  PostgreSQL Autodoc - http://www.rbt.ca/autodoc/

    if [[ "${@}" =~ '--release' ]]; then
        PGUSER="${PGUSER:-$USER}";
        PGDATABASE="${PGDATABASE:-ledgersmb}";
        OutFile="ledgersmb"
        OutDir+='doc/database'
        Options=''; #'--statistics'
    else
        PGUSER="${PGUSER:-lsmb_dbadmin}";
        PGDATABASE="${PGDATABASE:-demo16}";
        OutFile="ledgersmb-$PGDATABASE"
        OutDir+='/tmp/LedgerSMB-doc/database'
        Options='--statistics'
    fi
    if [[ "${@}" =~ '--statistics' ]]; then # if the commandline wants statistics and we haven't already specified them, add to Options.
        if ! [[ Options =~ '--statistics' ]]; then Options+=' --statistics'; fi
    fi

    mkdir -p "$OutDir"
    cd "$OutDir"
}

GetPassword() {
    # This block checks if we can login to the db without a password, and if we can't asks the user for one
    # we may not need one due to settings in hb_pga.conf, an entry in ~/.pgpass, or the existance of $PGPASSWORD in the environment
    psql --no-password -U "$PGUSER" -d "$PGDATABASE" -l &>/dev/null  || {
        read -rs -p"Please enter Password for DB Administrator ${PGUSER}: " PGPASSWORD
        echo; # this is needed as read -s doesn't propogate the newline
    }
}

InstallExtensions() {
    if [[ "$Options" =~ 'statistics' ]]; then
        psql -U "$PGUSER" -d "$PGDATABASE" -c 'create extension IF NOT EXISTS pgstattuple'
    fi
}

GenerateDocs() {
    postgresql_autodoc -d "$PGDATABASE" -f "$OutFile" -u "$PGUSER" $Options
}

GenerateImages() {
    mkdir -p "$OutDir/images"

    echo "Generating  $OutFile.svg"
    dot -Tsvg "$OutFile.dot" -o "images/$OutFile.svg"
    echo "Adding link $OutFile.svg.html  => $OutFile.svg"
    ln -s "$OutFile.svg" "images/$OutFile.svg.html"

    echo "Generating  $OutFile.pdf"
    dot -Tpdf "$OutFile.dot" -o "images/$OutFile.pdf"

    echo "Generating  $OutFile.png"
    dot -Tpng "$OutFile.dot" -o "images/$OutFile.png"
}

main() {
    echo
    echo
    echo

    Init;
    GetPassword;
    InstallExtensions;
    GenerateDocs;
    GenerateImages;

    cat <<-EOF
	====================================
	== Resulting docs written to .... ==
	====================================
	== $OutDir/$OutFile
	====================================
	
	EOF
}

main

