#!/bin/bash

if curl localhost:5001/setup.pl >/tmp/Is_LSMB_running.log 2>&1; then
    echo "Starman/Plack is Running";
else    # fail early if starman is not running
    E=$?;
    echo '=============================';
    echo "  Starman/plack Not running";
    echo '=============================';
    cat /tmp/Is_LSMB_running.log
    echo '=============================';
    cat /tmp/plackup-error.log;
    echo '=============================';
    exit $E;
fi
