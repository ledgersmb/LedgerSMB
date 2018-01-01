#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;
use Test::Trap qw(trap $trap);
use Math::BigFloat;

use LedgerSMB::Sysconfig;
use LedgerSMB;
use LedgerSMB::App_State;
use Log::Log4perl;
Log::Log4perl::init(\$LedgerSMB::Sysconfig::log4perl_config);


my $lsmb;


sub redirect {
        print "redirected\n";
}

sub lsmb_error_func {
        print $_[0];
}

##table of subroutine tests
##new
##call_procedure
##merge


$lsmb = LedgerSMB->new();
my $utfstr;
my @r;

ok(defined $lsmb);
isa_ok($lsmb, 'LedgerSMB');

# $lsmb->escape checks
$lsmb = LedgerSMB->new();
$utfstr = "\xd8\xad";
utf8::decode($utfstr);

# $lsmb->new checks
$lsmb = LedgerSMB->new();
ok(defined $lsmb, 'new: blank, defined');
isa_ok($lsmb, 'LedgerSMB', 'new: blank, correct type');
ok(defined $lsmb->{dbversion}, 'new: blank, dbversion defined');
ok(defined $lsmb->{version}, 'new: blank, version defined');

# $lsmb->call_procedure checks
SKIP: {
        skip 'Skipping call_procedure tests, no db specified', 5
                if !defined $ENV{PGDATABASE};
        $lsmb = LedgerSMB->new();
        my $pghost = "";
        $pghost = ";host=" . $ENV{PGHOST}
            if $ENV{PGHOST} && $ENV{PGHOST} ne 'localhost';
        $lsmb->{dbh} = DBI->connect("dbi:Pg:dbname=$ENV{PGDATABASE}$pghost",
                undef, undef, {AutoCommit => 0 });
        ok($lsmb->{dbh},"Connected to $ENV{PGDATABASE}");
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
}

# $lsmb->merge checks
$lsmb = LedgerSMB->new();
$lsmb->merge({'apple' => 1, 'pear' => 2, 'peach' => 3}, 'keys' => ['apple', 'pear']);
ok(!defined $lsmb->{peach}, 'merge: Did not add unselected key');
is($lsmb->{apple}, 1, 'merge: Added unselected key apple');
is($lsmb->{pear}, 2, 'merge: Added unselected key pear');

$lsmb = LedgerSMB->new();
$lsmb->merge({'apple' => 1, 'pear' => 2, 'peach' => 3});
is($lsmb->{apple}, 1, 'merge: No key, added apple');
is($lsmb->{pear}, 2, 'merge: No key, added pear');
is($lsmb->{peach}, 3, 'merge: No key, added peach');

$lsmb = LedgerSMB->new();
$lsmb->merge({'apple' => 1, 'pear' => 2, 'peach' => 3}, 'index' => 1);
is($lsmb->{apple_1}, 1, 'merge: Index 1, added apple as apple_1');
is($lsmb->{pear_1}, 2, 'merge: Index 1, added pear as pear_1');
is($lsmb->{peach_1}, 3, 'merge: Index 1, added peach as peach_1');
