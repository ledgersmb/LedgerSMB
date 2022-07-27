#!/usr/bin/perl

use strict;
use warnings;

use Test2::V0;
use Math::BigFloat;

use Beam::Wire;
use Log::Log4perl qw(:easy);
use Plack::Request;

use LedgerSMB;
use LedgerSMB::Locale;
use LedgerSMB::PGNumber;


my $wire = Beam::Wire->new(file => 't/ledgersmb.yaml');
LedgerSMB::Locale->initialize($wire);
Log::Log4perl->easy_init($OFF);

$wire = Beam::Wire->new(
    config => {
        default_locale => {
            class => 'LedgerSMB::LanguageResolver',
            args => {
                directory => './locale/po/',
            },
        }
    });
my $request = Plack::Request->new({});

my $lsmb = LedgerSMB->new($request, $wire);
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
