#!/bin/bash -x

docker build -t ylavoie/ledgersmb_circleci-chrome .
docker push ylavoie/ledgersmb_circleci-chrome
