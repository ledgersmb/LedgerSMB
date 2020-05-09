
package LedgerSMB::Database::Upgrade;

=head1 NAME

LedgerSMB::Database::Upgrade - upgrade routines factored out of setup.pm

=head1 DESCRIPTION

=cut

use strict;
use warnings;

use LedgerSMB::Upgrade_Preparation;
use LedgerSMB::Upgrade_Tests;

use Scope::Guard;

use Moose;
use namespace::autoclean;

=head1 ATTRIBUTES

=head2 database

=cut

has database => (is => 'ro', required => 1);

=head2 type

=cut

has type => (is => 'ro', required => 1);

=head1 METHODS

=head2 applicable_tests

Returns all pre-upgrade tests that apply to the application and version
of the database being upgraded/migrated.

=cut

sub _upgrade_test_is_applicable {
    my ($dbinfo, $test) = @_;

    return (($test->min_version le $dbinfo->{version})
            && ($test->max_version ge $dbinfo->{version})
            && ($test->appname eq $dbinfo->{appname}));
}

sub applicable_tests {
    my $self = shift;
    my $dbinfo = $self->database->get_info;

    my @tests = (
        grep { _upgrade_test_is_applicable($dbinfo, $_) }
        LedgerSMB::Upgrade_Tests->get_tests
        );
    my %consistency = map { $_->name => 1 } @tests;

    if (scalar @tests != scalar keys %consistency) {
        die 'Inconsistent state fixing data: multiple applicable tests '
            . 'with the same name';
    }

    return @tests;
}

=head2 applicable_test_by_name($name)

Retrieves exactly one test from the set of applicable tests matching
C<$name>. When no matching test is found, C<undef> is returned.

=cut

sub applicable_test_by_name {
    my ($self, $name) = @_;

    return first { $_->name eq $name } $self->applicable_tests;
}

=head2 run_tests($failure_cb)

Runs the applicable upgrade tests, until the first failing test,
calling C<$failure_cb> on that test.

Returns false-ish when a test failed; true-ish when all tests ran and
no conflicting data was identified (=failed).

=cut

sub run_tests {
    my ($self, $cb) = @_;

    my $dbh = $database->connect({ PrintError => 1, AutoCommit => 0});
    my $guard = guard {
        $dbh->rollback;
        $dbh->disconnect;
    };
    for my $test ($self->applicable_tests) {
        if (not $check->run($dbh, $cb)) {
            return 0;
        }
    }
    $dbh->commit;
    return 1;
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011-2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
