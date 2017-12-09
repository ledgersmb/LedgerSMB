#!/usr/bin/perl

use LedgerSMB::Sysconfig;

use Test::More tests => 3;
use Digest::SHA 'sha512_base64'; #already a dependency
use FindBin;

my $sqldir = "$FindBin::Bin/../sql/modules";

open my $blist, '<', "$sqldir/BLACKLIST";
local $/ = undef;
my $contents = <$blist>;
$contents =~ s/\n//g;
close $blist;

ok($contents, "Got contents from original blacklist");

my $contents2 = `perl $FindBin::Bin/../tools/makeblacklist.pl`;
$contents2 =~ s/\n//g;
ok($contents2, "Got contents from new blacklist");

is(sha512_base64($contents2),
   sha512_base64($contents),
   'Contents did not change'
)
or diag " The contents of your blacklisted file changed.
Please re-run make blacklist so that anyone running this software from
version control software is protected against sudden errors.";
