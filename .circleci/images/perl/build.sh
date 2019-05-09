#!/bin/bash -x

for v in 5.28 5.26 5.24 5.22 5.20 5.18 ; do
  docker build -t ylavoie/ledgersmb_circleci-perl:$v --build-arg perl=$v.0 .
  docker push ylavoie/ledgersmb_circleci-perl:$v
done
