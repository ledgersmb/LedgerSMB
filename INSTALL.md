

Contents
--------

 * [System requirements](#system-requirements)
 * [Simple Server Setup: Running on Starman](Running-on-Starman)
 * Installing Apache 2
 * Installing PostgreSQL
 * PostgreSQL authorization settings
 * Installing Perl module dependencies
   * for Debian
   * for Fedora
   * for <your system>
 * Initializing a company database
   * Manual Database Creation (needed on Windows platforms)
 * Adding configuration to Apache 2.x
 * Manual configuration
 * Upgrading
 * Company database removal



System requirements
===================

LedgerSMB depends on the following software:

 * a web server (Starman, Apache v2.x, MS IIS, etc)
 * PostgreSQL 9.2+
 * Perl 5.10+


Installation process overview
=============================

 1. Install the base software: web server (Apache),  
    database server (PostgreSQL) and Perl from your distribution  
    and package manager or source. Read on for details  
 2. Installing Perl module dependencies from your distribution and  
    package manager or CPAN.  Read on for details  
 3. Give the web server access to the ledgersmb directory
 4. Edit ./ledgersmb/ledgersmb.conf to be able to access the database
    and locate the relevant PostgreSQL contrib scripts
 5. Initializing a company database
    Database setup and upgrade script at http://localhost/ledgersmb/setup.pl
 6. Login with your name (database username),
    password (database user password), Company (databasename)

Running on Starman
===================
As an alternative to Apache 2, LedgerSMB now supports the Perl-based web server
named Starman.  To install you need:

 * Starman
 * CGI::Emulate::PSGI
 * PSGI::Middleware::Static
 * Plack::Builder

Compared to Apache 2, Starman seems to perform better at the Perl portions of
the application, but slower at serving Javascript and CSS files, though these
are usually cached on the browser.  Thus it is not unusual to see the software
seem to be slower at the first and then pick up speed, becoming faster than the
equivalent CGI installations.

The above may be installed by running the Makefile.PL and selecting appropriate
options.

Then from the LedgerSMB directory starting is as simple as:

 starman --preload-app tools/starman.psgi

The server by default starts on port 5000 so you would access the installation
by pointing your web browser to:

 http://localhost:5000/login.pl

You can also daemonize Starman, run it on the default port, and much more.  See
the starman documentation for details.  If you are using older versions of 
Starman, we recommend setting up SSL on a web server like Apache or Nginx and 
back-proxying.

Installing Apache 2
===================

This is not necessary if you are running Starman and only accessing from your
local system.

On Debian and its derivatives - like Ubuntu - Apache installation
is as simple as running:

 $ apt-get install apache2

On Fedora and its derivatives (RedHat, Centos ++) the following command
does the same:

 $ yum install httpd

On other systems, the steps to follow may differ.  Please submit
instructions for your system for inclusion here.


Installing PostgreSQL
=====================

On Debian and its derivatives installing PostgreSQL works with:

 $ apt-get install postgresql postgresql-client postgresql-contrib

On Fedora and its derivatives this command does the same:

 $ yum install postgresql postgresql-server postgresql-contrib

On other systems, the steps to follow may differ.  Please submit
instructions for your system for inclusion here.


PostgreSQL authorization settings (pg_hba.conf)
===============================================

pg_hba.conf settings for production
-----------------------------------

LedgerSMB passes through the HTTP auth info to PostgreSQL as user
credentials.  Currently we do not support Kerberos auth but that won't
be hard to add once someone wants it (maybe a couple hours of
development time).  Consequently, you should be aware of a couple of
things:

1)  Re-usable credentials are required.  That basically means HTTP
Basic unless you want to set up Kerberos.  As a result you will
certainly want to run this over SSL if this is not a single system
operation (which in your cases it is not).

2)  This also means that PostgreSQL must be able to use the
credentials the web server accepts.  Currently we recommend the md5
authentication method in the pg_hba.conf.  If you set pg_hba.conf
options to trust, then it won't even check the password or the
password expiration, so don't do that outside of testing/recovery
scenarios.

