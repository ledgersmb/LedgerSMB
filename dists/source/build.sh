#!/bin/bash

# Simple script to prepare for release

version="1.2.0b1";

cp ledger-smb ../releases/
cd ../releases/ledger-smb
find -name '*.svn' -exec rm -rf '{}' ';'
rm ledger-smb.conf
cd ..
tar -zxvf ledger-smb-$version.tar.gz ledger-smb
