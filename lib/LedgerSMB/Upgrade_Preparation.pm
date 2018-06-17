
package LedgerSMB::Upgrade_Preparation;

=head1 NAME

LedgerSMB::Upgrade_Preparation - Upgrade preparations for LedgerSMB

=head1 SYNPOPSIS

 TODO

=head1 DESCRIPTION

This module has a single function that returns upgrade preparations.

=cut

use strict;
use warnings;
use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

=head1 FUNCTIONS

=over

=item get_migration_preparations()

Returns the preparation array.
Preparations are run only once before any tests, to adjust some tables for
data uniqueness to allow edit, for example.
They must not alter data to prevent the user to revert to his original package,
either a previous LedgerSMB or SQL-ledger.

=cut

sub get_migration_preparations {
    my ($self) = @_;
    my @preparations = $self->_get_migration_preparations;
    return @preparations;
}

=back

=head1 TEST DEFINITION

Each test is a Moose object with the following properties (optional ones marked
as such).

=over

=item name

Name of the preparation

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

=item preparation

Text of the query to run

=cut

has preparation => (is => 'ro', isa => 'Str', required => 1);

=back

=head1 Methods

=cut

sub _get_migration_preparations {
    my ($request) = @_;

    my @preparations;

    push @preparations, __PACKAGE__->new(
        # Add a unique key to allow editing
        preparation => 'ALTER TABLE acc_trans DROP COLUMN IF EXISTS lsmb_entry_id;
                        ALTER TABLE acc_trans add column lsmb_entry_id SERIAL UNIQUE;',
        name => 'add_unique_acc_trans_key',
           appname => 'sql-ledger',
       min_version => '2.7',
       max_version => '3.0'
    );

    return @preparations;
}


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2018 The LedgerSMB Core Team

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

__PACKAGE__->meta->make_immutable;

1;
