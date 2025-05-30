#!/usr/bin/env perl

use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Spec;

use Capture::Tiny qw(capture);

use LedgerSMB::Company;
use LedgerSMB::Database;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($OFF);

 # Subprocesses don't want these options; we don't want to test them.
delete $ENV{PERL5LIB};
delete $ENV{PERL5OPT};


my @missing = grep { ! $ENV{$_} } (qw(LSMB_NEW_DB COA_TESTING LSMB_TEST_DB));
skip_all((join ', ', @missing) . ' not set') if @missing;

use File::Find::Rule;

my $rule = File::Find::Rule->new;
$rule->or($rule->new
               ->directory
               ->name(qr(gifi|sic))
               ->prune
               ->discard,
          $rule->new);
my @files = sort $rule->name("*.xml")->file->in("locale/coa");

my $db = "lsmb_test_db_coa";
(system('createdb', $db, '-T', $ENV{LSMB_NEW_DB}) >> 8 == 0)
    or die "Failed to create database $db: $!";
# sytem() returns 0 on success => 'and'

my $lsmb_db = LedgerSMB::Database->new(
    connect_data => {
        dbname       => $db,
        user         => $ENV{PGUSER},
        password     => $ENV{PGPASSWORD},
    },
    schema => 'xyz',
    );
my $dbh = $lsmb_db->connect;
die $DBI::errstr if $DBI::errstr;
my $sth = $dbh->prepare(q{SELECT COUNT(*), 'TESTRESULT' from account})
    or die $dbh->errstr;

for my $xmlfile (@files) {
    subtest "$xmlfile" => sub {
        my $company = LedgerSMB::Company->new(dbh => $dbh);
        open my $fh, '<:encoding(utf-8)', $xmlfile
            or die "Unable to open $xmlfile: $!";
        ok( lives { $company->configuration->from_xml($fh); } )
            or diag $@;
        close $fh or warn "Unable to close $xmlfile: $!";

        $sth->execute or die 'Failed to query test result: ' . $sth->errstr;
        my ($count) = $sth->fetchrow_array();
        ok($count, "Got rows back for account, for $xmlfile");
        $dbh->rollback;
    };
}

$sth->finish;
$dbh->rollback;
$dbh->disconnect;

capture {
    system('PERL5OPT="" dropdb', $db);
};

done_testing;
