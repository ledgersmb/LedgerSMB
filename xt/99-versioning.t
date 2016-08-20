#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 12;

use LedgerSMB;
use LedgerSMB::Form;
use LedgerSMB::App_State;
use Log::Log4perl;
Log::Log4perl::init(\$LedgerSMB::Sysconfig::log4perl_config);

$ENV{REQUEST_METHOD} = 'GET';
     # Suppress warnings from LedgerSMB::_process_cookies




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

my @dparts;
my @lparts;
my $age;
SKIP: {
	skip 'LedgerSMB is trunk', 1 if $lsmb->{version} =~ /trunk$/i;
        $lsmb->{version} =~ s/(\d+\.\d+\.\d+)\D.*/$1/;
        $lsmb->{dbversion} =~ s/(\d+\.\d+\.\d+)\D.*/$1/;
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
        $form->{version} =~ s/(\d+\.\d+\.\d+)\D.*/$1/;
        $form->{dbversion} =~ s/(\d+\.\d+\.\d+)\D.*/$1/;
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
