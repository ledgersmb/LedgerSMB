#!/bin/bash

if test -z "$1"
then
  echo "Usage: $0 COMPANY"
  echo "\"COMPANY\" is the name of the company database, such as the name given"
  echo "to --company when using the prepare-company-database.sh script."
  exit 1
fi


for a in `sed -e 's/^\s*//' -e 's/\s*$//' -e 's/#.*$//' LOADORDER | grep -v '^$'`
do
      psql -f "$a" -U postgres $1
done

