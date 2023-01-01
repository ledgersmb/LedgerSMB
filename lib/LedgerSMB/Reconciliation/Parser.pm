
package LedgerSMB::Reconciliation::Parser;

=head1 NAME

LedgerSMB::Reconciliation::Parser - Bank statement parser for reconciliation

=head1 DESCRIPTION

This module holds a collection of configurations for importing bank statement
transactions into a reconciliation report.

=cut

use strict;
use warnings;

use Moo;

use List::Util qw(first);

=head1 ATTRIBUTES

=head2 configurations

Holds an array of parser configurations, each an instance implementing the
L<LedgerSMB::Reconciliation::Format> role.

=cut

has configurations => (is => 'ro', default => sub { [] });

=head1 METHODS

=head2 get_configuration(name => $name)

Returns the first parser configuration with a name matching C<$name>.

=cut

sub get_configuration {
    my $self = shift;
    my %args = @_;

    return unless defined $args{name};
    return first { $_->name eq $args{name} } $self->configurations->@*;
}


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2023 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
