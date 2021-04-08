#!/usr/bin/perl
# HARNESS-DURATION-SHORT

use Test2::V0;

use LedgerSMB::Locale;
use LedgerSMB::Num2text;
use LedgerSMB::PGNumber;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($OFF);

use LedgerSMB::Sysconfig;
LedgerSMB::Sysconfig->initialize;
LedgerSMB::Locale->initialize;

my %english = (
    0 => 'Zero',
    1 => 'One',
   11 => 'Eleven',
   15 => 'Fifteen',
   30 => 'Thirty',
   39 => 'Thirty Nine',
   48 => 'Forty Eight',
   57 => 'Fifty Seven',
  101 => 'One Hundred One',
  166 => 'One Hundred Sixty Six',
 1100 => 'One Thousand One Hundred',
 1455 => 'One Thousand Four Hundred Fifty Five'
);

my $en = LedgerSMB::Num2text->new(LedgerSMB::Locale->get_handle('en'));
$en->init;
is($en->num2text($_, 1) , $english{$_}, "$_ -> $english{$_}, Plain") for keys %english;


done_testing;
