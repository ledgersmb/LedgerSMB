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

my @dparts;
my @lparts;
my $age;
SKIP: {
	skip 'LedgerSMB is trunk', 1 if $lsmb->{version} =~ /trunk$/i;
	@dparts = split /\./, $lsmb->{dbversion};
	@lparts = split /\./, $lsmb->{version};
	$age = 0;
	foreach my $dpart (@dparts) {
		my $lpart = shift @lparts;
		if (!defined $lpart) {
			$age = 1;
			last;
		} elsif ($lpart > $dpart) {
			last;
		} elsif ($dpart > $lpart) {
			$age = 1;
			last;
		}
	}
	ok($age == 0, 'lsmb: version >= dbversion');
}
SKIP: {
	skip 'Form is trunk', 1 if $form->{version} =~ /trunk$/i;
	@dparts = split /\./, $form->{dbversion};
	@lparts = split /\./, $form->{version};
	$age = 0;
	foreach my $dpart (@dparts) {
		my $lpart = shift @lparts;
		if (!defined $lpart) {
			$age = 1;
			last;
		} elsif ($lpart > $dpart) {
			last;
		} elsif ($dpart > $lpart) {
			$age = 1;
			last;
		}
	}
	ok($age == 0, 'form: version >= dbversion');
}
