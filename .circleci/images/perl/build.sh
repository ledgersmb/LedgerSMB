#!/bin/bash -x

for v in 5.30 5.28 5.26 5.24 5.22 ; do
  docker build -t ylavoie/ledgersmb_circleci-perl:$v --build-arg perl=$v.0 .
  docker push ylavoie/ledgersmb_circleci-perl:$v
done
