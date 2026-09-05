#!/usr/bin/perl

use Test2::V0;
use Test2::Plugin::BailOnFail;
use Digest::SHA 'sha512_base64'; #already a dependency
use FindBin;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($OFF);

my $index_file = "doc/adr/index.md";

sub slurp {
    my $phase = shift;
    ok(
        open(my $ih, '<', $index_file),
        "open ADR index.md",
        ) or fail "Failed to open $index_file: $!";

    local $/ = undef;
    my $contents = <$ih>;
    $contents =~ s/^Index Generated:.+?$//mi;
    $contents =~ s/\n//g;
    close $ih or diag("error closing $index_file $!");

    ok($contents, "Got contents from $phase index");
}

my $contents = slurp('original');

my $rc = system('utils/devel/create_adr_index', 'doc/adr/');
$rc and fail "regeneration of adr index failed: $rc";

my $contents2 = slurp('regenerated');

is(sha512_base64($contents2),
   sha512_base64($contents),
   'Contents did not change'
)
or diag "The contents of the ADR index changed.
Please re-run utils/devel/create_adr_index to regenerate the index and commit.";


done_testing;
