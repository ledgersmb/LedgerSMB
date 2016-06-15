
# NAME

LedgerSMB - Small and Medium business accounting and ERP

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

 * Perl 5.10+
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
for production installs.

## Check out the sources from GitHub

Note: **Skip this step for from-tarball installs**
Installation from release tarballs is preferred over installation from GitHub.

To get the latest development version:

```sh
 $ git clone https://github.com/ledgersmb/LedgerSMB.git
 $ cd LedgerSMB
 $ git submodule update --init --recursive
```

To get the released version 1.4.22, the commands look like:

```
 $ git clone -b 1.4.22 https://github.com/ledgersmb/LedgerSMB.git
 $ cd LedgerSMB
 $ git submodule update --init --recursive
```


## System (library) dependencies

The following non-Perl (system) dependencies need to be in place for the
```cpanm``` command mentioned below to work, in addition to what's documented
on the [How to install CPAN modules](http://www.cpan.org/modules/INSTALL.html)
page on CPAN.

 * PostgreSQL client libraries
 * Either:
   * PostgreSQL development package (so cpanm can compile DBD::Pg)
     (RedHat: postgresql-devel, Debian: libpq-dev)
   * DBD::Pg 3.4.2+ (so cpanm recognises that it won't need to compile it)

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

Those who don't want to install the dependencies globally should
investigate [local::lib](http://search.cpan.org/~haarg/local-lib-2.000019/)
to create an "overlay" over the system packages in a separate
directory.

The [in-depth installation instructions](http://ledgersmb.org/topic/installing-ledgersmb-15)
contain a list of distribution provided packages to reduce the CPAN
installation.

**NOTES**

 1. For the pdf-ps target, LaTeX is required.
 1. For the pdf-images target, ImageMagick is  required.

## PostgreSQL configuration

While it's possible to use LedgerSMB with the standard ```postgres``` user,
it's good practice to create a separate 'LedgerSMB database administrator':

```plain
$ sudo su - postgres -c 'createuser --no-superuser --createdb --login
          --createrole --pwprompt lsmb_dbadmin'
Enter password for new role: ****
Enter it again: ****
```

The ```pg_hba.conf``` file should have at least these lines in it:

```plain
local   all                            postgres                         peer
local   all                            all                              peer
host    all                            postgres        127.0.0.1/32     reject
host    all                            postgres        ::1/128          reject
host    postgres,template0             lsmb_admin      127.0.0.1/32     md5
host    postgres,template0             lsmb_admin      ::1/128          md5
host    postgres,template0,template1   all             127.0.0.1/32     reject
host    postgres,template0,template1   all             ::1/128          reject
host    all                            all             127.0.0.1/32     md5
host    all                            all             ::1/128          md5
```

After editing the ```pg_hba.conf``` file, reload the PostgreSQL server
(or without 'sudo' by running the commands as root user):

```sh
 $ sudo service postgresql reload
 # -or-
 $ sudo /etc/init.d/postgresql reload
```

## Configure LedgerSMB

For most systems, all that's required in this step is:

```bash
 $ cp conf/ledgersmb.conf.default ledgersmb.conf
```

## Build optimized JavaScript widgets (aka "build Dojo")

Note: **Skip this step for from-tarball installs** The tarrball already contains
  the "compiled" JavaScript sources.


This step requires either ```node``` (NodeJS) or ```java``` to be installed
and in all cases ```make```.

```sh
 $ make dojo
```

Builds the required content for the ```UI/js/``` directory from the content
in the ```UI/js-src/``` directory.  Note that this step fails when submodules
haven't been correctly initialised.

## Running Starman

With the above steps completed, the system is ready to run the web server:

```bash
 $ starman --port 5762 tools/starman.psgi
2016/05/12-02:14:57 Starman::Server (type Net::Server::PreFork) starting! pid(xxxx)
Resolved [*]:5762 to [::]:5762, IPv6
Not including resolved host [0.0.0.0] IPv4 because it will be handled by [::] IPv6
Binding to TCP port 5762 on host :: with IPv6
Setting gid to "1000 1000 24 25 27 29 30 44 46 108 111 121 1000"
```

## Environment Variables

We support the following
- PERL5LIB        : Optional (but recommended)
     - should be configured before any LedgerSMB related process is executed (including starman/plack)
     - This should have the normal system entries, but also the LedgerSMB install dir should be prepended or appended depending on if the system is dedicated to LedgerSMB (prepend) or used for other things (append)
     - An example would be
    ```
    PERL5LIB='/home/foo/perl5/lib/perl5:/home/foo/perl5/lib/perl5:/usr/local/ledgersmb/'
    ```
- LSMB_WORKINGDIR : Optional
     - Causes a chdir to the specified directory as the first thing done in starman.psgi
     - If not set the current dir is used.
     - An example would be
    ```
    LSMB_WORKINGDIR='/usr/local/ledgersmb/'
    ```


## Next steps

The system is installed and should be available for evaluation through
http://localhost:5762/setup.pl and http://localhost:5762/login.pl.

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
Copyright (c) 2006 - 2016 The LedgerSMB Project contributors
Copyright (c) 1999 - 2006 DWS Systems Inc (under the name SQL Ledger)
```

# License

[GPLv2](http://open-source.org/licenses/GPL-2.0)
