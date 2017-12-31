#!/usr/bin/perl

use Test::More tests => 4;
use Digest::SHA 'sha512_base64'; #already a dependency
use FindBin;

my $sqldir = "$FindBin::Bin/../sql/modules";

ok(open(my $blist, '<', "$sqldir/BLACKLIST"), "open BLACKLIST");
my $contents = join "", map { $a = $_; chomp $a; $a } <$blist>;
close $blist;

ok($contents, "Got contents from original blacklist");

diag `perl $FindBin::Bin/../tools/makeblacklist.pl`;
$? and BAIL_OUT("received non-zero exit from makeblacklist.pl");

open $blist, '<', "$sqldir/BLACKLIST";
my $contents2 = join "", map {  $a = $_; chomp $a; $a } <$blist>;
close $blist;
ok($contents, "Got contents from new blacklist");

is(sha512_base64($contents2), sha512_base64($contents), 'Contents did not change')
or diag " The contents of your blacklisted file changed.  
Please re-run make blacklist so that anyone running this software from 
version control software is protected against sudden errors.";
