#!/usr/bin/perl

use LedgerSMB::Sysconfig;

use Test2::V0;
use Test2::Plugin::BailOnFail;
use Digest::SHA 'sha512_base64'; #already a dependency
use FindBin;

my $sqldir = "$FindBin::Bin/../sql/modules";
my $blacklist_file = "$sqldir/BLACKLIST";

ok(
    open(my $blist, '<', $blacklist_file),
    "open BLACKLIST",
) or fail "Failed to open $blacklist_file $!";

local $/ = undef;
my $contents = <$blist>;
$contents =~ s/\n//g;
close $blist or diag("error closing $blacklist_file $!");

ok($contents, "Got contents from original blacklist");

my $contents2 = `perl -Ilib $FindBin::Bin/../utils/test/makeblacklist.pl`;
$? and fail 'makeblacklist.pl gave non-zero exit code';

$contents2 =~ s/\n//g;
ok($contents2, "Got contents from new blacklist");

is(sha512_base64($contents2),
   sha512_base64($contents),
   'Contents did not change'
)
or diag " The contents of your blacklisted file changed.
Please re-run make blacklist so that anyone running this software from
version control software is protected against sudden errors.";

done_testing;
