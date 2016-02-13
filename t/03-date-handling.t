#!/usr/bin/perl
#
# Note: This file assumes good dates, SL behaviour with bad dates is undefined
#

use strict;
use warnings;
use Test::More 'no_plan';
use Math::BigFloat;

use LedgerSMB::Sysconfig;
use LedgerSMB;
use LedgerSMB::Form;
use LedgerSMB::Locale;
use LedgerSMB::App_State;
use Log::Log4perl;
Log::Log4perl::init(\$LedgerSMB::Sysconfig::log4perl_config);


$ENV{REQUEST_METHOD} = 'GET';
     # Suppress warnings from LedgerSMB::_process_cookies


my $form = new Form;
my $locale_en = LedgerSMB::Locale->get_handle('en_CA');
my $locale_es = LedgerSMB::Locale->get_handle('es');
my %myconfig;
ok(defined $form);
isa_ok($form, 'Form');
my $lsmb = new LedgerSMB;
ok(defined $lsmb);
isa_ok($lsmb, 'LedgerSMB');

my @formats = ( ['mm-dd-yy', '-', 2, '02-29-00', '03-01-00'],
		['mm/dd/yy', '/', 2, '02/29/00', '03/01/00'],
		['dd-mm-yy', '-', 2, '29-02-00', '01-03-00'],
		['dd/mm/yy', '/', 2, '29/02/00', '01/03/00'],
		['dd.mm.yy', '.', 2, '29.02.00', '01.03.00'],
#		['yyyymmdd', '', 4, '20000229', '20000301'],
		['yyyy-mm-dd', '-', 4, '2000-02-29', '2000-03-01']);

my @months = ('January', 'February', 'March', 'April', 'May ', 'June',
	'July', 'August', 'September', 'October', 'November', 'December');

my @mon = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
	'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');

my %month_num = ('01' => '31', '02' => '28', '03' => '31', '04' => '30',
		 '05' => '31', '06' => '30', '07' => '31', '08' => '31',
		 '09' => '30', '10' => '31', '11' => '30', '12' => '31');

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
# Note that $locale->date also takes in yyyymmdd
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
	cmp_ok($locale_en->date(\%myconfig, '20000229'), 'eq',
		$result, "date, $fmt: chopped");
	for my $mm (1 .. 12) {
		my $start = $fmt;
		my $temp = sprintf('%02d', $mm);
		my $month_en = $locale_en->text($months[$mm - 1]);
		my $month_en_2 = $locale_en->text($mon[$mm - 1]);
		my $month_es = $locale_es->text($months[$mm - 1]);
		$start =~ s/dd/29/;
		$start =~ s/yyyy/2000/;
		$start =~ s/yy/00/;
		$start =~ s/mm/$temp/;
		cmp_ok($locale_es->date(\%myconfig, $start, 1), 'eq',
			"$month_es 29 2000", "date, $start, $fmt: long, es");
		cmp_ok($locale_en->date(\%myconfig, $start, 1), 'eq',
			"$month_en 29 2000", "date, $start, $fmt: long, en");
		cmp_ok($locale_en->date(\%myconfig, $start, ''), 'eq',
			"$month_en_2 29 2000", "date, $start, $fmt: '', en") if
			$start !~ /^\d{4}\D/; # Ack... special case
	}
	cmp_ok($locale_en->date(\%myconfig, '2007-05-18', ''), 'eq',
		"2007-05-18", "date, 2007-05-18, $fmt: '', en");
}

foreach my $format (0 .. $#formats) {
	%myconfig = (dateformat => $formats[$format][0]);
	my $fmt = $formats[$format][0];
	my $sep = $formats[$format][1];
	my $yearcount = $formats[$format][2];
	cmp_ok($form->datetonum(\%myconfig, $formats[$format][3]), 'eq',
		'20000229', "form: datetonum, $fmt");
}
cmp_ok($form->datetonum(\%myconfig), 'eq', '', "form: datetonum, empty string");
cmp_ok($form->datetonum(\%myconfig, '1234'), 'eq', '1234',
	"form: datetonum, 1234");

