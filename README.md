[![GPLv2 Licence](https://badges.frapsoft.com/os/gpl/gpl.png?v=103)](https://opensource.org/licenses/GPL-2.0/)
[![Build Status](https://api.travis-ci.org/ledgersmb/LedgerSMB.svg?branch=master)](https://travis-ci.org/ledgersmb/LedgerSMB)
[![Coverage Status](https://coveralls.io/repos/github/ledgersmb/LedgerSMB/badge.svg?branch=master)](https://coveralls.io/github/ledgersmb/LedgerSMB?branch=master)
[![Docker](https://img.shields.io/docker/pulls/ledgersmb/ledgersmb.svg)](https://hub.docker.com/r/ledgersmb/ledgersmb/)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/795/badge)](https://bestpractices.coreinfrastructure.org/projects/795)

As coveralls currently has a bug with their badging for master, here is a corrected version
[![Coverage Status](http://www.sbts.com.au/repos/github/ledgersmb/LedgerSMB/badge.svg?branch=master)](https://coveralls.io/github/ledgersmb/LedgerSMB?branch=master)


# LedgerSMB

Small and Medium business accounting and ERP

# SYNOPSIS

LedgerSMB is a free integrated web application accounting system, featuring
double entry accounting, budgetting, invoicing, quotations, projects, timecards,
inventory management, shipping and more ...

The UI allows world-wide accessibility; with its data stored in the
enterprise-strength PostgreSQL open source database system, the system is know
to operate smoothly for businesses with thousands of transactions per week.
Screens and customer visible output are defined in templates, allowing easy and
fast customization. Supported output formats are PDF, CSV, HTML, ODF and more.

Directly send orders and invoices from the built-in e-mail function to your
customers or RFQs (request for quotation) to your vendors with PDF attachments.


# System requirements

## Server

 * Perl 5.14+
 * PostgreSQL 9.4+
 * Web server (e.g. nginx, Apache, lighttpd)

The web external server is only required for production installs;
for evaluation purposes a simpler setup can be used, as detailed
below.

## Client

A [Dojo 1.10 compatible web browser](http://dojotoolkit.org/reference-guide/1.10/releasenotes/1.10.html#user-agent-support)
is all that's required on the client (except IE8 and 9); it includes Chrome as
of version 13, FireFox as of 3.6 and MS Internet Explorer as of version 10 and
a wide range of mobile browsers.

# Quick start

The instructions below are for getting started quickly; the [project's
site](http://ledgersmb.org) provides [in-depth installation instructions](http://ledgersmb.org/topic/installing-ledgersmb-15)
for **production** installs.

## Check out the sources from GitHub

__***Skip this step for from-tarball installs***__
(Installation from release tarballs is preferred over installation from GitHub.)

To get the latest development version:

```sh
 $ git clone https://github.com/ledgersmb/LedgerSMB.git
 $ cd LedgerSMB
 $ git submodule update --init --recursive
```

To get the released version 1.5.5, the commands look like:

```
 $ git clone -b 1.5.5 https://github.com/ledgersmb/LedgerSMB.git
 $ cd LedgerSMB
 $ git submodule update --init --recursive
```


## System (library) dependencies

The following non-Perl (system) dependencies need to be in place for the
```cpanm``` command mentioned below to work, in addition to what's documented
on the [How to install CPAN modules](http://www.cpan.org/modules/INSTALL.html)
page on CPAN.

 * PostgreSQL client libraries
 * PostgreSQL server
 * DBD::Pg 3.4.2+ (so cpanm recognises that it won't need to compile it)  
   This package is called `libdbd-pg-perl` in Debian and `perl-DBD-Pg`
   in RedHat/Fedora

Then, some of the features listed below have system requirements as well:

 * latex-pdf-ps depends on these binaries or libraries:
   * latex (usually provided through a texlive package)
   * pdflatex
   * dvitopdf
   * dvitops
   * pdftops
 * latex-pdf-images
   * ImageMagick

## Perl module dependencies

This section depends on [a working local::lib installation](https://ledgersmb.org/content/setting-perls-locallib-ledgersmb-why-and-how)
as well as an installed `cpanm` executable. Both should be available from
your distribution's package repository (Debian calls them `liblocal-lib-perl`
and `cpanminus` respectively). `cpanm` depends on the `make` command being available.

To install the Perl module dependencies, run:

```sh

 $ cpanm --quiet --notest --with-feature=starman [other features] --installdeps .

```
The following features may be selected by
specifying ```--with-feature=<feature>```:

| Feature          | Description                         |
|------------------|-------------------------------------|
| latex-pdf-ps     | Enable PDF and PostScript output    |
| latex-pdf-images | Image size detection for PDF output |
| starman          | Starman Perl/PSGI webserver         |
| openoffice       | OpenOffice.org document output      |
| edi              | (EXPERIMENTAL) X12 EDI support      |
| rest             | (EXPERIMENTAL) RESTful webservices  |

Note: The example command contains ```--with-feature=starman``` for the
purpose of the quick start.

When not installing as root or through `sudo`, `cpanm` will install unfulfilled
library dependencies into a location which can be used with `local::lib`. 

The [in-depth installation instructions](http://ledgersmb.org/topic/installing-ledgersmb-15)
contain a list of distribution provided packages to reduce the
number of dependencies installed from CPAN.

**NOTES**

 1. For the pdf-ps target, LaTeX is required.
 1. For the pdf-images target, ImageMagick is  required.

## PostgreSQL configuration

While it's possible to use LedgerSMB with the standard ```postgres``` user,
it's good practice to create a separate 'LedgerSMB database administrator':

```plain
$ sudo -u postgres createuser --no-superuser --createdb --login \
          --createrole --pwprompt lsmb_dbadmin
Enter password for new role: ****
Enter it again: ****
```

The ```pg_hba.conf``` file should have at least these lines in it (order of the entries matters):

```plain
local   all                            postgres                         peer
local   all                            all                              peer
host    all                            postgres        127.0.0.1/32     reject
host    all                            postgres        ::1/128          reject
host    postgres,template0,template1   lsmb_dbadmin    127.0.0.1/32     md5
host    postgres,template0,template1   lsmb_dbadmin    ::1/128          md5
host    postgres,template0,template1   all             127.0.0.1/32     reject
host    postgres,template0,template1   all             ::1/128          reject
host    all                            all             127.0.0.1/32     md5
host    all                            all             ::1/128          md5
```

 > Note: `pg_hba.conf` can be found in `/etc/postgresql/<version>/main/` on Debian
 >  and in `/var/lib/pgsql/data/` on RedHat/Fedora

After editing the ```pg_hba.conf``` file, reload the PostgreSQL server
(or without 'sudo' by running the commands as root user):

```sh
 $ sudo service postgresql reload
 # -or-
 $ sudo /etc/init.d/postgresql reload
```

## Configure LedgerSMB

### From-tarball installs
(Installation from tarball is highly preferred over installation from GitHub for production installs.)

```bash
 $ cp conf/ledgersmb.conf.default ledgersmb.conf
```

### From-GitHub installs

```bash
 $ cp conf/ledgersmb.conf.unbuilt-dojo ledgersmb.conf
```

 > Note: Using 'built dojo' instead of 'unbuilt dojo' will greatly improve
 > page load times of some pages.  However, creating a built dojo
 > adds considerable complexity to these instructions; please consult
 > [the extensive setup instructions](https://ledgersmb.org/topic/installing-ledgersmb-15-github)
 > to build dojo.

## Running Starman

With the above steps completed, the system is ready to run the web server:

 > NOTE: DO NOT run starman (or any web service) as root, this is considered
 >     a serious security issue, and as such LedgerSMB doesn't support it.
 >     Instead, if you need to start LedgerSMB from a root process, drop
 >     privlidges to a user that doesn't have write access to the LedgerSMB Directories first.
 >     Most daemonising mechanisims (eg: systemd) provide a mechanism to do this.
 >     Do not use the starman --user= mechanism, it currently drops privlidges too late.

```bash
 $ starman -I lib -I old/lib --listen localhost:5762 tools/starman.psgi
2016/05/12-02:14:57 Starman::Server (type Net::Server::PreFork) starting! pid(xxxx)
Resolved [*]:5762 to [::]:5762, IPv6
Not including resolved host [0.0.0.0] IPv4 because it will be handled by [::] IPv6
Binding to TCP port 5762 on host :: with IPv6
Setting gid to "1000 1000 24 25 27 29 30 44 46 108 111 121 1000"
```


## Environment Variables

All regular Perl environment variables can be used. In particular, it's important to make sure
`PERL5LIB` is set correctly when setting up `local::lib` for the first time.

We support the following
- LSMB_WORKINGDIR : Optional
     - Causes a chdir to the specified directory as the first thing done in starman.psgi
     - If not set the current dir is used.
     - An example would be
    ```
    LSMB_WORKINGDIR='/usr/local/ledgersmb/'
    ```


## Next steps

The system is installed and should be available for evaluation through
- http://localhost:5762/setup.pl    # creation and privileged management of company databases
- http://localhost:5762/login.pl    # Normal login for the application

The system is ready for [preparation for first
use](http://ledgersmb.org/topic/preparing/preparing-ledgersmb-15-first-use).

# Project information

Web site: [http://ledgersmb.org/](http://ledgersmb.org)

Live chat:
 * IRC: [irc://irc.freenode.net/#ledgersmb](irc://irc.freenode.net/#ledgersmb)
 * Matrix: [https://vector.im/#/room/#ledgersmb:matrix.org](https://vector.im/#/room/#ledgersmb:matrix.org) (bridged IRC channel)

Forums: [http://forums.ledgersmb.org/](http://forums.ledgersmb.org/)

Mailing list archives: [http://archive.ledgersmb.org](http://archive.ledgersmb.org)

Mailing lists:
 * [https://lists.sourceforge.net/lists/listinfo/ledger-smb-announce](https://lists.sourceforge.net/lists/listinfo/ledger-smb-announce)
 * [https://lists.sourceforge.net/lists/listinfo/ledger-smb-users](https://lists.sourceforge.net/lists/listinfo/ledger-smb-users)
 * [https://lists.sourceforge.net/lists/listinfo/ledger-smb-devel](https://lists.sourceforge.net/lists/listinfo/ledger-smb-devel)

Repository: https://github.com/ledgersmb/LedgerSMB

## Project contributors

Source code contributors can be found in the project's Git commit history
as well as in the CONTRIBUTORS file in the repository root.

Translation contributions can be found in the project's Git commit history
as well as in the Transifex project Timeline.


# Copyright

```plain
Copyright (c) 2006 - 2017 The LedgerSMB Project contributors
Copyright (c) 1999 - 2006 DWS Systems Inc (under the name SQL Ledger)
```

# License

[GPLv2](http://open-source.org/licenses/GPL-2.0)
