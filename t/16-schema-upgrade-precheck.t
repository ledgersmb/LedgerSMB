# Database schema upgrade pre-checks

use strict;
use warnings;

use File::Temp qw( :seekable );
use IO::Scalar;

use Test::More 'no_plan';
use Test::Exception;


use LedgerSMB::Database::ChangeChecks qw( run_checks load_checks );


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

use LedgerSMB::Database::ChangeChecks;

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



$tests = <<HEREDOC;
package PreCheckTests;

use LedgerSMB::Database::ChangeChecks;

check 'title1',
    description => q|a description|,
    query => q|a query|,
    on_submit => sub { return 1; },
    on_failure => sub { return 1; };


check 'title2',
    description => q|a description|,
    query => q|a query|,
    on_submit => sub { return 1; },
    on_failure => sub { return 1; };


1;
HEREDOC

$fh = IO::Scalar->new(\$tests);
lives_and(sub { is scalar &load_checks($fh), 2 },
          'Loading a two checks from file-handle');


###TODO: Do we need to validate that the checks have unique names?!


#
#
#
#  Tests to assert correct requiring of required arguments
#

$tests = <<HEREDOC;
package PreCheckTests;

use LedgerSMB::Database::ChangeChecks;

check 'title',
    query => q|a query|,
    on_submit => sub { return 1; },
    on_failure => sub { return 1; };

1;
HEREDOC

$fh = IO::Scalar->new(\$tests);
throws_ok(sub { &load_checks($fh) }, qr/doesn't define a description/,
    '"check" keyword bails without a description');


$tests = <<HEREDOC;
package PreCheckTests;

use LedgerSMB::Database::ChangeChecks;

check 'title',
    description => q|a description|,
    on_submit => sub { return 1; },
    on_failure => sub { return 1; };

1;
HEREDOC

$fh = IO::Scalar->new(\$tests);
throws_ok(sub { &load_checks($fh) }, qr/doesn't define a query/,
    '"check" keyword bails without a query');



$tests = <<HEREDOC;
package PreCheckTests;

use LedgerSMB::Database::ChangeChecks;

check 'title',
    description => q|a description|,
    query => q|a query|,
    on_failure => sub { return 1; };

1;
HEREDOC

$fh = IO::Scalar->new(\$tests);
throws_ok(sub { &load_checks($fh) }, qr/doesn't define 'on_submit'/,
    '"check" keyword bails without an "on_submit"');


$tests = <<HEREDOC;
package PreCheckTests;

use LedgerSMB::Database::ChangeChecks;

check 'title',
    description => q|a description|,
    query => q|a query|,
    on_submit => sub { return 1; };


1;
HEREDOC

$fh = IO::Scalar->new(\$tests);
throws_ok(sub { &load_checks($fh) }, qr/doesn't define 'on_failure'/,
    '"check" keyword bails without an "on_failure"');


#
#
#
#  Tests to assert that multiple checks can be defined in a single file
#


