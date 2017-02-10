use Test::More;
use Test::ParallelSubtest;
use File::Find::Rule;
use strict;
use warnings;

my @missing = grep { ! $ENV{$_} } (qw(LSMB_NEW_DB COA_TESTING LSMB_TEST_DB));
plan skip_all => (join ', ', @missing) . ' not set' if @missing;

my $rule = File::Find::Rule->new;
$rule->or($rule->new
               ->directory
               ->name(qr(gifi|sic))
               ->prune
               ->discard,
          $rule->new);
my @files = sort $rule->name("*.sql")->file->in("sql/coa");

for my $sqlfile (@files) {

    bg_subtest "$sqlfile" => sub {
        local $!;

        my ($_1,$dir,$type,$name) = $sqlfile =~ qr(sql\/coa\/(([a-z]{2})\/)?(.+\/)?([^\/\.]+)\.sql$);
        $type //= "";

        my $test_db = "$ENV{LSMB_NEW_DB}_lsmb_test_coa";
        $test_db .= "_${dir}" if $dir;
        $test_db .= "_${name}";

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
}


ok(1,"coaload done");

done_testing;
