FROM        ylavoie/ledgersmb_circleci-primary
MAINTAINER  LedgerSMB  devel@lists.ledgersmb.org

USER root

RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update && \
    apt-get --no-install-recommends --yes install lighttpd && \
    apt-get -qqy autoremove && \
    apt-get -qqy autoclean && \
    rm -rf /var/lib/apt/lists/*

COPY lighttpd.sh /usr/local/bin
COPY lighttpd.conf /etc/lighttpd/lighttpd.conf

USER circleci

RUN mkdir -p ~/project/UI

EXPOSE 5000

STOPSIGNAL SIGTERM

USER www-data
CMD ["/usr/local/bin/lighttpd.sh"]