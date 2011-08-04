#!/bin/bash

# Searches /usr/share/mime for freedesktop.xml files and builds a list of sql
# statements for populating the mime_types table.  People can occasionally 
# rename the table and rebuild it in order to check for new entries that need 
# to be added.

# This is a build tool, not suited for general administration of the software.
# --CT

find /usr/share/mime -name '*.xml' \
   | grep -v packages \
   | grep -v template \
   | grep -v 'inode'  \
   | sed -e "s#/usr/share/mime/\(.*\).xml#INSERT INTO mime_type (mime_type) VALUES(\'\1\')\;#"
