#!perl

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
    lives_ok {
        # Most checks here aren't immediately visible:
        # the database session checks that the correct queries
        # and expected responses are being generated. When not,
        # an error is thrown, which we handle by using 'lives_ok'
        my $dbh = _create_dbh_for_failure_session($check, $test);
        my $out = json_formatter_context {
            return ! run_checks($dbh, checks => [ $check ]);
        } $dir->dirname;
        ok(defined($out), 'JSON failure output was generated');
        ok(-f $out, 'JSON failure output exists');
    };

    lives_ok {
        my $dbh = _create_dbh_for_submit_session($check, $test);
        _save_JSON_response_file($check, $test->{response}, $dir);
        my $out = json_formatter_context {
            return ! run_checks($dbh, checks => [ $check ]);
        } $dir->dirname;
        ok(! defined($out), 'No new failures occurred');
    };
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