# $form->split_date checks
# Note that $form->split_date assumes the year range 2000-2099
# Note that $form->split_date only outputs two digit years
# Note that $form->split_date if a date provided without non-digit, identity
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
	$rv = $fmt;
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
	@output = $form->split_date($fmt, '12345');
	cmp_ok($output[0], 'eq', '12345',
		'split_date, 12345');
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

# $form->from_to checks
# Note that $form->from_to requires $form->format_date
# Note that $form->from_to outputs four digit years
# Note that $form->from_to outputs 1999-12-31 (formatted) if no input given
# Note that $form->from_to outputs the last day of the previous year if only year given
# Note that $form->from_to outputs the last day of the chosen month if month given
# Note that $form->from_to $interval of 0 is current day
# Note that $form->from_to $interval is an integral quantity of months
# Note that $form->from_to will fail if ($interval + $month) > 22
# (2 + 23), 25 - 12, 13 - 1, 12
foreach my $format (0 .. $#formats) {
	$form->{db_dateformat} = $formats[$format][0];
	my $fmt = 'yyyy-mm-dd';
	my $sep = '-';
	my $yearcount = $formats[$format][2];
	my $results = $fmt;
	$results =~ s/(yy)?yy/1999/;
	$results =~ s/mm/12/;
	$results =~ s/dd/31/;
	cmp_ok($form->from_to(), 'eq',
		$results, "from_to, $fmt, unspecified");
	$results =~ s/1999/2006/;
	cmp_ok($form->from_to('07'), 'eq',
		$results, "from_to, $fmt, 07");
	cmp_ok($form->from_to('2007'), 'eq',
		$results, "from_to, $fmt, 2007");
	$results =~ s/2006/2007/;
	$results =~ s/12/05/;
	cmp_ok($form->from_to('07', '05'), 'eq',
		$results, "from_to, $fmt, 07-05");
	cmp_ok($form->from_to('2007', '05'), 'eq',
		$results, "from_to, $fmt, 2007-05");
	$results =~ s/05/02/;
	$results =~ s/31/28/;
	cmp_ok($form->from_to('07', '02'), 'eq',
		$results, "from_to, $fmt, 07-02");
	cmp_ok($form->from_to('2007', '02'), 'eq',
		$results, "from_to, $fmt, 2007-02");
	$results =~ s/2007/2000/;
	$results =~ s/28/29/;
	cmp_ok($form->from_to('00', '02'), 'eq',
		$results, "from_to, $fmt, 00-02 leap day");
	cmp_ok($form->from_to('2000', '02'), 'eq',
		$results, "from_to, $fmt, 2000-02 leap day");
	$results =~ s/29/31/;
	$results =~ s/02/01/;
	cmp_ok($form->from_to('00', '01'), 'eq',
		$results, "from_to, $fmt, 00-01 year edge");
	cmp_ok($form->from_to('2000', '01'), 'eq',
		$results, "from_to, $fmt, 2000-01 year edge");
	$results =~ s/01/12/;
	cmp_ok($form->from_to('00', '12'), 'eq',
		$results, "from_to, $fmt, 00-12 year edge");
	cmp_ok($form->from_to('2000', '12'), 'eq',
		$results, "from_to, $fmt, 2000-12 year edge");
	$results =~ s/12/02/;
	$results =~ s/31/29/;
	cmp_ok($form->from_to('00', '02', '1'), 'eq',
		$results, "from_to, $fmt, 00-02, 1 interval");
	cmp_ok($form->from_to('2000', '02', '1'), 'eq',
		$results, "from_to, $fmt, 2000-02, 1 interval");
	$results =~ s/29/28/;
	my $month;
	my $lastmonth;
	for (2 .. 11) {
		$month = sprintf '%02d', $_ + 1;
		$lastmonth = sprintf '%02d', $_;
		$results =~ s/$lastmonth/$month/;
		$results =~ s/$month_num{$lastmonth}/$month_num{$month}/;
		cmp_ok($form->from_to('00', '02', $_), 'eq',
			$results, "from_to, $fmt, 00-02, $_ interval");
		cmp_ok($form->from_to('2000', '02', $_), 'eq',
			$results, "from_to, $fmt, 2000-02, $_ interval");
	}
	$results =~ s/2000/2001/;
	for (0 .. 10) {
		$month = sprintf '%02d', $_ + 1;
		$lastmonth = sprintf '%02d', $_;
		$lastmonth = '12' if $lastmonth eq '00';
		$results =~ s/([^0])$lastmonth/${1}$month/;
		$results =~ s/^$lastmonth/$month/;
		$results =~ s/$month_num{$lastmonth}/$month_num{$month}/;
		cmp_ok($form->from_to('00', '02', $_ + 12), 'eq',
			$results, "from_to, $fmt, 00-02, $_ + 12 interval");
		cmp_ok($form->from_to('2000', '02', $_ + 12), 'eq',
			$results, "from_to, $fmt, 2000-02, $_ + 12 interval");
	}
	$results =~ s/11/$today_parts{'mm'}/;
	$results =~ s/30/$today_parts{'dd'}/;
	$results =~ s/2001/$today_parts{'yyyy'}/;
	cmp_ok($form->from_to('00', '02', '0'), 'eq',
		$results, "from_to, $fmt, 00-02, 0 interval (today)");
	cmp_ok($form->from_to('2000', '02', '0'), 'eq',
		$results, "from_to, $fmt, 2000-02, 0 interval (today)");
}

