#!perl


=head1 Driver application for testing of schema change checks

This application reads files (*.precheck) and executes the test scenarios
defined in them by setting up a mock environment: The schema change checks
I<think> they are being executed as a regular check, but everything from
the database connection to the user-input is mocked.

=head2 Definition of test scenarios in *.precheck files

Each precheck test definition file is a Perl source file which holds
exactly one hash. Note that due to the fact that it's a Perl source file
comments can be added just as in regular Perl files.

The names of the prechek files below t/16-precheck/ use the same paths
as the schema change check files below sql/changes/ that they are tests
for. E.g. the test file t/16-precheck/1.5/abstract_tables.precheck defines
tests for checks defined in sql/changes/1.5/abstract_tables.sql.checks.pl.

The keys of the hash correspond with the titles of the checks in the file
to be tested. The values associated with the keys are arrays of hashes.
Each hash in the array defines a test case for the specific check to be
tested. These keys are supported:

=over

=item failure_data

Defines a L<DBD::Mock> resultset (rows failing the check) for the
query defined by the check.

=item failure_session

A list of L<DBD::Mock::Session states|
https://metacpan.org/pod/DBD::Mock#DBD::Mock::Session> to be used
I<after> the initial state with the failing query. These could
be neccessary/desirable for e.g. queries issued
as part of the C<dropdown_sql> DSL keyword.

=item submit_session

A list of L<DBD::Mock::Session states|
https://metacpan.org/pod/DBD::Mock#DBD::Mock::Session> to be used to validate
the correct submission of corrected data back to the database.

=item response

A hash object used to generate the response data as documented in
L<LedgerSMB::Database::SchemaChecks::JSON>.

Note that a JSON formatted data structure is printed as part of the error
message when the response is missing to help creation of one.

=back

=cut

use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBI;
use DBD::Mock::Session;
use File::Find::Rule;
use File::Temp;
use JSON::MaybeXS;
use LedgerSMB::Database::ChangeChecks qw( run_checks load_checks );
use LedgerSMB::Database::SchemaChecks::JSON qw( json_formatter_context );
use List::Util qw( first );


my @schemacheck_tests = File::Find::Rule->new
    ->name('*.precheck')->in('t/16-prechecks');

my @schemachecks = File::Find::Rule->new
    ->name('*.checks.pl')->in('sql/changes');

is(scalar(@schemachecks), scalar(@schemacheck_tests),
   'All schema checks are tested');


sub _slurp {
    my ($fn) = @_;

    open my $fh, '<:encoding(UTF-8)', $fn
        or die "Failed to open generated response file '$fn': $!";
    local $/ = undef;
    my $content = <$fh>;
    close $fh
        or warn "Failed to close generated response file '$fn': $!";


    return $content;
}

sub _schemacheck_file {
    my ($schemacheck_test) = @_;

    my $schemacheck = $schemacheck_test;
    $schemacheck =~ s!^t/16-prechecks/!sql/changes/!
        or die "Can't map '$schemacheck_test' to schema change check file";
    $schemacheck =~ s!.precheck$!.sql.checks.pl!
        or die "Can't map '$schemacheck_test' to schema change check file";

    if (! -f $schemacheck) {
        die "Schema change check file ($schemacheck) associated"
            . " with $schemacheck_test doesn't exist";
    }

    return $schemacheck;
}

sub _create_dbh_for_failure_session {
    my ($check, $test) = @_;
    my $dbh = DBI->connect('dbi:Mock:', '', '', { PrintError => 0 });
    $test->{failure_session} //= [];
    my $session = DBD::Mock::Session->new(
        'sess',
        {
            statement => $check->{query},
            results => $test->{failure_data},
        },
        @{$test->{failure_session} // []},
        );
    $dbh->{mock_session} = $session;

    return $dbh;
}

sub _create_dbh_for_submit_session {
    my ($check, $test) = @_;
    my $dbh = DBI->connect('dbi:Mock:', '', '', { PrintError => 0 });
    $test->{submit_session} //= [];
    my $session = DBD::Mock::Session->new(
        'sess',
        {
            statement => $check->{query},
            results => $test->{failure_data},
        },
        @{$test->{failure_session}},
        @{$test->{submit_session}},
        );
    $dbh->{mock_session} = $session;

    return $dbh;
}

my $json = JSON::MaybeXS->new( utf8 => 1 );

sub _save_JSON_response_file {
    my ($check, $response, $dir) = @_;
    my $fn = LedgerSMB::Database::SchemaChecks::JSON::_response_filename(
        $dir->dirname, $check
        );

    open my $fh, '>:encoding(UTF-8)', $fn
        or die "Unable to create JSON response file '$fn': $!";
    print $fh $json->encode({ response => $response })
        or die "Unable to generate JSON response file '$fn': $!";
    close $fh
        or warn "Unable to close JSON response file '$fn': $!";
}

sub _run_schemacheck_test {
    my ($check, $test) = @_;
    my $dir = File::Temp->newdir;
    my $out;
    lives_ok {
        # Most checks here aren't immediately visible:
        # the database session checks that the correct queries
        # and expected responses are being generated. When not,
        # an error is thrown, which we handle by using 'lives_ok'
        my $dbh = _create_dbh_for_failure_session($check, $test);
        $out = json_formatter_context {
            return ! run_checks($dbh, checks => [ $check ]);
        } $dir->dirname;
        ok(defined($out), 'JSON failure output was generated');
        ok(-f $out, 'JSON failure output exists');
    };

    if ($test->{response}) {
        lives_ok {
            my $dbh = _create_dbh_for_submit_session($check, $test);
            _save_JSON_response_file($check, $test->{response}, $dir);
            $out = json_formatter_context {
                return ! run_checks($dbh, checks => [ $check ]);
            } $dir->dirname;
            ok(! defined($out), 'No new failures occurred');
        };
    }
    elsif (ref $check->{on_submit}) {
        fail 'Response defined; use failure output below to define a response';
        diag _slurp($out);
    }
    else {
        note "no response: $check->{title}\n\n";
    }
}


sub _run_schemacheck_tests {
    my ($check, $tests) = @_;

    _run_schemacheck_test($check, $_) for @$tests;
}


sub _run_schemachecks_tests {
    my ($schemacheck_test) = @_;
    my $schemacheck_file = _schemacheck_file($schemacheck_test);
    my @checks = load_checks($schemacheck_file);
    my $tests = eval _slurp($schemacheck_test);
    die "Unable to load schema checks from file $schemacheck_test: $@"
        if defined $@ and not defined $tests;

    for my $test (keys %$tests) {
        my $check = first { $_->{title} eq $test } @checks;
        ok( defined($check),
            "Found check for which tests ($test) have been"
            . " defined in $schemacheck_file");

        if ($check) {
            _run_schemacheck_tests($check, $tests->{$test});
        }
    }
}


if (@schemacheck_tests) {
    _run_schemachecks_tests($_) for @schemacheck_tests;
    done_testing;
}
else {
    plan skip_all => "No test definition files found";
}
