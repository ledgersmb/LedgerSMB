#!/bin/bash -x

docker build -t ledgersmb/ledgersmb_circleci-lighttpd .
docker push ledgersmb/ledgersmb_circleci-lighttpd
