
use v5.38;

package LedgerSMB::Company;

=head1 NAME

LedgerSMB::Company - Entrypoint to the Perl API for a LedgerSMB company

=head1 SYNOPSIS

  use LedgerSMB::Company;

  # assuming a connected $dbh database handle
  my $c = LedgerSMB::Company->new( dbh => $dbh );

  print $c->setting('company.legalname');

=cut

use Moose;
use namespace::autoclean;

use LedgerSMB::Company::Configuration;
use LedgerSMB::Company::Menu;
use LedgerSMB::Company::Workflows;

=head1 DESCRIPTION

This module defines the class which encapsulates a connection to a LedgerSMB
company database. Its responsibility is to provide access to the various
groups of functionality (modules) in the database and their wrapping
Perl API modules.

=head1 ATTRIBUTES

=head2 dbh (required)

Database handle for connection to the LedgerSMB company database. The
access rights to the company are derived from the connected user.

=cut

has _dbh => (is => 'ro', init_arg => 'dbh', reader => 'dbh', required => 1,
             trigger => sub { die '<undef> dbh passed to Company' if not defined $_[1]; });

=head2 wire (required)

Configuration instance (dependency injection container). L<Beam::Wire> instance.

=cut

has _wire => (is => 'ro', init_arg => 'wire', reader => 'wire', required => 1);

=head2 configuration

Holds a L<LedgerSMB::Company::Configuration> instance, representing the
configuration of the connected company database (as visible to the connected
user).

This attribute cannot be set at object instantiation.

Note: Depending on the connected user, different parts of the configuration
may be visible. In order to see and manage the complete company setup, be
sure to connect as a database owner or PostgreSQL super-user.

=cut

has configuration => (
    is => 'ro',
    init_arg => undef,
    lazy => 1,
    builder => '_build_configuration');

sub _build_configuration {
    my $self = shift;
    return LedgerSMB::Company::Configuration->new( dbh => $self->dbh );
}


=head2 menu

Holds a L<LedgerSMB::Company::Menu> instance, representing the
menu of the connected company database (as visible to the connected user).

This attribute cannot be set at object instantiation.

=cut

has menu => (
    is => 'ro',
    init_arg => undef,
    lazy => 1,
    builder => '_build_menu');

sub _build_menu($self) {
    return LedgerSMB::Company::Menu->new( dbh => $self->dbh );
}

=head2 workflows

=cut

has workflows => (
    is => 'ro',
    init_arg => undef,
    lazy => 1,
    builder => '_build_workflows');

sub _build_workflows($self) {
    return LedgerSMB::Company::Workflows->new(
        dbh => $self->dbh,
        wire => $self->wire,
        app => $self
        );
}


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020-2025 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

__PACKAGE__->meta->make_immutable;
