#!/bin/bash

# Simple script to prepare for release

if test -n "$1" # Arguments are presented.  set up argument list and related
then
   pgdoc="postgresql_autodoc -U $1 -d $2"
else
   pgdoc="true";
fi

version="1.2.20";
#rpmversion="1.2.6";
build_d="../release";

if test -d blib; then
  rm -rf blib
fi

if test -d _build; then
  rm -rf _build
fi

if test -d $build_d/ledgersmb; then
  rm -rf $build_d/ledgersmb
fi
if test ! -d $build_d; then
  mkdir $build_d
fi
mkdir $build_d/ledgersmb
cp -R * $build_d/ledgersmb
cd $build_d/ledgersmb
pwd
find . -name '*.svn' -exec rm -rf '{}' ';'
find . -name '*.rej' -exec rm -rf '{}' ';'
rm ledger-smb.conf
rm ledgersmb.conf
cd doc/database
$pg_doc
cd ../../..
tar -zcvf ledgersmb-$version.tar.gz ledgersmb
cp ledgersmb-$version.tar.gz ledgersmb-$rpmversion.tar.gz