3)  The postgres user or other db superuser must be given access via
the web app in order to create databases.  A password must be set for
this user, if not previously set, if you wish to use the setup.pl web
management console to configure LedgerSMB company databases.

A typical pg_hba.conf entry might be:

host   all   all   127.0.0.1/32    md5

If you want to lock this down, you can lock it down further by:
host   lsmbdb  all  127.0.0.1/32    md5
host  postgres postgres  127.0.0.1/32    md5

A typical command to set a password using the psql command line
might be:

 $ psql -c "ALTER USER postgres WITH PASSWORD 'My-Password'"


As of 1.4, connections to template1 are no longer required for the db setup 
process.

Note that the above will require new pg_hba.conf lines for each db created.


Installing Perl module dependencies
===================================

LedgerSMB depends on these additional modules (not listing core modules):

  Test::More
  Test::Trap
  Test::Exception
  Data::Dumper
  Log::Log4perl
  Locale::Maketext
  Locale::Maketext::Lexicon
  DateTime
  DBI
  DBD::Pg
  MIME::Base64
  Digest::MD5
  HTML::Entities    (part of HTML::Parser)
  Math::BigFloat    (part of Math::BigInt)
  IO::Scalar        (part of IO-stringy)
  Config::IniFiles
  MIME::Lite
  Template  (also known as The Template Toolkit or TT)
  Error
  CGI::Simple
  File::MimeInfo
  Number::Format
  DateTime::Format::Strptime
  Moose
  namespace::autoclean
  Carp::Always
  JSON

and these optional ones:

  XML::Simple        [RESTful Web Services XML support]
  Image::Size        [Size detection for images for embedding in LaTeX]
  Net::TCLink        [Support for TrustCommerce credit card processing]
  Parse::RecDescent  [Support for the *experimental* scripting engine]
  Getopt::Long       [Developer tool dependencies]
  FileHandle         [Developer tool dependencies]
  Locale::Country    [Developer tool dependencies]
  Locale::Language   [Developer tool dependencies]
  Template::Plugin::Latex [Support for Postscript and PDF output]
  TeX::Encode             [Support for Postscript and PDF output]
  XML::Twig               [Support for OpenOffice output]
  OpenOffice::OODoc       [Support for OpenOffice output]

To build using the Makefile.PL you will also need:

  Module::Install

All these modules can be downloaded from CPAN, the modules distribution
archive for Perl. However our experience has been that if your distribution
provides a module via its package manager (apt, rpm, etc.), you will have
fewer difficulties if you use that instead.

The sections below list specific instructions for the different OSes and
distributions. If you plan to depend as much as possible - as recommended -
on your distribution, you should follow the instructions in those sections
before proceeding here.

When you have completed the distribution specific steps described below,
you should proceed to run:

 $ perl Makefile.PL
 $ make test

which will ask you which modules it should download, if you didn't install
- using your package manager - all of the required and optional modules
listed above. If you don't want support for a specific module, simply
answer 'no' in response to the download question.

Remark: If you've never downloaded packages from CPAN, Perl is likely
to ask you a number of questions regarding the configuration of the
CPAN module (the Perl module downloader) as well.




>>> Perl module dependencies for Debian

---- Actions for Debian Wheezy  (7.x stable)

To install all the required packages which Wheezy supports, execute the
following command:

 $ aptitude install libdatetime-perl libdbi-perl libdbd-pg-perl \
   libcgi-simple-perl libtemplate-perl libmime-lite-perl \
   liblocale-maketext-lexicon-perl libtest-exception-perl \
   libtest-trap-perl liblog-log4perl-perl libmath-bigint-gmp-perl \
   libfile-mimeinfo-perl libtemplate-plugin-number-format-perl \
   libdatetime-format-strptime-perl libconfig-general-perl \
   libdatetime-format-strptime-perl libio-stringy-perl libmoose-perl \
   libconfig-inifiles-perl libnamespace-autoclean-perl \
   libcarp-always-perl libjson-perl


This installs the required modules available from the Wheezy repository.

