#!/bin/sh

# One must run the source file build first.

cp ../release/ledgersm*.tar.gz /root/rpmbuild/SOURCES/

rpmbuild -ba dists/rpm/ledgersmb.spec

mv /root/rpmbuild/SOURCES/ledgersmb* ../release
