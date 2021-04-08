#!/usr/bin/perl
# HARNESS-DURATION-SHORT

use strict;
use warnings;

use Test2::V0;
use Math::BigFloat;

use LedgerSMB;
use LedgerSMB::Locale;
use LedgerSMB::Sysconfig;
use Plack::Request;

use Log::Log4perl qw(:easy);

LedgerSMB::Sysconfig->initialize;
LedgerSMB::Locale->initialize;
Log::Log4perl->easy_init($OFF);

my $request = Plack::Request->new({});

my $lsmb = LedgerSMB->new($request);
my @r;

ok(defined $lsmb);
isa_ok($lsmb, ['LedgerSMB']);

my $pgdatabase = $ENV{LSMB_NEW_DB} // $ENV{PGDATABASE} // '';
my $pghost = "";
$pghost = ";host=" . $ENV{PGHOST}
        if $ENV{PGHOST} && $ENV{PGHOST} ne 'localhost';
$lsmb->{dbh} = DBI->connect("dbi:Pg:dbname=$pgdatabase$pghost",
        undef, undef, {AutoCommit => 0 });
ok($lsmb->{dbh},"Connected to $pgdatabase");
LedgerSMB::App_State::set_DBH($lsmb->{dbh});
@r = $lsmb->call_procedure('procname' => 'character_length',
        'funcschema' => 'pg_catalog',
        'args' => ['month']);
is($#r, 0, 'call_procedure: correct return length (one row)');
is($r[0]->{'character_length'}, 5,
        'call_procedure: single arg, non-numeric return');

@r = $lsmb->call_procedure('procname' => 'trunc',
        'funcschema' => 'pg_catalog',
        'args' => [57.1, 0]);
is($r[0]->{'trunc'}, Math::BigFloat->new('57'),
        'call_procedure: two args, numeric return');

@r = $lsmb->call_procedure('procname' => 'pi',
        'funcschema' => 'pg_catalog',
        'args' => []);
like($r[0]->{'pi'}, qr/^3.14/,
        'call_procedure: empty arg list, non-numeric return');
@r = $lsmb->call_procedure('procname' => 'pi',
        'funcschema' => 'pg_catalog');
like($r[0]->{'pi'}, qr/^3.14/,
        'call_procedure: no args, non-numeric return');
$lsmb->{dbh}->rollback();
$lsmb->{dbh}->disconnect;

done_testing;
