#!/bin/sh

# One must run the source file build first.

cp ../release/ledgersm*.tar.gz /root/rpmbuild/SOURCES/

rpmbuild -ba --sign  \
               --define "_source_filedigest_algorithm 0" \
               --define "_binary_filedigest_algorithm 0" \
               dists/rpm/ledgersmb.spec

mv /root/rpmbuild/SOURCES/ledgersmb* ../release

mv /root/rpmbuild/SRPMS/ledgersmb* ../release

mv /root/rpmbuild/RPMS/noarch/ledgersmb* ../release

