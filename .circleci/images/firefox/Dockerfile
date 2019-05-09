ARG PROTOCOL=json
FROM ylavoie/ledgersmb_circleci-primary AS primary
MAINTAINER  LedgerSMB  devel@lists.ledgersmb.org
# We build here the 2 firefox versions
# Select either json or webdriver

# Great idea from https://medium.com/@tonistiigi/advanced-multi-stage-build-patterns-6f741b852fae

# Build the JSON version =======================================================
FROM selenium/standalone-firefox as firefox-json
ENV SE_OPTS -port 4422

# Build Headless version (Webdriver) ===========================================
FROM primary as firefox-webdriver
USER root
ENV FIREFOX 66.0
ENV GECKODRIVER v0.24.0

RUN echo "deb http://http.debian.net/debian unstable main" > /etc/apt/sources.list.d/firefox.list && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get update && \
    apt-get --no-install-recommends --yes install firefox=$FIREFOX\* && \
    apt-get -qqy autoremove && \
    apt-get -qqy autoclean && \
    rm -rf /var/lib/apt/lists/*

COPY profile/ profile/

# Install the latest version of Geckodriver:
RUN BASE_URL=https://github.com/mozilla/geckodriver/releases/download \
  && curl -sL $BASE_URL/$GECKODRIVER/geckodriver-$GECKODRIVER-linux64.tar.gz | \
    tar -xz -C /usr/local/bin

CMD ["geckodriver", "--host", "0.0.0.0", "--port", "4422", "--marionette-port", "2828", "--log", "trace"]

# Use the proper branch ========================================================
FROM firefox-${PROTOCOL} AS firefox
EXPOSE 4422
