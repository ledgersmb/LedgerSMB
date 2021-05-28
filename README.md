
# LedgerSMB

Small and Medium business accounting and ERP


[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/795/badge)](https://bestpractices.coreinfrastructure.org/projects/795)
[![LedgerSMB](https://circleci.com/gh/ledgersmb/LedgerSMB/tree/master.svg?style=svg)](https://circleci.com/gh/ledgersmb/LedgerSMB/tree/master)
[![Lgtm total alerts](https://img.shields.io/lgtm/alerts/g/ledgersmb/LedgerSMB.svg?logo=lgtm&logoWidth=18)](https://lgtm.com/projects/g/ledgersmb/LedgerSMB/alerts/)
[![GPLv2 Licence](https://badges.frapsoft.com/os/gpl/gpl.png?v=103)](https://opensource.org/licenses/GPL-2.0/)
[![Coverage Status](https://coveralls.io/repos/github/ledgersmb/LedgerSMB/badge.svg?branch=master)](https://coveralls.io/github/ledgersmb/LedgerSMB?branch=master)
[![Docker](https://img.shields.io/docker/pulls/ledgersmb/ledgersmb.svg)](https://hub.docker.com/r/ledgersmb/ledgersmb/)
[![Language grade: JavaScript](https://img.shields.io/lgtm/grade/javascript/g/ledgersmb/LedgerSMB.svg?logo=lgtm&logoWidth=18)](https://lgtm.com/projects/g/ledgersmb/LedgerSMB/context:javascript)
[![Mentioned in Awesome <awesome-selfhosted>](https://awesome.re/mentioned-badge.svg)](https://github.com/Kickball/awesome-selfhosted#enterprise-resource-planning)



# SYNOPSIS

LedgerSMB is a free integrated web application accounting system, featuring
double entry accounting, budgeting, invoicing, quotations, projects, timecards,
inventory management, shipping and more ...

The UI allows world-wide accessibility; with its data stored in the
enterprise-strength `PostgreSQL` open source database system, the system is known
to operate smoothly for businesses with thousands of transactions per week.
Screens and customer visible output are defined in templates, allowing easy and
fast customization. Supported output formats are PDF, CSV, HTML, ODF and more.

Directly send orders and invoices from the built-in e-mail function to your
customers or RFQs (request for quotation) to your vendors with PDF attachments.


# System requirements

Note that these are the system requirements for LedgerSMB 1.9.0-dev, the current
development version. Please check the system requirements for [the 1.7 old stable
version](https://github.com/ledgersmb/LedgerSMB/tree/1.7#system-requirements)
and [the 1.8 version](https://github.com/ledgersmb/LedgerSMB/tree/1.8#system-requirements).

## Server

* `Perl 5.24+`
* `PostgreSQL 9.6+`
* Web server (e.g. `nginx`, `Apache`, `lighttpd`, `Varnish`)

The web external server is only required for production installs;
for evaluation purposes a simpler setup can be used, as detailed
below.

## Client

A `Dojo` compatible web browser is all that's required on the client;
it includes the recent versions of `Chrome`, `FireFox`, `Opera`,
`MS Internet Explorer` and a wide range of mobile browsers.
Please note that LedgerSMB
explicitly doesn't make any attempts to support Internet Explorer.

The tables below show the browsers currently supported, their earliest date
and a range of versions.


### Desktop

| Browser Name        | Earliest | Versions                                    |
| ------------------- |:--------:|:------------------------------------------- |
| Chrome              | 2017-09  | 61-81, 83-93                                |
| Edge                | 2017-10  | 16-18, 79-81, 83-90                         |
| Firefox             | 2018-05  | 60-90                                       |
| Opera               | 2017-09  | 48-58, 60, 62-75                            |
| Safari              | 2017-03  | 10.1, 11, 11.1, 12, 12.1, 13, 13.1, 14,     |
|                     |          | 14.1, TP                                    |

### Mobile

| Browser Name        | Earliest | Versions                                    |
| ------------------- |:--------:|:------------------------------------------- |
| Chrome for Android  | 2021-04  | 90                                          |
| Firefox for Android | 2021-03  | 87                                          |
| Android Browser     | 2021-04  | 90                                          |
| Safari on iOS       | 2017-03  | 10.3, 11.0-11.4, 12.0-12.4, 13.0-13.7,      |
|                     |          | 14.0-14.5                                   |
| Samsung Internet    | 2018-12  | 8.2, 9.2, 10.1, 11.1-11.2, 12.0, 13.0,      |
|                     |          | 14.0                                        |

**Note: Earliest dates and versions come from http://caniuse.com. Only the most
recent data is available for Mobile browsers other than Safari, because they
are pushed out to the devices as soon as they are releases, so the amount of
old browsers is negligible. **
# Quick start (`Docker compose`)

The quickest way to get the `Docker` image up and running is by using the
docker-compose file available through the `GitHub` repository at:

https://github.com/ledgersmb/ledgersmb-docker/blob/1.8/docker-compose.yml

which sets up both the LedgerSMB image and a supporting database image for
production purposes (i.e. with persistent (database) data, with the
exception of one thing: setting up an `Nginx` or `Apache` reverse proxy
with TLS 1.2 support -- a requirement if you want to access your
installation over any type of network.

See the [documentation on Docker Hub](https://hub.docker.com/r/ledgersmb/ledgersmb/).

# Quick start (from tarball)

The instructions below are for getting started quickly; the [project's site](https://ledgersmb.org)
provides [in-depth installation
instructions](https://ledgersmb.org/content/installing-ledgersmb-18)
for **production** installs.

## System (library) dependencies

The following non-Perl (system) dependencies need to be in place for the
`cpanm` command mentioned below to work, in addition to what's documented
on the [How to install CPAN modules](http://www.cpan.org/modules/INSTALL.html)
page on CPAN.

* `cpanminus`  This can be manually installed, or installed as a system package.
  It may not be necessary to install `cpanminus` if you are only going to install
  from debian packages.
* `PostgreSQL` client libraries
* `PostgreSQL` server
* `DBD::Pg 3.4.2+` (so `cpanm` recognizes that it won't need to compile it)
  This package is called `libdbd-pg-perl` in `Debian` and `perl-DBD-Pg`
  in `RedHat/Fedora`
* `make`       This is used by `cpan` dependencies during their build process

Then, some of the features listed below have system requirements as well:

* `latex-pdf-ps` depends on these binaries or libraries:
  * `latex` (usually provided through a `texlive` package)
  * `pdflatex`
  * `dvipdfm`
  * `dvips`
  * `pdf2ps`

## Perl module dependencies

This section depends on [a working local::lib installation](https://ledgersmb.org/content/setting-perls-locallib-ledgersmb-why-and-how)
as well as an installed `cpanm` executable. Both should be available from
your distribution's package repository (Debian calls them `liblocal-lib-perl`
and `cpanminus` respectively). `cpanm` depends on the `make` and `gcc` commands
being available.

NOTE: `gcc` can be removed after all `cpan` dependencies are installed.
      However, it may be necessary to reinstall it if additional modules are
      required during an upgrade

To install the `Perl` module dependencies, run:

```sh
cpanm --quiet --notest --with-feature=starman [other features] --installdeps .
```

**NOTES**


1. Don't miss the "." at the end of the `cpanm` command!
2. The environment variables `PERL5LIB`, `PERL_MB_OPT` and `PERL_MM_OPT`
   need to be set and that `PATH` needs to include the local::lib location.
3. `[other features]` are described in the [in-depth installation
   instructions](https://ledgersmb.org/content/installing-ledgersmb-18)
4. The [in-depth installation
   instructions](https://ledgersmb.org/topic/installing-ledgersmb-18)
   contain a list of distribution provided packages to reduce the
   number of dependencies installed from CPAN.


## `PostgreSQL` configuration

While it's possible to use LedgerSMB with the standard `postgres` user,
it's good practice to create a separate 'LedgerSMB database administrator'.
In this quickstart, we add a password to the `postgres` superuser:


```plain
$ sudo -u postgres psql -U postgres \
   -c "alter role postgres password 'CHANGE-ME' valid until 'tomorrow'"
```

**NOTES**

1. The password is only valid until the end of the day it's assigned
   then you can't forget to remove the password leaving a security hole


## Configure LedgerSMB

LedgerSMB should be able to run without configuration. If you need specific
settings, please

```sh
cp doc/conf/ledgersmb.conf.default ledgersmb.conf
```

and edit `ledgersmb.conf` to match your requirements.

## Running Starman

With the above steps completed, the system is ready to run the web server:

```bash
 $ starman --preload-app -I lib -I old/lib --listen localhost:5762 \
      bin/ledgersmb-server.psgi
2020/05/12-02:14:57 Starman::Server (type Net::Server::PreFork) starting! pid(xxxx)
Resolved [*]:5762 to [::]:5762, IPv6
Not including resolved host [0.0.0.0] IPv4 because it will be handled by [::] IPv6
Binding to TCP port 5762 on host :: with IPv6
Setting gid to "1000 1000 24 25 27 29 30 44 46 108 111 121 1000"
```

**NOTES**

1. The command above does _not_ need `root` privileges
2. Please don't use Starman's `--user` option to set the user;
   it badly interacts with initialization run by LedgerSMB

## Environment Variables

We support the following Environment Variables within our code

* `LSMB_WORKINGDIR` : Optional
  * Causes a `chdir` to the specified directory as the first thing done in
    `starman.psgi`
  * If not set the current dir is used.
  * An example would be

  ```bash
  LSMB_WORKINGDIR='/usr/local/ledgersmb/' starman ...
  ```

We support the following Environment Variables for our dependencies

* `PGHOST` : Optional
  * Specifies the `Postgres server` Domain Name or IP address
* `PGPORT` : Optional
  * Specifies the `Postgres server` Port
* `PGSSLMODE` : Optional
  * Enables SSL for the `Postgres` connection

Please note the earlier remarks about the `local::lib` environment requiring
the variables `PERL5LIB`, `PERL_MM_OPT`, `PERL_MB_OPT` and `PATH` being set
up.


## Next steps

The system is installed and should be available for evaluation through

* `http://localhost:5762/setup.pl`    # creation and privileged management of
                                      company databases
* `http://localhost:5762/login.pl`    # Normal login for the application

The system is ready for [preparation for first
use](https://ledgersmb.org/topic/preparing/preparing-ledgersmb-18-first-use).

# Project information

Web site: [`https://ledgersmb.org/`](https://ledgersmb.org)

Live chat:

* Matrix: [`#ledgersmb:matrix.org`](https://app.element.io/#/room/#ledgersmb:matrix.org)
  (bridged IRC channel)

Mailing list archives: [`https://archive.ledgersmb.org`](https://archive.ledgersmb.org)

Mailing lists:

* [Announcements](https://lists.ledgersmb.org/postorius/lists/announce.lists.ledgersmb.org/)
* [User Discussion](https://lists.ledgersmb.org/postorius/lists/users.lists.ledgersmb.org/)
* [Developer Discussion](https://lists.ledgersmb.org/postorius/lists/devel.lists.ledgersmb.org/)

Repository: `https://github.com/ledgersmb/LedgerSMB`

## Project contributors

Source code contributors can be found in the project's `Git` commit history
as well as in the CONTRIBUTORS file in the repository root.

Translation contributions can be found in the project's `Git` commit history
as well as in the `Transifex` project Timeline.


# Copyright

```plain
Copyright (c) 2006 - 2020 The LedgerSMB Project contributors
Copyright (c) 1999 - 2006 DWS Systems Inc (under the name SQL Ledger)
```

# License

[`GPLv2`](https://opensource.org/licenses/GPL-2.0)
