#!/bin/bash

# Simple script to prepare for release

if test -n "$1" # Arguments are presented.  set up argument list and related
then
   $pgdoc = "postgresql_autodoc -U $1 -d $2"
else
   $pgdoc = "true";
fi

version="1.2.0rc4";
build_d="../release";

if test -d blib; then
  rm -rf blib
fi

if test -d _build; then
  rm -rf _build
fi

if test -d $build_d/ledger-smb; then
  rm -rf $build_d/ledger-smb
fi
if test ! -d $build_d; then
  mkdir $build_d
fi
mkdir $build_d/ledger-smb
cp -R * $build_d/ledger-smb
cd $build_d/ledger-smb
pwd
find -name '*.svn' -exec rm -rf '{}' ';'
rm ledger-smb.conf
rm ledgersmb.conf
cd doc/database
$pg_doc
cd ../../..
tar -zcvf ledger-smb-$version.tar.gz ledger-smb
