#!/usr/bin/perl
# HARNESS-DURATION-SHORT

use strict;
use warnings;

use Test2::V0;

use LedgerSMB;
use Plack::Request;

use LedgerSMB::Sysconfig;
use LedgerSMB::Locale;
LedgerSMB::Sysconfig->initialize;
LedgerSMB::Locale->initialize;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($OFF);


my $lsmb;
my $request = Plack::Request->new({});


##table of subroutine tests
##new
##call_procedure
##merge


$lsmb = LedgerSMB->new($request);
my $utfstr;

ok(defined $lsmb);
isa_ok($lsmb, ['LedgerSMB']);

# $lsmb->escape checks
$lsmb = LedgerSMB->new($request);
$utfstr = "\xd8\xad";
utf8::decode($utfstr);

# $lsmb->new checks
$lsmb = LedgerSMB->new($request);
ok(defined $lsmb, 'new: blank, defined');
isa_ok($lsmb, ['LedgerSMB'], 'new: blank, correct type');
ok(defined $lsmb->{dbversion}, 'new: blank, dbversion defined');
ok(defined $lsmb->{version}, 'new: blank, version defined');

# $lsmb->merge checks
$lsmb = LedgerSMB->new($request);
$lsmb->merge({'apple' => 1, 'pear' => 2, 'peach' => 3}, 'keys' => ['apple', 'pear']);
ok(!defined $lsmb->{peach}, 'merge: Did not add unselected key');
is($lsmb->{apple}, 1, 'merge: Added unselected key apple');
is($lsmb->{pear}, 2, 'merge: Added unselected key pear');

$lsmb = LedgerSMB->new($request);
$lsmb->merge({'apple' => 1, 'pear' => 2, 'peach' => 3});
is($lsmb->{apple}, 1, 'merge: No key, added apple');
is($lsmb->{pear}, 2, 'merge: No key, added pear');
is($lsmb->{peach}, 3, 'merge: No key, added peach');

$lsmb = LedgerSMB->new($request);
$lsmb->merge({'apple' => 1, 'pear' => 2, 'peach' => 3}, 'index' => 1);
is($lsmb->{apple_1}, 1, 'merge: Index 1, added apple as apple_1');
is($lsmb->{pear_1}, 2, 'merge: Index 1, added pear as pear_1');
is($lsmb->{peach_1}, 3, 'merge: Index 1, added peach as peach_1');

done_testing;