# $form->add_date checks
# returns undef if no date passed
# valid units: days, weeks, months, years
# all uses in LSMB use days unit
# has no error handling capabilities
foreach my $format (0 .. $#formats) {
	$form->{db_dateformat} = $formats[$format][0];
	%myconfig = (dateformat => $formats[$format][0]);
	my $fmt = $formats[$format][0];
	my $sep = $formats[$format][1];
	my $yearcount = $formats[$format][2];
	my $start = $fmt;
	$start =~ s/(yy)?yy/2000/;
	$start =~ s/mm/01/;
	$start =~ s/dd/29/;
	my $results = $start;
	$results =~ s/29/30/;
	cmp_ok($form->add_date(\%myconfig, $start, 1, 'days'), 'eq',
		$results, "add_date, $fmt, 1 days, 2000-01-29");
	$results =~ s/30/31/;
	cmp_ok($form->add_date(\%myconfig, $start, 2, 'days'), 'eq',
		$results, "add_date, $fmt, 2 days, 2000-01-29");
	$results =~ s/31/05/;
	$results =~ s/01/02/;
	cmp_ok($form->add_date(\%myconfig, $start, 1, 'weeks'), 'eq',
		$results, "add_date, $fmt, 1 weeks, 2000-01-29");
	$results =~ s/05/12/;
	cmp_ok($form->add_date(\%myconfig, $start, 2, 'weeks'), 'eq',
		$results, "add_date, $fmt, 2 weeks, 2000-01-29");
	$results =~ s/12/29/;
	cmp_ok($form->add_date(\%myconfig, $start, 1, 'months'), 'eq',
		$results, "add_date, $fmt, 1 months, 2000-01-29");
	$results =~ s/02/03/;
	cmp_ok($form->add_date(\%myconfig, $start, 2, 'months'), 'eq',
		$results, "add_date, $fmt, 2 months, 2000-01-29");
	$results = $start;
	$results =~ s/01/11/;
	cmp_ok($form->add_date(\%myconfig, $start, 10, 'months'), 'eq',
		$results, "add_date, $fmt, 10 months, 2000-01-29");
	$results = $start;
	$results =~ s/01/12/;
	cmp_ok($form->add_date(\%myconfig, $start, 11, 'months'), 'eq',
		$results, "add_date, $fmt, 11 months, 2000-01-29");
	$results = $start;
	$results =~ s/2000/2001/;
	cmp_ok($form->add_date(\%myconfig, $start, 12, 'months'), 'eq',
		$results, "add_date, $fmt, 12 months, 2000-01-29");
	cmp_ok($form->add_date(\%myconfig, $start, 1, 'years'), 'eq',
		$results, "add_date, $fmt, 1 years, 2000-01-29");
	$results =~ s/2001/2002/;
	cmp_ok($form->add_date(\%myconfig, $start, 2, 'years'), 'eq',
		$results, "add_date, $fmt, 2 years, 2000-01-29");
}
cmp_ok($form->add_date(\%myconfig, '20000129', 2, 'years'), 'eq',
	'20020129', 'add_date, yyyymmdd, 2 years, 20000129');
ok(!defined $form->add_date(\%myconfig),
	'add_date, undef if no date');
