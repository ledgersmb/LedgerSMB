
package LedgerSMB::Database::Factory;

=head1 NAME

LedgerSMB::Database::Factory -

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use strict;
use warnings;

use Moo;

our $VERSION = '0.0.1';


use LedgerSMB::Database;

=head1 ATTRIBUTES

=head2 connect_data

=cut

has connect_data => (is => 'ro', required => 1);

=head2 schema

=cut

has schema => (is => 'ro', default => 'public');

=head1 METHODS

=head2 instance( user => $username, password => $password, %overriden_connect_data )

=cut

sub instance {
    my $self = shift;
    my %args = @_;

    return LedgerSMB::Database->new(
        connect_data => {
            host => 'localhost',
            port => 5432,
            $self->connect_data->%*,
            %args
        },
        schema => $self->schema );
}



1;


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2022 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

