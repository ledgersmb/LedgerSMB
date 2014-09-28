#!/bin/sh

# One must run the source file build first.

VERSION="1.5.0"
hg archive -ttgz ~/ledgersmb.tar.gz

# Remove Dojo

gunzip  ~/ledgersmb.tar.gz
tar -f ~/ledgersmb.tar --delete ledgersmb/UI/lib/dojo -v

gzip ~/ledgersmb.tar;

mv ~/ledgersmb.tar.gz ~/rpmbuild/SOURCES/ledgersmb-$VERSION.tar.gz;

rpmbuild -ba --sign  \
               --define "_source_filedigest_algorithm 0" \
               --define "_binary_filedigest_algorithm 0" \
               dists/rpm/ledgersmb.spec

mv /root/rpmbuild/SOURCES/ledgersmb* ../release

mv /root/rpmbuild/SRPMS/ledgersmb* ../release

mv /root/rpmbuild/RPMS/noarch/ledgersmb* ../release

