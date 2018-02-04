# Database schema upgrade pre-checks

use strict;
use warnings;

use File::Temp qw( :seekable );
use IO::Scalar;

use Test::More 'no_plan';
use Test::Exception;


use LedgerSMB::Database::PreChecks qw( run_checks load_checks );


#
#
#
#  Tests to assert correct loading of pre-check code
#


my $tests = <<HEREDOC;
package PreCheckTests;

1;

HEREDOC


my $fh = IO::Scalar->new(\$tests);
lives_and(sub { is scalar &load_checks($fh), 0 },
          'Loading empty checks from file-handle');


my $th = File::Temp->new();
print $th $tests;
$th->flush;
lives_and(sub { is scalar &load_checks($th->filename), 0 },
          'Loading empty checks from file');
close $th;


throws_ok(sub { &load_checks('/tmp/non-existant') },
          qr/Schema-upgrade pre-check failed/,
          'Loading from non-existant file fails');



$tests = <<HEREDOC;
package PreCheckTests;

use LedgerSMB::Database::PreChecks;

check 'title',
    description => q|a description|,
    query => q|a query|,
    on_submit => sub { return 1; },
    on_failure => sub { return 1; };

1;
HEREDOC

$fh = IO::Scalar->new(\$tests);
lives_and(sub { is scalar &load_checks($fh), 1 },
          'Loading a single check from file-handle');


