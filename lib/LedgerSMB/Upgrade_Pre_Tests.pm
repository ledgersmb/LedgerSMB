=head1 NAME

LedgerSMB::Upgrade_Pre_Tests - Upgrade pre-tests for LedgerSMB

=head1 SYNPOPSIS

 TODO

=head1 DESCRIPTION

This module has a single function that returns upgrade pre-tests.

=cut

package LedgerSMB::Upgrade_Pre_Tests;
use strict;
use warnings;
use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

=head1 FUNCTIONS

=over

=item get_pre_tests()

Returns the pre-test array
Pre-tests are run only once before any tests, to adjust some tables for
data uniqueness to allow edit, for example.

=cut

sub get_pre_tests {
    my ($self) = @_;
    my @pre_tests = $self->_get_pre_tests;
    return @pre_tests;
}

=back

=head1 TEST DEFINITION

Each test is a Moose object with the following properties (optional ones marked
as such).

=over

=item name

Name of the test

=cut

has name => (is => 'ro', isa => 'Str', required => 1);

=item min_version

The first version to run this against

=cut

has min_version => (is => 'ro', isa => 'Str', required => 1);

=item max_version

The maximum version to run this against

=cut

has max_version => (is => 'ro', isa => 'Str', required => 1);

=item appname

The appname of the application the test belongs to.
Can currently be 'ledgersmb' or 'sql-leder'.

=cut

has appname => (is => 'ro', isa => 'Str', required => 1);

=item test_query

Text of the query to run

=cut

has test_query => (is => 'ro', isa => 'Str', required => 1);

=back

=head1 Methods

=cut

sub _get_pre_tests {
    my ($request) = @_;

    my @pre_tests;

    push @pre_tests, __PACKAGE__->new(
        # Add a unique key to allow editing
        test_query => 'ALTER TABLE acc_trans DROP COLUMN IF EXISTS lsmb_entry_id;
                       ALTER TABLE acc_trans add column lsmb_entry_id SERIAL UNIQUE;',
        name => 'add_unique_acc_trans_key',
           appname => 'sql-ledger',
       min_version => '2.7',
       max_version => '3.0'
    );

    return @pre_tests;
}

__PACKAGE__->meta->make_immutable;

1;
