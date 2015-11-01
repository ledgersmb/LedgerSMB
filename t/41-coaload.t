use Test::More;
use strict;
use warnings;

my @missing = grep { ! $ENV{$_} } (qw(LSMB_NEW_DB COA_TESTING LSMB_TEST_DB));
plan skip_all => (join ', ', @missing) . ' not set' if @missing;

open FILES, '<', 't/data/41-coaload.t';
my @files = grep { /^[^#]/ } <FILES>;
close FILES;

my $test_db = "$ENV{LSMB_NEW_DB}_lsmb_test_coa";

for my $sqlfile(@files){
    local $!;
    $! = undef; # reset if drop failed
    system("dropdb '$test_db' 2>/dev/null");
    system("createdb '$test_db' -T '$ENV{LSMB_NEW_DB}'");
    ok(! $!, "DB created for $sqlfile testing");
    system("psql $test_db -f $sqlfile");
    ok(! $!, "psql run file succeeded");
    my $returnstring = `psql '$test_db' -c "SELECT COUNT(*), 'TESTRESULT' from account"`;
    my ($testval) = grep { /TESTRESULT/ } split("\n", $returnstring);
    $testval =~ s/\D//g;
    ok($testval, "Got rows back for account, for $sqlfile");
    system("dropdb '$test_db'");
}



done_testing;
