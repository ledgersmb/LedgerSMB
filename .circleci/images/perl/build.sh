#!/bin/bash -x

for v in 5.28 5.30 5.26 5.24 5.22 ; do
  docker build -t ledgersmb/ledgersmb_circleci-perl:$v \
    --build-arg perl=$v.0 \
    --build-arg SHA=$(curl -s 'https://api.github.com/repos/ledgersmb/LedgerSMB/branches/master' | jq -r '.commit.sha') .
  docker push ledgersmb/ledgersmb_circleci-perl:$v
done
