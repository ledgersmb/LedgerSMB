#!/usr/bin/perl
package LedgerSMB::Scripts::dirt;
use warnings;
use strict;

use DBI;
use Getopt::Long;

# Default variable values section
my $editor = $ENV{EDITOR};
unless ($editor) {
	$editor = "vi";
}
my $owner = 'ledgersmb';
my $pass = 'LEDGERSMBINITIAL';
my $host = 'localhost';
my $port = '5432';
my $srcdir = `pwd`;
chomp $srcdir;
my $dstdir = `pwd`;
chomp $dstdir;
my $coa = "$srcdir/sql/coa/us/chart/General.sql";
my $chart_name;
my $gifi;
my $countrycode = 'US';
my $company_name = '';
my $postgres_username = 'postgres';
my $postgres_password;
my $postgres_db = 'postgres';
my $pgsql_contrib_dir;
my $admin_firstname = 'Default';
my $admin_middlename = 'NULL';
my $admin_lastname = 'Admin';
my $admin_username = 'admin';
my $admin_password = 'admin';
my $interactive = 0;
my $no_postgress_pass = 0;
my $progress = '';
my $help;
my $dbh;

# Usage explanation section

my $usage = qq{
usage: $0 --company COMPANY --pgsql-contrib DIR [option1 .. optionN]

This script wants to be run as the root user. You will need to have
permission to write the new ledgersmb-httpd.conf.
Unless you select --no_postgress_pass, you will be asked to enter the
password of the '$postgres_username' user.

This script creates a '$owner' superuser on the specified PostgreSQL host,
if it does not exist.  Then it proceeds to load the LedgerSMB database
structure and content, loading Chart of Accounts data and GIFI data
as specified in the argument list.

After the database has been created, the script inserts a default user
'$admin_username' (password: '$admin_password'), with these initial values:

First name:  $admin_firstname  (NULL == none)
Middle name: $admin_middlename (NULL == none)
Last name:   $admin_lastname   (NULL == none)
Country:     '$countrycode'

This default user will be assigned all privileges within the application.
You may change any or all of these default values.

Available options:
 --srcdir		The path where the sources for LedgerSMB are located
			[$srcdir]
 --dstdir		The path where the sources will be located when invoked
			from the webserver [$dstdir]
 --host			The PostgreSQL host to connect to (see 'man psql') [$host]
 --port			The PostgreSQL port to connect to (see 'man psql') [$port]
 --company		The name of the database to be created for the company [*]
 --countrycode		The name of the 2 character country code. Defaults to 'US'
 --owner		The name of the superuser which is to become owner of the
			company's database [$owner]
 --password		The password to be used to create the 'ledgersmb' user
			on the specified PostgreSQL server [$pass]
 --coa			The path locating the file to be used to load the
			Chart of Accounts data
			Defaults to '$srcdir/sql/coa/us/chart/General.sql'
 --chart		Chart used
 --gifi			The path locating the file to be
			used to load the GIFI data with the chart of accounts
 --postgres_username	postgres username, only use if not 'postgres'
 --postgres_password	postgres user password. Defaults to none
 --no_postgress_pass	Means no postgres password is needed
 --postgres_db		postgres database name. Defaults to 'postgres'
 --admin_firstname	Admin firstname
 --admin_middlename	Admin middlename
 --admin_lastname	Admin lastname
 --admin_username	Admin username
 --admin_password	Admin password
 --editor		Editor to be used to edit ledgersmb.conf if does not exist
 --progress		Echoes the commands executed by the script during setup
 --help			Shows this help screen

 * These arguments don't have a default, but are required
};

