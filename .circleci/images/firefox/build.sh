#!/bin/bash -x

DOCKER_BUILDKIT=1 docker build -t ledgersmb/ledgersmb_circleci-firefox .
docker push ledgersmb/ledgersmb_circleci-firefox
