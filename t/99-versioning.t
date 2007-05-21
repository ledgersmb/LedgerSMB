#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 9;

use LedgerSMB::Form;

my $form = new Form;
ok(defined $form, 'form: defined');
isa_ok($form, 'Form', 'form: correct type');
ok(defined $form->{version}, 'form: version set');
ok(defined $form->{dbversion}, 'form: dbversion set');
$form->{version} =~ s/\s//g;
$form->{dbversion} =~ s/\s//g;

ok(-e 'VERSION', 'VERSION exists');
ok(-s 'VERSION', 'VERSION non-empty');
ok(-r 'VERSION', 'VERSION readable');
open(my $FH, '<', 'VERSION');
my $ver = readline $FH;
close $FH;
chomp $ver;
$ver =~ s/\s//g;
is($form->{version}, $ver, 'Form version matches VERSION');

SKIP: {
	skip 'Form is trunk', 1 if $form->{version} =~ /trunk$/i;
	cmp_ok($form->{version}, 'ge', $form->{dbversion}, 
		'form: version >= dbversion');
}
