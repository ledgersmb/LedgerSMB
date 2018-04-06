#!/usr/bin/perl
use warnings;
use strict;

use DBI;
use Getopt::Long;
my @company_roles;
my $role;
my $host = 'localhost';
my $port = '5432';
my $postgres_username = 'postgres';
my $postgres_password;
my $postgres_db = 'postgres';
my $company_name;
my @other_roles;
my $progress;
my $help;
my $usage = qq{
usage: $0 --company COMPANY --postgres_password PASS [options]
Available options:
 --company		The name of the database to be dropped [*]
 --postgres_username	postgres username, only use if not [$postgres_username]
 --postgres_password	postgres user password. Defaults to none [*]
 --postgres_db		postgres database name. Defaults to [$postgres_db]
 --owner		The superuser owner of database [optional]
 --role			Repeat to add other roles to be dropped, such as 'admin'
 --host			The PostgreSQL host to connect to (see 'man psql') [$host]
 --port			The PostgreSQL port to connect to (see 'man psql') [$port]

Roles like 'lsmb_"company_name"__%' within the database are removed.
};
GetOptions (
	'host:s' => \$host,
	'port:i' => \$port,
	'company=s' => \$company_name,
	'owner:s' => \@other_roles,
	'role:s' => \@other_roles,
	'postgres_username:s' => \$postgres_username,
	'postgres_password=s' => \$postgres_password,
	'postgres_db:s' => \$postgres_db,
	'progress' => \$progress,
	'help|?|h' => \$help
);

if ($help) {
	print $usage;
	exit;
}

unless ($company_name) {
	print $usage;
	print "\nmissing or empty --company option\n";
	exit;
}

unless ($postgres_password) {
	print $usage;
	print "\nmissing or empty --postgres_password option\n";
	exit;
}
my $dbh = DBI->connect("DBI:Pg:dbname=$postgres_db;host=$host;port=$port", $postgres_username, $postgres_password, {'RaiseError' => 0, pg_enable_utf8 => 1 });

if ($progress) {
	print "DROP DATABASE $company_name;\n";
}
$dbh->do("DROP DATABASE $company_name;");

$company_name .= '__';
if ($progress) {
	print "SELECT rolname FROM pg_roles WHERE rolname LIKE 'lsmb_$company_name%';\n";
}
my $SQL = "SELECT rolname FROM pg_roles WHERE rolname LIKE 'lsmb_$company_name%';";

my $sth = $dbh->prepare($SQL);
	$sth->execute;
while ($role = $sth->fetchrow) {
	if ($progress) {
		print "$role\n";
	}
	push @company_roles, $role;
}
$sth->finish;

for my $role (@company_roles) {
	if ($progress) {
		print "DROP ROLE $role;\n";
	}
	$dbh->do("DROP ROLE $role;");
}

for my $role (@other_roles) {
	if ($progress) {
		print "DROP ROLE $role;\n";
	}
	$dbh->do("DROP ROLE $role;");
}

