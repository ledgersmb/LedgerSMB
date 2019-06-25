#!/bin/bash -x

docker build -t ledgersmb/ledgersmb_circleci-phantomjs .
docker push ledgersmb/ledgersmb_circleci-phantomjs
