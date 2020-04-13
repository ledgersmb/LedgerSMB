#!/usr/bin/perl
#
# Note: This file assumes good dates, SL behaviour with bad dates is undefined
#

use strict;
use warnings;
use Test2::V0;
use Math::BigFloat;

use LedgerSMB::Sysconfig;
use LedgerSMB;
use LedgerSMB::Form;
use LedgerSMB::Locale;
use LedgerSMB::App_State;
use Plack::Request;

use Log::Log4perl qw( :easy );
Log::Log4perl->easy_init($OFF);


$ENV{REQUEST_METHOD} = 'GET';
     # Suppress warnings from LedgerSMB::_process_cookies


my $form = Form->new;
my $locale_en = LedgerSMB::Locale->get_handle('en_CA');
my $locale_es = LedgerSMB::Locale->get_handle('es');
my %myconfig;
ok(defined $form);
isa_ok($form, 'Form');
my $request = Plack::Request->new({});
my $lsmb = LedgerSMB->new($request);
ok(defined $lsmb);
isa_ok($lsmb, 'LedgerSMB');

my @formats = (['yyyy-mm-dd', '-', 4, '2000-02-29', '2000-03-01']);

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
$today_parts{'mm'} = `date +\%m`;
$today_parts{'dd'} = `date +\%d`;
chomp $today_parts{'yyyy'};
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
                my $month_en = $locale_en->maketext($months[$mm - 1]);
                my $month_en_2 = $locale_en->maketext($mon[$mm - 1]);
                my $month_es = $locale_es->maketext($months[$mm - 1]);
                $start =~ s/dd/29/;
                $start =~ s/yyyy/2000/;
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
        $start =~ s/yyyy/2000/;
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


use LedgerSMB::PGDate;

# there are 4 requirements to PGDate that we can verify here:
is(LedgerSMB::PGDate->from_input('')->to_output, '',
   'round-tripping empty string returns empty string');
is(LedgerSMB::PGDate->from_input(undef)->to_output, '',
   'round-tripping "undef" returns an empty string (for easy concatenation)');
is(LedgerSMB::PGDate->from_input('2016-01-01')->to_output, '2016-01-01',
   'round-tripping valid ISO-8601 date returns that date');

foreach my $test (
    {
        format => 'dd/mm/yyyy',
        date => '29/10/2016',
    },
    {
        format => 'dd.mm.yyyy',
        date => '29.10.2016',
    },
    {
        format => 'dd-mm-yyyy',
        date => '29-10-2016',
    },
    {
        format => 'ddmmyyyy',
        date => '29102016',
    },
    {
        format => 'mm/dd/yyyy',
        date => '10/29/2016',
    },
    {
        format => 'mm.dd.yyyy',
        date => '10.29.2016',
    },
    {
        format => 'mm-dd-yyyy',
        date => '10-29-2016',
    },
    {
        format => 'mmddyyyy',
        date => '10292016',
    },
    {
        format => 'yyyymmdd',
        date => '20161029',
    },
) {
   $LedgerSMB::App_State::User = { dateformat => $test->{format} };
   is(eval { LedgerSMB::PGDate->from_input($test->{date})->to_output },
      $test->{date},
      "round-tripping valid '$test->{format}' date returns that date");
}


done_testing;
