#!/bin/bash

# Simple script to prepare for release

version="1.2.0b1";
build_d="../release";

if test -d $build_d/ledger-smb; then
  rm -rf $build_d/ledger-smb
fi
if test ! -d $build_d; then
  mkdir $build_d
fi
cp ledger-smb $build_d
cd $build_d/ledger-smb
find -name '*.svn' -exec rm -rf '{}' ';'
rm ledger-smb.conf
cd ..
tar -zxvf ledger-smb-$version.tar.gz ledger-smb
