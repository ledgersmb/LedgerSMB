#!/bin/sh

CWD=`pwd`

sed -e "s|WORKING_DIR|$CWD|" ledgersmb-httpd.conf.template > ledgersmb-httpd.conf

username="apache"
read -p "Which user does your web server run as? [$username]" REPLY

chown ${REPLY:-$username} spool templates css

location="/etc/httpd/conf.d"
read -p "Where do we copy the ledgersmb-httpd.conf file to? [$location] " REPLY

cp ledgersmb-httpd.conf ${REPLY:-$location}

echo "Please restart your web server for the changes to take effect."
