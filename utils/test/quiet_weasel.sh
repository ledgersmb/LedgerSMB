#!/bin/bash -x

[ -f "$1" ] && sudo sed -i -r 's/^ +print STDERR .+$//g' "$1"

exit 0
