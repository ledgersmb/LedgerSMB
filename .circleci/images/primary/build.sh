#!/bin/bash -x

docker build -t ylavoie/ledgersmb_circleci-primary .
docker push ylavoie/ledgersmb_circleci-primary
