#!/usr/bin/perl
# Copyright (c) 2012, The LedgerSMB Core Team
# All rights reserved. 
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met: 
#
# Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer. 
#
# Redistributions in binary form must reproduce the above copyright notice, this
# list of conditions and the following disclaimer in the documentation and/or
# other materials provided with the distribution. 
#
# THIS SOFTWARE IS PROVIDED BY THE LEDGERSMB CORE TEAM AND CONTRIBUTORS "AS
# IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL LEDGERSMB CORE TEAM OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
# This is the prepare-company-database.pl which serves as a command line tool
# for creating LedgerSMB databases and also as a reference implementation to 
# demonstrate the usage of the LedgerSMB::Database framework.
#
# 
use Getopt::Long;
use LedgerSMB::Database;
use Cwd;

# Needed for creating a user

use LedgerSMB;
use LedgerSMB::Entity::User;
use LedgerSMB::Entity::Person::Employee;
use DBI;

# always use strict!
use strict;

# DEFAULTS TO BE EDITED

my $ADMIN_FIRSTNAME='Default';
my $ADMIN_MIDDLENAME=undef;
my $ADMIN_LASTNAME='Admin';
my $ADMIN_USERNAME='admin';
my $ADMIN_PASSWORD='admin';

# Defaults for command line

my $company=undef;
my $owner='ledgersmb';
my $pass='LEDGERSMBINITIAL';
my $host='localhost';
my $port=5432;
my $srcdir=getcwd;
my $dstdir=getcwd;
my $cc = 'us';
my $coa="$srcdir/sql/coa/us/chart/General.sql";
my $gifi=undef;
my $progress=0;
my $help=0;

my $script_name = 'tools/prepare-company-database.pl';

my $usage = qq|
usage: $script_name --company COMPANY --pgsql-contrib DIR [option1 .. optionN]

This script wants to be run as the root user. If you don't, you'll be
asked to enter the password of the 'postgres' user

This script creates a 'ledgersmb' user on the specified PostgreSQL host,
if it does not exist.  Then it proceeds to load the LedgerSMB database
structure and content, loading Chart of Accounts data and GIFI data
as specified in the argument list.

After the database has been created, the script inserts a default user
'$ADMIN_USERNAME' (password: '$ADMIN_PASSWORD'), with these initial values:

First name:  $ADMIN_FIRSTNAME  (NULL == none)
Middle name: $ADMIN_MIDDLENAME (NULL == none)
Last name:   $ADMIN_LASTNAME   (NULL == none)
Country:     'US'

This default user will be assigned all privileges within the application.

Available options:
 --srcdir	The path where the sources for LedgerSMB are located
                [$srcdir]
 --dstdir	The path where the sources will be located when invoked
		from the webserver [$dstdir]
 --host		The PostgreSQL host to connect to (see 'man psql') [$host]
 --port		The PostgreSQL port to connect to (see 'man psql') [$port]
 --company	The name of the database to be created for the company [*]
 --owner	The name of the superuser which is to become owner of the
		company's database [$owner]
 --password	The password to be used to create the 'ledgersmb' user
		on the specified PostgreSQL server [$pass]
 --cc           The two letter country code to use [$cc]
 --coa		The chart of accounts file to load [$coa]
 --gifi		The GIFI file to load if any [$gifi]
 --help		Shows this help screen

 * These arguments don't have a default, but are required
|;


GetOptions(
   'srcdir=s'        => \$srcdir,
   'dstdir=s'        => \$dstdir,
   'port=s'          => \$port,
   'host=s'          => \$host,
   'company=s'       => \$company,
   'owner=s'         => \$owner,
   'password=s'      => \$pass,
   'cc=s'            => \$cc,
   'coa=s'           => \$coa,
   'gifi=s'          => \$gifi,
   'help'            => \$help
);

&usage if $help;

# Setting up the environment here in case at some point we want to expand to
# call libpq programs directly.  It also makes the script more future proof in
# other ways.
# and is a LedgerSMB-ism.
#
$ENV{PGUSER} = $owner if $owner;
$ENV{PGPASS} = $pass if $pass;
$ENV{PGDATABASE} = $company if $company;
$ENV{PGHOST} = $host if $host;
$ENV{PGPORT} = $port if $port;

my $database = LedgerSMB::Database->new(
        {dbname => $company, 
    countrycode => $cc, 
     chart_name => $coa, 
   company_name => $company, 
       username => $owner, 
       password => $pass}
);

$database->create_and_load();


# CREATING THE USER
#
# This is a little tricky because we have to actually manually create a database
# connection.  In the future we may want to have such a database connection 
# returned by LedgerSMB::Database, but that is not done yet.

my $lsmb = LedgerSMB->new() || die 'could not create new LedgerSMB object';
$lsmb->{dbh} = DBI->connect("dbi:Pg:dbname=$ENV{PGDATABASE}",
                                       undef, undef, { AutoCommit => 0 });

# We also have to retrieve the country ID which requires a database query

my $sth = $lsmb->{dbh}->prepare(
            'SELECT id FROM country WHERE short_name ILIKE ?'
);

$sth->execute($cc);
my ($country_id) = $sth->fetchrow_array;

# This section is still untested and may be for some time.  Unlike in 1.3, we 
# don't have to do $lsmb->merge() and then create new copies of the LedgerSMB 
# archetype.  This leads to more direct, readable code, but there may still be
# some bugs to work out --CT

my $employee = LedgerSMB::Entity::Employee->new(
     first_name  => $ADMIN_FIRSTNAME,
     last_name   => $ADMIN_LASTNAME,
     middle_name => $ADMIN_MIDDLENAME,
     country_id  => $country_id,
);

$employee->save;

my $user = LedgerSMB::Entity::User->new(
     username    => $ADMIN_USERNAME,
     password    => $ADMIN_PASSWORD,
     import      => 't',
     entity_id   => $employee->entity_id,
);

$user->save;

my $user = LedgerSMB::DBObject::Admin->new({base => $lsmb});

$user->save_user;

# SUBS
#
# usage:  Print the usage message and exit.
#
sub usage { print $usage; exit; }
