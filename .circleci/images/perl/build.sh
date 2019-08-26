#!/bin/bash -x

REPO=${CIRCLE_PROJECT_USERNAME:-$USER}

for v in 5.30 5.28 5.26 5.24 5.22 ; do
  docker build -t $REPO/ledgersmb_circleci-perl:$v \
    --build-arg perl=$v.0 \
    --build-arg REPOSITORY=$REPO \
    --build-arg SHA=$(curl -s 'https://api.github.com/repos/ledgersmb/LedgerSMB/branches/master' | jq -r '.commit.sha') .
  docker push $REPO/ledgersmb_circleci-perl:$v
done
