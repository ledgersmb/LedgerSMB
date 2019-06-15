#!/bin/bash -x

docker build -t ledgersmb/ledgersmb_circleci-chrome .
docker push ledgersmb/ledgersmb_circleci-chrome
