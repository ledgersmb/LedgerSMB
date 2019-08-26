#!/bin/bash -x

REPO=${CIRCLE_PROJECT_USERNAME:-$USER}

for v in 9.5 9.6 10 11 ; do
  docker build -t $REPO/ledgersmb_circleci-postgres:$v --build-arg version=$v .
  docker push $REPO/ledgersmb_circleci-postgres:$v
done
