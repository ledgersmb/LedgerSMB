# Database schema upgrade pre-checks


use Test2::V0 qw(!check); # ChangeChecks imports 'check'


use LedgerSMB::Database::ChangeChecks qw( :DEFAULT run_with_formatters
       run_checks load_checks );


use Data::Dumper;
use DBI;
use File::Temp qw( :seekable );
use MIME::Base64;




#
#
#
#  Tests to assert validity of internal helpers
#

my $encoded_pk =
    LedgerSMB::Database::ChangeChecks::_encode_pk(
        { num => 3, str => 'abc', not_avail => undef },
        [ 'num', 'str', 'not_avail' ]
    );

my %pk;
@pk{('num', 'str', 'not_avail')} =
    @{LedgerSMB::Database::ChangeChecks::_decode_pk($encoded_pk)};

is LedgerSMB::Database::ChangeChecks::_encode_pk(
    \%pk, [ 'num', 'str', 'not_avail' ]),
    $encoded_pk, 'primary key encoding + decoding';


#
#
#
#  Tests to assert correct loading of pre-check code
#


my $tests = <<HEREDOC;
package PreCheckTests;

1;

HEREDOC


open my $fh, '<', \$tests
    or die $!;
ok( lives { is scalar &load_checks($fh), 0; } ,
          'Loading empty checks from file-handle');


my $th = File::Temp->new();
print $th $tests;
$th->flush;
ok( lives { is scalar &load_checks($th->filename), 0; },
          'Loading empty checks from file');
close $th or die "Failed to close empty test file: $!";


