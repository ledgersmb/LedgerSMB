ARG version=10

FROM        postgres:$version
MAINTAINER  LedgerSMB  devel@lists.ledgersmb.org

# FROM resets ARG, so redeclare
ARG version

RUN DEBIAN_FRONTEND="noninteractive" apt-get -qqy update && \
    apt-get -qqy install postgresql-$version-pgtap && \
    apt-get -qqy autoremove && \
    apt-get -qqy autoclean && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /docker-entrypoint-initdb.d

COPY lsmb-dev-init.sh /docker-entrypoint-initdb.d/lsmb-dev-init.sh

USER postgres
