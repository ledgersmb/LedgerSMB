package LedgerSMB::Report::Voided_Option;

=head1 NAME

LedgerSMB::Report::Voided_Option - Report interface for voided selection

=head1 DESCRIPTION

This moose role adds an C<is_voided>d user-settable flag (Y/N/All)
which is mapped to a boolean (True/False/Null).  Null is used to request all.

=head1 ADDED PROPERTIES

=head2 is_voided string

Y, N, All

=head2 voided bool

mapped from is_voided

=cut

use Moose::Role;
use namespace::autoclean;

has is_voided => (is => 'ro', isa => 'Str',
                  default => 'All');
has voided => (is => 'ro', lazy => 1,
               builder => '_voided');

my $_voided_map = {
   Y => 1,
   N => 0,
  All => undef
};

=head1 METHODS

This module does not declare any (public) methods.

=cut


sub _voided {
    my $self = shift;
    die 'Bad approval code: ' . $self->is_voided
        unless exists $_voided_map->{$self->is_voided};
    return $_voided_map->{$self->is_voided}
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2016-2023 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
