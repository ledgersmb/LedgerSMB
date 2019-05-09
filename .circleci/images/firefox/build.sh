#!/bin/bash -x

DOCKER_BUILDKIT=1 docker build -t ylavoie/ledgersmb_circleci-firefox .
docker push ylavoie/ledgersmb_circleci-firefox
