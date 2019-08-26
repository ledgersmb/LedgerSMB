#!/bin/bash -x

REPO=${CIRCLE_PROJECT_USERNAME:-$USER}

docker build -t $REPO/ledgersmb_circleci-primary .
docker push $REPO/ledgersmb_circleci-primary