To install the (optional) PDF/Postscript output module, install the
following packages by executing this command:

 $ aptitude install libtemplate-plugin-latex-perl \
      libtex-encode-perl texlive-latex-recommended

To install the optional module for size detection of images for embedding
in LaTeX, execute:

 $ aptitude install libimage-size-perl

The credit card processing support for TrustCommerce is available
from the Wheezy repository through:

 $ aptitude install libnet-tclink-perl

The Open Office output option is available from the Wheezy repository
as well through the command:

 $ aptitude install libxml-twig-perl libopenoffice-oodoc-perl

To use the Starman perl-based web server install the required perl modules
by executing:

 $ aptitude install starman libcgi-emulate-psgi-perl libplack-perl

(@@@ ADD info about xelatex @@@)
http://ledgersmb.org/faq/localization/im-using-non-ascii-unicode-characters-why-cant-i-generate-pdf-output



>>> Perl module dependencies for Fedora and its derivatives (RedHat, Centos ++)

---- Actions for Fedora 
Install rpm or look at dists/rpm/ledgersmb.spec for perl module dependencies
(@@@ update for 1.4 @@@)


Initializing a company database
===============================

LedgerSMB 1.3 and higher stores data for each company in a separate "database".
A database is a PostgreSQL concept for grouping tables, indexes, etc.

Each company database must be named.  This name is essentially the system
identifier within PostgreSQL for the company's dataset.  The name for the
company database can only contain letters, digits and underscores.
Additionally, it must start with a letter.  Company database names are
case insensitive, meaning you can't create two separate company databases
called 'Ledgersmb' and 'ledgersmb'.

One way you can create databases fairly easily is by directing your web browser
to the setup.pl script at your installed ledgersmb directory.  So if the 
base URL is http://localhost/ledgersmb/, you can access the database setup and 
upgrade script at http://localhost/ledgersmb/setup.pl.  This is very different
from the approaches taken by LedgerSMB 1.2.x and earlier and SQL-Ledger, but
rather forms a wizard to walk you through the process.

The setup.pl wizard will prompt for a super-user login and password. This is
the database superuser mentioned above (often 'postgres').  It will also ask
for a database name.  If the database name you provide does not yet exist,
the process of creating a new company database will be started.

Please note that the setup.pl file assumes that LedgerSMB is already configured 
to be able to access the database and locate the relevant PostgreSQL contrib 
scripts.  In particular, you must have the contrib_dir directive set to point
to those scripts properly in your ledgersmb.conf before you begin.

If you are upgrading from 1.2, your 1.2 tables will be moved to schema lsmb12.
Please keep this schema for some months. Updates which need this schema may
still be necessary.

An alternative method is the 'prepare-company-database.sh' script contributed by
Erik Huelsmann.  This script can be useful in creating and populating databases
from the command line and it offers a reference implementation written in BASH
for how this process is done.   The prepare-company-database.sh script is only
supported on GNU environments, but a prepare-company-database.pl is included
with nearly identical syntax which is supported everywhere LedgerSMB is.

The 'prepare-company-database.sh' script in the tools/ directory will set
up databases to be used for LedgerSMB. The script should be run as 'root'
because it wants to 'su' to the postgres user.  Alternatively, if you
know the password of the postgres user, you can run the script as any other
user.  You'll be prompted for the password.  Additionally, the script creates
a superuser to assign ownership of the created company database to. By
default this user is called 'ledgersmb'.  The reason for this choice is that
when removing the ledgersmb user, you'll be told about any unremoved parts
of the database, because the owner of an existing database can't be removed
until that database is itself removed.

The following invocation of the script sets up your first test company,
when invoked as the root user and from the root directory of the LedgerSMB
sources:

 $ ./tools/prepare-company-database.sh --company testinc

The script assumes your PostgreSQL server runs on 'localhost' with
PostgreSQL's default port (5432).

Upon completion, it will have created a company database with the name
'testinc', a user called 'ledgersmb' (password: 'LEDGERSMBINITIALPASSWORD'),
a single user called 'admin' (password: 'admin') and the roles required to
manage authorizations.

