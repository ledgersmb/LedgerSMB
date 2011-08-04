#!/bin/sh

#This is a simple script which filters out the menu acl stuff from the Roles.sql
#file and thus makes it suitable to run on systems with custom menues.
#...
# Standard usage would be something like:
# sh tools/extract_role_grants.sh | sed -e 's/<?lsmb dbname ?>/[dbname]/' | psql#
# This will eventually be moved into Perl in the Database.pm

grep -iv "insert into" modules/Roles.sql | grep -iv values | less
