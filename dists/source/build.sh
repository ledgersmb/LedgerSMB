#!/bin/bash

# Simple script to prepare for release

version="1.2.0rc2";
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
cd ..
tar -zcvf ledger-smb-$version.tar.gz ledger-smb