Additionally, it will have loaded a minimal list of languages required
to succesfully navigate the various screens.

All these can be adjusted using arguments provided to the setup script. See
the output generated by the --help option for a full list of options.

Note: The script expects to be able to connect to the postgresql database
      server over a TCP/IP connection after initial creation of the ledgersmb
      user.  The ledgersmb user will be used to log in. To ensure that's
      possible, it's easiest to ensure there's a row in the pg_hba.conf file
      [the file which says how PostgreSQL should enforce its login policy]
      with a 'host' configuration for the 127.0.0.1/32 address and the md5
      authentication enforcement.  This line can be inserted for the duration
      of the configuration of LedgerSMB, if the file doesn't have one.  The
      line can safely be removed afterwards.

Manual Database Creation:
-------------------------
In some environments, using the tools above are not possible.  These may 
include some heavily scripted environments which require additional control 
than the above tools provide, or rare environments where environemnt variables
are not recognized by libpq or are not properly transmitted from Perl to the 
called program (such problems have been reported to us on Microsoft Windows 
platforms).

These instructions also provide basic documentation for custom db creation 
tools.

In this case:

1.  Load the sql/Pg-database.sql using a tool of your choice (psql or PgAdmin)
2.  Load the modules in the order located in sql/modules/LOADORDER
    * can be done programmatically, see the UNIX Bash script reload_modules.sh 
      in that same directory.
    * can use tools of your choice (PGAdmin, psql).

When upgrading a database, you perform that second stage, and then set the 
version record in the defaults table to the appropriate version (with a new
database, this is set by default).  To do this:

    * SELECT * FROM setting__set('version', '1.3.41'); -- or other version


Adding configuration to Apache 2.x
==================================

LedgerSMB requires a webserver which passes authentication information
through to the LedgerSMB application. Currently, Apache (with mod_rewrite
support) and IIS are known to support this requirement. The section below
details the Apache setup process.

Default installation layouts for Apache HTTPD on various operating systems 
and distributions: http://wiki.apache.org/httpd/DistrosDefaultLayout

If your Apache has been built with module support, your configuration files
should include the following line somewhere:

LoadModule rewrite_module <path-to-apache-modules-directory>/mod_rewrite.so

[On Debian and its derivatives, mod_rewrite can be enabled using the command

 $ a2enmod rewrite

executed as the root user.]

A default configuration file to be used with Apache2 comes with LedgerSMB in
its root project directory: ledgersmb-httpd.conf.template. You can use the 
'configure_apache.sh' script to fill out the template.

You my need to add a commmand to your Apache configuration to load the
configuration in that file by including the following line:

Include /path/to/ledgersmb/ledgersmb-httpd.conf

If your distribution load extra config files from example conf.d 
you do not need to add the the line to your Apache configuration.
[Debian, Fedora, Centos, RedHat]

[On Debian and derivatives, you can store the resulting
configuration file directly in the /etc/apache2/conf.d directory.  From
that location, it'll be automatically included upon the next server (re)start.
On Apache 2.4 on Debian and derivatives, you can store the configuration file 
in the /etc/apache2/conf-enabled directory. You will need to add the cgi module
by going to /etc/apache2/mods-enabled/ and creating a symbolic link like this:
ln -s /etc/apache2/mods-available/cgi.load cgi.load
You also may need to add a symbolic link to enable apache to see postgres:
ln -s /user/bin/psql /bin/psql
both these commands will need to be performed with root permissions (use sudo)]

In order for the changes to take effect, you should run

 $ apachectl restart

On some systems apachectl might be called apache2ctl.

On systems without apachectl support, you will need to run either:

 $ service apache2 restart

or

 $ /etc/init.d/apache2 restart


Manual configuration
====================

If you want to perform the installation of the company database completely
manually, you should consult the 'tools/prepare-company-database.sh' script
as the authorative documentation of the steps to perform.


Upgrading to LedgerSMB 1.5
==========================

From LedgerSMB 1.4:

Untar over the top and then select step 1 or 2:

1)  Automated process (all platforms):

