#!/bin/bash

for v in 9.5 9.6 10 11 ; do
  docker build -t ylavoie/ledgersmb_circleci-postgres:$v --build-arg version=$v .
  docker push ylavoie/ledgersmb_circleci-postgres:$v
done
