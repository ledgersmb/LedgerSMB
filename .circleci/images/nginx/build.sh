#!/bin/bash -x

docker build -t ledgersmb/ledgersmb_circleci-nginx .
docker push ledgersmb/ledgersmb_circleci-nginx
