#!/usr/bin/perl

use LedgerSMB::Sysconfig;

use Test::More tests => 3;
use Digest::SHA 'sha512_base64'; #already a dependency
use FindBin;

my $sqldir = "$FindBin::Bin/../sql/modules";
my $tempdir = $LedgerSMB::Sysconfig::tempdir;

open my $blist, '<', "$sqldir/BLACKLIST";
my $contents = join "", map { $a = $_; chomp $a; $a } <$blist>;
close $blist;

ok($contents, "Got contents from original blacklist");

diag `perl $FindBin::Bin/../tools/makeblacklist.pl`;

open $blist, '<', "$tempdir/BLACKLIST";
my $contents2 = join "", map {  $a = $_; chomp $a; $a } <$blist>;
close $blist;
ok($contents, "Got contents from new blacklist");

is(sha512_base64($contents2), sha512_base64($contents), 'Contents did not change')
or diag " The contents of your blacklisted file changed.  
Please re-run make blacklist so that anyone running this software from 
version control software is protected against sudden errors.";
