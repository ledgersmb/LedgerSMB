#!/usr/bin/perl
#
# Note: This file assumes good dates, SL behaviour with bad dates is undefined
#

#LedgerSMB/Form.pm:3153:sub from_to
#LedgerSMB/Form.pm:1361:sub add_date {

use strict;
use warnings;
use Test::More 'no_plan';
use Math::BigFloat;

use LedgerSMB::Sysconfig;
use LedgerSMB::Form;
use LedgerSMB::Locale;

my $form = new Form;
my $locale_en = LedgerSMB::Locale->get_handle('en');
my $locale_es = LedgerSMB::Locale->get_handle('es');
my %myconfig;
ok(defined $form);
isa_ok($form, 'Form');
$form->{dbh} = ${LedgerSMB::Sysconfig::GLOBALDBH};

my @formats = ( ['mm-dd-yy', '-', 2, '02-29-00', '03-01-00'], 
		['mm/dd/yy', '/', 2, '02/29/00', '03/01/00'],
		['dd-mm-yy', '-', 2, '29-02-00', '01-03-00'], 
		['dd/mm/yy', '/', 2, '29/02/00', '01/03/00'],
		['dd.mm.yy', '.', 2, '29.02.00', '01.03.00'], 
#		['yyyymmdd', '', 4, '20000229', '20000301'],
		['yyyy-mm-dd', '-', 4, '2000-02-29', '2000-03-01']);

my @months = ('January', 'February', 'March', 'April', 'May ', 'June', 
	'July', 'August', 'September', 'October', 'November', 'December');

my $today = `date +\%F`;
chomp $today;
my %today_parts;
$today_parts{'yyyy'} = `date +\%Y`;
$today_parts{'yy'} = $today_parts{'yyyy'};
$today_parts{'yy'} =~ s/^..//;
$today_parts{'mm'} = `date +\%m`;
$today_parts{'dd'} = `date +\%d`;
chomp $today_parts{'yyyy'};
chomp $today_parts{'yy'};
chomp $today_parts{'mm'};
chomp $today_parts{'dd'};

# $locale->date checks
# Note that $locale->date assumes the year range 2000-2099
# Note that $locale->date does not perform language-specific long forms
foreach my $format (0 .. $#formats) {
	%myconfig = (dateformat => $formats[$format][0]);
	my $fmt = $formats[$format][0];
	my $sep = $formats[$format][1];
	my $yearcount = $formats[$format][2];
	my $result = $formats[$format][3];
	$result =~ s/^(.*)(20)?00(.*)$/${1}2000${3}/ if $yearcount == 2;
	cmp_ok($locale_en->date(\%myconfig), 'eq', 
		'', "date, $fmt: empty string");
	cmp_ok($locale_en->date(\%myconfig, $formats[$format][3]), 'eq',
		$result, "date, $fmt: short");
	for my $mm (1 .. 12) {
		my $start = $fmt;
		my $temp = sprintf('%02d', $mm);
		my $month_en = $locale_en->text($months[$mm - 1]);
		my $month_es = $locale_es->text($months[$mm - 1]);
		$start =~ s/dd/29/;
		$start =~ s/yyyy/2000/;
		$start =~ s/yy/00/;
		$start =~ s/mm/$temp/;
		cmp_ok($locale_es->date(\%myconfig, $start, 1), 'eq',
			"$month_es 29 2000", "date, $start, $fmt: long, es");
		cmp_ok($locale_en->date(\%myconfig, $start, 1), 'eq',
			"$month_en 29 2000", "date, $start, $fmt: long, en");
	}
}

# $form->current_date checks
foreach my $format (0 .. $#formats) {
	%myconfig = (dateformat => $formats[$format][0]);
	my $fmt = $formats[$format][0];
	my $sep = $formats[$format][1];
	my $yearcount = $formats[$format][2];
	is($form->current_date(\%myconfig), $today, 
		"current_date, $fmt: $today");
	is($form->current_date(\%myconfig, $formats[$format][3]), 
		'2000-02-29', "current_date, $fmt: 2000-02-29");
	is($form->current_date(\%myconfig, $formats[$format][3], 1), 
		'2000-03-01', "current_date, $fmt: 2000-03-01");
}

# $form->datetonum checks
# Note that $form->datetonum assumes the year range 2000-2099
foreach my $format (0 .. $#formats) {
	%myconfig = (dateformat => $formats[$format][0]);
	my $fmt = $formats[$format][0];
	my $sep = $formats[$format][1];
	my $yearcount = $formats[$format][2];
	cmp_ok($form->datetonum(\%myconfig, $formats[$format][3]), 'eq',
		'20000229', "datetonum, $fmt");
}

# $form->split_date checks
# Note that $form->split_date assumes the year range 2000-2099
# Note that $form->split_date only outputs two digit years
foreach my $format (0 .. $#formats) {
	%myconfig = (dateformat => $formats[$format][0]);
	my $fmt = $formats[$format][0];
	my $sep = $formats[$format][1];
	my $yearcount = $formats[$format][2];
	my @output = $form->split_date($fmt, $formats[$format][3]);
	my $rv = $fmt;
	$rv =~ s/\Q$sep\E//g;
	$rv =~ s/(yy)?yy/$output[1]/;
	$rv =~ s/mm/$output[2]/;
	$rv =~ s/dd/$output[3]/;
	cmp_ok($output[1], 'eq', '00', "split_date specified, year");
	cmp_ok($output[2], 'eq', '02', "split_date specified, month");
	cmp_ok($output[3], 'eq', '29', "split_date specified, day");
	cmp_ok($output[0], 'eq', $rv, "split_date specified, unit");
	@output = $form->split_date($fmt);
	my $rv = $fmt;
	$rv =~ s/\Q$sep\E//g;
	$rv =~ s/(yy)?yy/$output[1]/;
	$rv =~ s/mm/$output[2]/;
	$rv =~ s/dd/$output[3]/;
	my $tv = $fmt;
	$tv =~ s/\Q$sep\E//g;
	$tv =~ s/(yy)?yy/$today_parts{'yy'}/;
	$tv =~ s/mm/$today_parts{'mm'}/;
	$tv =~ s/dd/$today_parts{'dd'}/;
	cmp_ok($output[1], 'eq', $today_parts{'yy'}, 
		"split_date unspecified, year");
	cmp_ok($output[2], 'eq', $today_parts{'mm'}, 
		"split_date unspecified, month");
	cmp_ok($output[3], 'eq', $today_parts{'dd'}, 
		"split_date unspecified, day");
}

# $form->format_date checks
# Note that $form->format_date always outputs four digit years
foreach my $format (0 .. $#formats) {
	$form->{db_dateformat} = $formats[$format][0];
	my $fmt = $formats[$format][0];
	my $sep = $formats[$format][1];
	my $yearcount = $formats[$format][2];
	my $results = $fmt;
	$results =~ s/(yy)?yy/2000/;
	$results =~ s/mm/02/;
	$results =~ s/dd/29/;
	cmp_ok($form->format_date('2000-02-29'), 'eq',
		$results, "format_date, $fmt, ISO");
	cmp_ok($form->format_date($formats[$format][3]), 'eq',
		$formats[$format][3], "format_date, $fmt, non-ISO");
}

