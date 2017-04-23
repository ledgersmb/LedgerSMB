#!/bin/bash

if ! declare -F Log >/dev/null; then # declare a local copy of the Log() function that only prints to screen
    function Log() {
        echo -e "$@"
    }
fi

echo "Running $0 as $USER"

# Grab some ENV VARS
Log "USER: $USER"
Log "PERL5LIB: $PERL5LIB"
Log "$( perl -I$HOME/perl5/lib/perl5 -Mlocal::lib )"
