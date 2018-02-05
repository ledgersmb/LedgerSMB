# Database schema upgrade pre-checks

use strict;
use warnings;

use DBI;
use File::Temp qw( :seekable );
use IO::Scalar;

use Test::More 'no_plan';
use Test::Exception;


use LedgerSMB::Database::ChangeChecks qw( :DEFAULT run_with_formatters
       run_checks load_checks );


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
close $th or die "Failed to close empty test file: $!";


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
#  Tests to assert successfully detecting failure and successful completion
#

# create a fake database handle...
my $dbh = DBI->connect('DBI:Mock:', '', '');


#
# Single succeeding scenario

$dbh->{mock_add_resultset} = {
    sql     => 'something',
    results => [
        [ 'headers' ],
        ],
};

lives_and( sub {
    is &run_checks( $dbh,
                    checks => [
                        {
                            query => 'something',
                            on_failure => sub { die 'on_failure called?!' },
                        },
                    ]
        ), 1
    }, 'single completed check');



#
# Multiple succeeding scenarios

$dbh->{mock_add_resultset} = {
    sql     => 'something',
    results => [
        [ 'headers' ],
        ],
};
$dbh->{mock_add_resultset} = {
    sql     => 'something else',
    results => [
        [ 'headers' ],
        ],
};

lives_and( sub {
    is &run_checks( $dbh,
                    checks => [
                        {
                            query => 'something',
                            on_failure =>
                                sub { die 'on_failure called?!' },
                        },
                        {
                            query => 'something else',
                            on_failure =>
                                sub { die 'on_failure (2) called?!' },
                        },
                    ]
        ), 1
           }, 'multiple completed checks');


#
# Single failing scenario

$dbh->{mock_add_resultset} = {
    sql     => 'something',
    results => [
        [ 'headers' ],
        [ 'failing row' ],
        ],
};

my $result = undef;

lives_and( sub {
    is &run_checks( $dbh,
                    checks => [
                        {
                            query => 'something',
                            on_failure => sub { $result = 'called'; },
                        },
                    ]
        ), 0
    }, 'single failed check: indicates failure');

is $result, 'called', 'single failed check: "on_failure" called';


#
# Multiple scenarios, first failing

$dbh->{mock_add_resultset} = {
    sql     => 'something',
    results => [
        [ 'headers' ],
        [ 'failing row' ],
        ],
};
# No need for a second resultset: it won't be queried...

$result = [];
lives_and( sub {
    is &run_checks( $dbh,
                    checks => [
                        {
                            query => 'something',
                            on_failure =>
                                sub { push @$result, 'called 1' },
                        },
                        {
                            query => 'something else',
                            on_failure =>
                                sub { die 'on_failure (2) called?!' },
                        },
                    ]
        ), 0
           }, 'multiple checks, first failing');

# second "on_failure" not called: processing aborted after first one
is_deeply $result, [ 'called 1' ],
    'multiple checks, first failing; "on_failure" called';


#
# Multiple scenarios, second failing

$dbh->{mock_add_resultset} = {
    sql     => 'something',
    results => [
        [ 'headers' ],
        ],
};
$dbh->{mock_add_resultset} = {
    sql     => 'something else',
    results => [
        [ 'headers' ],
        [ 'failing row' ],
        ],
};

$result = [];
lives_and( sub {
    is &run_checks( $dbh,
                    checks => [
                        {
                            query => 'something',
                            on_failure =>
                                sub { push @$result, 'called 1' },
                        },
                        {
                            query => 'something else',
                            on_failure =>
                                sub { push @$result, 'called 2' },
                        },
                    ]
        ), 0
           }, 'multiple checks, first failing');

# first "on_failure" not called: query succeeded.
is_deeply $result, [ 'called 2' ],
    'multiple checks, first failing; "on_failure" called';



#
#
#
#  Tests to assert successful establishing of execution environment
#

throws_ok { confirm(); } qr/can't be called outside/,
    '"confirm" throws error outside formatter-context';
throws_ok { describe(); } qr/can't be called outside/,
    '"describe" throws error outside formatter-context';
throws_ok { grid(); } qr/can't be called outside/,
    '"grid" throws error outside formatter-context';
throws_ok { LedgerSMB::Database::ChangeChecks::provided(); }
    qr/can't be called outside/,
    '"provided" throws error outside formatter-context';

run_with_formatters {
    lives_ok { confirm(); } '"confirm" runs inside formatter-context';
    lives_ok { describe(); } '"describe" runs inside formatter-context';
    lives_ok { grid(); } '"grid" runs inside formatter-context';
    lives_ok { LedgerSMB::Database::ChangeChecks::provided(); }
    '"provided" runs inside formatter-context';
} {
    confirm => sub {},
    describe => sub {},
    grid => sub {},
    provided => sub {},
};