GetOptions (
	'srcdir:s' => \$srcdir,
	'dstdir:s' => \$dstdir,
	'host:s' => \$host,
	'port:i' => \$port,
	'pgsql_contrib=s' => \$pgsql_contrib_dir,
	'company=s' => \$company_name,
	'owner:s' => \$owner,
	'password:s' => \$pass,
	'coa:s' => \$coa,
	'chart:s' => \$chart_name,
	'gifi:s' => \$gifi,
	'countrycode:s' => \$countrycode,
	'postgres_username:s' => \$postgres_username,
	'postgres_password=s' => \$postgres_password,
	'no_postgress_pass:s' => \$no_postgress_pass,
	'postgres_db:s' => \$postgres_db,
	'admin_firstname:s' => \$admin_firstname,
	'admin_middlename:s' => \$admin_middlename,
	'admin_lastname:s' => \$admin_lastname,
	'admin_username:s' => \$admin_username,
	'admin_password:s' => \$admin_password,
	'editor:s' => \$editor,
	'progress' => \$progress,
	'help|?|h' => \$help
);
use lib qw($srcdir);
if ($help) {
	print $usage;
	exit;
}

unless ($company_name) {
	print $usage;
	print "\nmissing or empty --company option\n";
	exit;
}

unless (($postgres_password) || ($no_postgress_pass)) {
	print $usage;
	print "\nmissing or empty --postgres_password option\n";
	exit;
}
unless (stat "/tmp/ledgersmb") {
	mkdir "/tmp/ledgersmb";
}
if (stat "$srcdir/ledgersmb.conf") {
	require LedgerSMB;
	require LedgerSMB::Database;
	require LedgerSMB::Sysconfig;
} else {
	setup_ledgersmb_conf($srcdir);
	require LedgerSMB;
	require LedgerSMB::Database;
	require LedgerSMB::Sysconfig;
};

my $logger = Log::Log4perl->get_logger('LedgerSMB::Scripts::dirt');
my $creds = dirt_get_credentials();
my $request = {};
$request->{database} = $company_name;

$ENV{SCRIPT_NAME} = "dirt.pl";
# ENVIRONMENT NECESSARY
$ENV{PGUSER} = $creds->{login};
$ENV{PGPASSWORD} = $creds->{password};
$ENV{PGDATABASE} = $request->{database};

create_ledgersmb_httpd_conf();
unless ($no_postgress_pass) {
	$dbh = DBI->connect("DBI:Pg:dbname=$postgres_db;host=$host;port=5432", $postgres_username, $postgres_password, {'RaiseError' => 0, pg_enable_utf8 => 1 });
} else {
	$dbh = DBI->connect("DBI:Pg:dbname=$postgres_db;host=$host;port=5432", $postgres_username, {'RaiseError' => 0, pg_enable_utf8 => 1 });
}

my $is_v9_1plus_aref = $dbh->selectcol_arrayref("SELECT version();");
if ($progress) {
	print "$$is_v9_1plus_aref[0]\n";
}
my $admin_user_ok = $dbh->do("CREATE ROLE $creds->{login} WITH SUPERUSER LOGIN NOINHERIT ENCRYPTED PASSWORD '$creds->{password}';");
my $database = LedgerSMB::Database->new(
					{username => $creds->{login},
					company_name => $request->{database},
					password => $creds->{password}}
					);
if ($progress) {
	print "username $creds->{login}\n";
	print "company_name = $request->{database}\n";
	print "password = $creds->{password}\n";
}

my $rc = $database->create();#TODO what if createdb fails?
$logger->info("create rc=$rc");
my $mc = $database->load_modules('LOADORDER');
if ($progress) {
	print "\$mc = $mc\n";
}
$logger->info("load modules mc=$mc");

  # Load a chart of accounts
$dbh->disconnect;

$dbh = DBI->connect("DBI:Pg:dbname=$request->{database};host=$host;port=5432", $creds->{login}, $creds->{password}, {'RaiseError' => 0, pg_enable_utf8 => 1 });

my $psql_args = "-h $host -p $port -U $creds->{login}";
my $psql_cmd = "psql $psql_args -d $request->{database}";

  # Load a chart of accounts

