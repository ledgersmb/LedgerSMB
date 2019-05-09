#!/bin/bash -x

docker build -t ylavoie/ledgersmb_circleci-lighttpd .
docker push ylavoie/ledgersmb_circleci-lighttpd
