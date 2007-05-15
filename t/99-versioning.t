#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 17;

use LedgerSMB;
use LedgerSMB::Form;

my $lsmb = new LedgerSMB;
ok(defined $lsmb, 'lsmb: defined');
isa_ok($lsmb, 'LedgerSMB', 'lsmb: correct type');
ok(defined $lsmb->{version}, 'lsmb: version set');
ok(defined $lsmb->{dbversion}, 'lsmb: dbversion set');

my $form = new Form;
ok(defined $form, 'form: defined');
isa_ok($form, 'Form', 'form: correct type');
ok(defined $form->{version}, 'form: version set');
ok(defined $form->{dbversion}, 'form: dbversion set');

is($lsmb->{version}, $form->{version}, 'LedgerSMB and Form versions match');
is($lsmb->{dbversion}, $form->{dbversion}, 'LedgerSMB and Form dbversions match');

ok(-e 'VERSION', 'VERSION exists');
ok(-s 'VERSION', 'VERSION non-empty');
ok(-r 'VERSION', 'VERSION readable');
open(my $FH, '<', 'VERSION');
my $ver = readline $FH;
close $FH;
chomp $ver;
is($lsmb->{version}, $ver, 'LedgerSMB version matches VERSION');
is($form->{version}, $ver, 'Form version matches VERSION');

SKIP: {
	skip 'LedgerSMB is trunk', 1 if $lsmb->{version} =~ /trunk$/i;
	cmp_ok($lsmb->{version}, '>=', $lsmb->{dbversion}, 
		'lsmb: version >= dbversion');
}
SKIP: {
	skip 'Form is trunk', 1 if $form->{version} =~ /trunk$/i;
	cmp_ok($form->{version}, '>=', $form->{dbversion}, 
		'form: version >= dbversion');
}