if ($coa ne 'none') {
	open(my $psql_ph, "| $psql_cmd >/dev/null 2>&1") || die "can't run psql: $!";
	open (my $coa_fh, "<", $coa);
	while (<$coa_fh>) {
		print $psql_ph $_;
		if ($progress) {
			print $_;
		}
	}
	close $coa_fh;
	close $psql_ph;
}
  # Load a gifi

if ($gifi) {
	open(my $psql_ph, "| $psql_cmd >/dev/null 2>&1") || die "can't run psql: $!";
	open (my $gifi_fh, "<", $gifi);
	while (<$gifi_fh>) {
		print $psql_ph $_;
		if ($progress) {
			print $_;
		}
	}
	close $gifi_fh;
	close $psql_ph;
}
my $cmd="SELECT code FROM language;";
my @languages;
undef my $vetor;
my $sth = $dbh->prepare($cmd);
	$sth->execute;
while ($vetor = $sth->fetchrow) {
	push @languages, $vetor;
}
$sth->finish;

my @results = `tools/generate-language-table-contents.pl locale/po`;
#print @results;

$dbh->do("COPY language FROM STDIN WITH DELIMITER '|'");
for my $result (@results) {
	if (grep(/$result/, @languages)) {
		next;
	}
	$dbh->pg_putcopydata($result);
	if ($progress) {
		print $result;
	}
}
$dbh->pg_putcopyend();

my $SQL = "SELECT admin__save_user(NULL,
                         person__save(NULL,
                                      3,
                                      '$admin_firstname',
                                      '$admin_middlename',
                                      '$admin_lastname',
                                      (SELECT id FROM country
                                       WHERE short_name = '$countrycode')),
                         '$admin_username',
                         '$admin_password',
                         TRUE);

SELECT admin__add_user_to_role('$admin_username', rolname)
FROM pg_roles
WHERE rolname like 'lsmb_${company_name}_%';";

	my $ir = $dbh->do($SQL);
	if($ir) {
		if ($progress) {
			print qq{Success for CREATE ADMIN_USER $admin_username\n};
		}
	} else {
		print qq{Failure for CREATE ADMIN_USER $admin_username -- $DBI::errstr\n};
		exit;
	}



sub dirt_get_credentials {
my $return_value = {};
#$logger->debug("\$auth=$auth");#be aware of passwords in log!
($return_value->{login}, $return_value->{password}) = ($owner, $pass);
if (defined $LedgerSMB::Sysconfig::force_username_case){
if (lc($LedgerSMB::Sysconfig::force_username_case) eq 'lower'){
$return_value->{login} = lc($return_value->{login});
} elsif (lc($LedgerSMB::Sysconfig::force_username_case) eq 'upper'){
$return_value->{login} = uc($return_value->{login});
}
}

return $return_value;

}

sub create_ledgersmb_httpd_conf {
open (my $tmpl_fh, "<", "$srcdir/ledgersmb-httpd.conf.template");
open (my $lhttpconf_fh, ">", "$dstdir/ledgersmb-httpd.conf");

my @tmpl = <$tmpl_fh>;
$logger->info("Creating $dstdir/ledgersmb-httpd.conf\n");
if ($progress) {
	print "Creating $dstdir/ledgersmb-httpd.conf\n";
}
for my $line (@tmpl) {
	$line =~ s/WORKING_DIR/$dstdir/g;
	$logger->info("$line");
	if ($progress) {
		print "$line";
	}
	print $lhttpconf_fh $line;
}
close $tmpl_fh;
close $lhttpconf_fh;
}

sub setup_ledgersmb_conf {
	my $srcdir = shift;
	print "\n
		You do not have a copy of ledgersmb.conf.\n
		Please edit this new copy derived from ledgersmb.conf.default\n";
	sleep 4;
	system "cp $srcdir/conf/ledgersmb.conf.default $srcdir/ledgersmb.conf;$editor $srcdir/ledgersmb.conf";
}

1;