like( dies { &load_checks('/tmp/non-existant'); },
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

open $fh, '<', \$tests
    or die $!;
ok( lives { is scalar &load_checks($fh), 1; },
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

open $fh, '<', \$tests
    or die $!;
ok( lives { is scalar &load_checks($fh), 2; },
          'Loading two checks from file-handle');



$tests = <<HEREDOC;
package PreCheckTests;

use LedgerSMB::Database::ChangeChecks;

check 'title',
    description => q|a description|,
    query => q|a query|,
    on_submit => sub { return 1; },
    on_failure => sub { return 1; };


check 'title',
    description => q|a description|,
    query => q|a query|,
    on_submit => sub { return 1; },
    on_failure => sub { return 1; };


1;
HEREDOC

open $fh, '<', \$tests
    or die $!;
like( dies { &load_checks($fh); },
          qr/^Multiple checks with the same name not supported/,
          'Loading two equally named checks from file-handle');


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

open $fh, '<', \$tests
    or die $!;
like( dies { &load_checks($fh); }, qr/doesn't define a description/,
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

open $fh, '<', \$tests
    or die $!;
like( dies { &load_checks($fh); }, qr/doesn't define a query/,
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

open $fh, '<', \$tests
    or die $!;
like( dies { &load_checks($fh); }, qr/doesn't define 'on_submit'/,
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

open $fh, '<', \$tests
    or die $!;
like( dies { &load_checks($fh); }, qr/doesn't define 'on_failure'/,
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

ok( lives {
    is &run_checks( $dbh,
                    checks => [
                        {
                            query => 'something',
                            on_failure => sub { die 'on_failure called?!' },
                        },
                    ]
        ), 1;
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

ok( lives {
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
        ), 1;
           }, 'multiple completed checks');


#
# Single failing scenario

$dbh = DBI->connect('DBI:Mock:', '', '');
$dbh->{mock_add_resultset} = {
    sql     => 'something',
    results => [
        [ 'headers' ],
        [ 'failing row' ],
        ],
};

my $result = undef;

run_with_formatters {
    ok(lives {
        is &run_checks( $dbh,
                        checks => [
                            {
                                query => 'something',
                                on_failure => sub { $result = 'called'; },
                            },
                        ]
            ), 0;
    }, 'single failed check: indicates failure');
} {
    confirm => sub {},
    describe => sub {},
    grid => sub {},
    provided => sub { return 0; },
};

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
run_with_formatters {
    ok( lives {
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
            ), 0;
    }, 'multiple checks, first failing');
} {
    confirm => sub {},
    describe => sub {},
    grid => sub {},
    provided => sub { return 0; },
};

# second "on_failure" not called: processing aborted after first one
is $result, [ 'called 1' ],
    'multiple checks, first failing; "on_failure" called';


#
# Multiple scenarios, second failing

$dbh = DBI->connect('DBI:Mock:', '', '');
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
run_with_formatters {
    ok( lives {
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
            ), 0;
    }, 'multiple checks, first failing');
} {
    confirm => sub {},
    describe => sub {},
    grid => sub {},
    provided => sub { return 0; },
};

# first "on_failure" not called: query succeeded.
is $result, [ 'called 2' ],
    'multiple checks, first failing; "on_failure" called';



#
#
#
#  Tests to assert successful establishing of execution environment
#

{
    # The call to C<grid> depends on the $check context
    local $LedgerSMB::Database::ChangeChecks::check = {
        tables => {
            'a' => { prim_key => 'a' }
        }
    };


    like( dies { confirm(); }, qr/can't be called outside/,
         '"confirm" throws error outside formatter-context');
    like( dies { describe(); }, qr/can't be called outside/,
         '"describe" throws error outside formatter-context');
    like( dies { grid [], name => 'a'; }, qr/can't be called outside/,
         '"grid" throws error outside formatter-context');
    like( dies { LedgerSMB::Database::ChangeChecks::provided(); },
         qr/can't be called outside/,
        '"provided" throws error outside formatter-context');

    run_with_formatters {
        ok lives { confirm(); }, '"confirm" runs inside formatter-context';
        ok lives { describe(); }, '"describe" runs inside formatter-context';
        ok lives { grid [], name => 'a'; },
                 '"grid" runs inside formatter-context';
        ok lives { LedgerSMB::Database::ChangeChecks::provided(); },
        '"provided" runs inside formatter-context';
    } {
        confirm => sub {},
        describe => sub {},
        grid => sub {},
        provided => sub {},
    };
}

#
#
#
#  Tests to assert the 'provided' protocol
#

{
    local $LedgerSMB::Database::ChangeChecks::check = 'the-check';
    run_with_formatters {
        ok lives { is LedgerSMB::Database::ChangeChecks::provided(), 1,
                    '"provided" without arguments'; };
        ok lives { is LedgerSMB::Database::ChangeChecks::provided('name'),
                    'name', '"provided" with argument'; };
    } {
        confirm => sub {},
        describe => sub {},
        grid => sub {},
        provided => sub {
            shift; # remove the check being passed in
            return 1 if ! @_;
            return shift;
        },
    };
}


# Result set with failures
$dbh = DBI->connect('DBI:Mock:', '', '');
$dbh->{mock_add_resultset} = [
    [ 'headers' ],
    [ 'failing-row' ],
    ];

# Result set without failures, so we fake that the data was fixed
$dbh->{mock_add_resultset} = [
    [ 'headers' ],
    ];

$result = 'failed';
run_with_formatters {
    ok lives {
        is &run_checks( $dbh,
                        checks => [
                            {
                                query => 'something',
                                on_failure => sub { },
                                on_submit => sub { $result = 'success' },
                            },
                        ]
            ), 1;
    }, 'No call to "on_failure" when data "provided"';
} {
    confirm => sub {},
    describe => sub {},
    grid => sub {},
    provided => sub { return 1; }
};
is $result, 'success', 'due to "provided" data, "on_submit" is called';



#
#
#
#  Tests to assert the correctness of 'save_grid'
#


# Result set with failures
$dbh = DBI->connect('DBI:Mock:', '', '');
$dbh->{mock_add_resultset} = [
    [ qw/a d e/ ],
    [ qw/z y x/ ],
    [ qw/w v u/ ],
    ];
$dbh->{mock_add_resultset} = [
    [ qw/d/ ],
    [] ];
$dbh->{mock_add_resultset} = [
    [ qw/d/ ],
    [] ];

run_with_formatters {
    LedgerSMB::Database::ChangeChecks::_run_check(
        $dbh,
        {
            tables => {
                'abc' => { prim_key => 'a' },
            },
            query => 'dummy',
            on_failure => sub {
                my ($check, $dbh, $rows) = @_;
                grid $rows,
                  name => 'b',
                  table => 'abc',
                  columns => [ qw/d e/ ],
                  edit_columns => [ 'd' ],
                ;
            },
            on_submit => sub {
                save_grid $dbh, [
                    { a => 'z', d => 'y', e => 'x' },
                    { a => 'w', d => 'v', e => 'u' },
                ], name => 'b', table => 'abc';
            },
        });
} {
    provided => sub {
        return [ { __pk => encode_base64('z', ''), a => 'z', d => 'a' },
                 { __pk => encode_base64('w', ''), a => 'w', d => 'b' },
            ];
    },
    confirm => sub {},
    describe => sub {},
    grid => sub {},
};

my $sql_history = ${$dbh->{mock_all_history}}[-2];
my $stmt = $sql_history->statement;
$stmt =~ s/\s+/ /g;

is $stmt, q{UPDATE "abc" SET "d" = ? WHERE "a" = ?},
    'Found the correct update statement';
is $sql_history->bound_params, [ 'b', 'w' ],
    'Found the correct bound parameters';

done_testing;
