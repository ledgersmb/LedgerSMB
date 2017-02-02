#!/bin/bash

Log() {
    echo -e "$@" 1>&5
}

echo "Running $0 as $USER"

# Grab some ENV VARS
Log "USER: $USER"
Log "PERL5LIB: $PERL5LIB"
Log "$( perl -I$HOME/perl5/lib/perl5 -Mlocal::lib )"
