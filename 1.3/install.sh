#!/bin/sh

#./install.sh myLsmb13_test

CWD=`pwd`
APACHE_ALIAS='ledgersmb'

if  [ $# -eq 1 ]
then
 APACHE_ALIAS=$1
 echo "setting apache alias to $APACHE_ALIAS"
fi


echo "Installing Perl Modules"

cpan Module::Install

perl Makefile.PL

make

echo "Configuring Apache"

#sed "s|WORKING_DIR|$CWD|" ledgersmb-httpd.conf.template > ledgersmb-httpd.conf
sed  "s|/ledgersmb|/$APACHE_ALIAS|g;s|WORKING_DIR|$CWD|g" ledgersmb-httpd.conf.template > ledgersmb-httpd.conf

echo "Which user does your web server run as?"
read username

chown $username spool templates css

echo "Where do we copy the ledgersmb-httpd.conf file to?"
read location
cp ledgersmb-httpd.conf $location

echo "Please restart your web server for the changes to take effect."
