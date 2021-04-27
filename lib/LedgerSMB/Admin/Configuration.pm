
package LedgerSMB::Admin::Configuration;

=head1 NAME

LedgerSMB::Admin::Configuration - ledgersmb-admin's configuration provider

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use strict;
use warnings;

use List::Util qw(first);

use Moose;
use namespace::autoclean;

=head1 ATTRIBUTES

=head2 config

=cut

has config => (is => 'ro', required => 0,
               default => sub { { connect_data => {} } });

=head1 METHODS

=head2 get($config_key)

Generic configuration accessor, returns the value of the specific
configuration key.

=cut

sub get {
    my ($self, $key) = @_;

    return $self->config->{$key};
}


=head2 sql_directory

Accessor for specific 'sql_directory' configuration key, with extra
processing to assert the correct scalar return value (selecting the
best fit from a list provided -- or the defaults).

=cut

sub sql_directory {
    my ($self) = @_;

    my $dirs = $self->get('sql_directory');
    $dirs = [ qw( ./sql
              /usr/local/share/ledgersmb-admin/sql
              /usr/share/ledgersmb-admin/sql ) ]
        unless defined $dirs;
    $dirs = [ $dirs ] unless ref $dirs;

    return first { -d $_ } $dirs->@*;
}

__PACKAGE__->meta->make_immutable;

1;

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.
