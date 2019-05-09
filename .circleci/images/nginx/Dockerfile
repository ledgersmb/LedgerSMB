FROM        ylavoie/ledgersmb_circleci-primary
MAINTAINER  LedgerSMB  devel@lists.ledgersmb.org

USER root

RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update && \
    apt-get --no-install-recommends --yes install nginx && \
    apt-get -qqy autoremove && \
    apt-get -qqy autoclean && \
    rm -rf /var/lib/apt/lists/*

COPY nginx.conf /etc/nginx/nginx.conf
COPY nginx.sh /usr/local/bin

USER circleci

RUN mkdir -p ~/project/UI

EXPOSE 5000

STOPSIGNAL SIGTERM

CMD ["/usr/local/bin/nginx.sh"]