#!/bin/sh

# One must run the source file build first.

cp ../release/ledger-sm*.tar.gz /usr/src/redhat/SOURCES/

rpmbuild -ba dists/rpm/ledgersmb.spec

mv /usr/src/redhat/RPMS/noarch/ledgersmb* ../release