* direct browser to the setup.pl file in the directory you are in.
* provide PostgreSQL superuser credentials and the name of your data base.
* Click continue.
* [Optionally] Click 'Backup DB' and/or 'Backup Roles'.
* Click 'Yes', answering "LedgerSMB 1.4 found. Upgrade?"
* Repeat for each database.

2) Shell script process (UNIX/Linux only):

* cd to the sql/modules directory of the ledgersmb installation.
* sh reload_modules.sh [dbname]
* repeat the shell script for each database.

From LedgerSMB 1.3:

Untar over the top and then select step 1 or 2:

1)  Browser based process (all platforms):

* direct browser to the setup.pl file in the directory you are in.
* provide PostgreSQL superuser credentials and the name of your data base.
* Click continue.
* [Optionally] Click 'Backup DB' and/or 'Backup Roles'.
* Click 'Yes', answering "LedgerSMB 1.3 found. Upgrade?"
* Repeat for each database.


From LedgerSMB 1.1 and earlier:

For versions prior to 1.2, please upgrade to LedgerSMB 1.2 before upgrading to
1.3.x.  To do this upgrade, simply untar the version of 1.2.x over your old
installation and run the relevant database upgrade scripts (in
sql/upgrade/legacy).  Then proceed below.

From LedgerSMB 1.2.x

* Untar over the top.
* Check your Perl dependencies:
   * perl Makefile.PL
   * make
   * make test
      But run 'make test' under an english locale, because some tests check for english error messages.
      (Bash tips: LANG=en_US make test )
* run the install.sh script.
* fix ledgersmb.conf with new config
  copy ledgersmb.conf to ledgersmb.conf.old
  copy conf/ledgersmb.conf.default to ledgersmb.conf and reconfigure.
* direct your browser to the setup.pl script in your ledgersmb directory (via
  http) and follow the prompts:
   * Provide Pg superuser and database information for your existing database
     (the database created for your company)
   * Click continue when asked to upgrade
   * When asking for upgrade info:
       * contrib_dir is the directory where either tablefunc.control is
       * Default country is the country to map contacts which have no country
         information to.  This is the short, two letter ISO code for the
         country, such as AU for Austria, or US for United States.  It is
         case insensitive.
       * Default ar/ap accounts provide links to accounts for purposes of
         selection among multiple AR/AP accounts, and for purposes of payment
         reversals.  Enter account numbers here, like 1200 for AR and 2100 for
         AP
   * Provide user information.
     Note: users are recreated as PostreSQL db users with application acess instead
     of just imported from your 1.2.x install. New users created by the administrative
     functions have their password auth timing out after a day, unless they change their
     passwords after logging into LedgerSMB.
   * log into the application and create additional users under System/User
     Management

ROLLING BACK AN UPGRADE
=========================

LedgerSMB upgrades are non-destructive and work by moving data to the side,
adding mapping data, and then populating a new LedgerSMB schema.  The data is retained in an old schema, with a naming convention like lsmbnn (for LedgerSMB) or slnn (for SQL-Ledger).  The following schemas are used currently:

lsmb13: LedgerSMB 1.3
lsmb12: LedgerSMB 1.2
sl28:  SQL-Ledger 2.8

We include downgrade scripts for previous LSMB versions.  This works by removing
the mapping the data and restoring the old schema.  Changes made in the process
of preparing for upgrades (the test screens for unique identifiers etc) are
preserved but nothing else is.

The downgrade scripts assume that LedgerSMB is installed in the public schema.
If this is not the case, then the scripts will have to be edited before running.

UPGRADING INTO A NON-STANDARD SCHEMA
====================================

The installation and upgrade scripts are schema-agnostic.  They install the
components into the first available schema on the installing super-users
search_path.

This should be done for users of the software too (using alter database or alter
user), and it must also be configured in the ledgersmb.conf.




Company database removal
========================

In the tools/ directory, there's a script which will remove a company
database and all the standard authorization data that's created by
the 'prepare-company-database.sh' script.  Said script is called
'delete-company-database.sh'.

