#!/bin/bash -x

docker build -t ylavoie/ledgersmb_circleci-nginx .
docker push ylavoie/ledgersmb_circleci-nginx
