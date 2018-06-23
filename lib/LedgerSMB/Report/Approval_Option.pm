package LedgerSMB::Report::Approval_Option;

=head1 NAME

LedgerSMB::Report::Approval_Option - Report interface for approval

=head1 DESCRIPTION

This moose role adds an C<is_approve>d user-settable flag (Y/N/All)
which is mapped to a boolean (True/False/Null).  Null is used to request all.

=head1 ADDED PROPERTIES

=head2 is_approved string

Y, N, All

=head2 approved bool

mapped from is_approved

=cut

use Moose::Role;
use namespace::autoclean;

has is_approved => (is => 'ro', isa => 'Str',
                    default => 'Y');
has approved => (is => 'ro', lazy => 1,
                 builder => '_approved');

my $_approval_map = {
   Y => 1,
   N => 0,
  All => undef
};

=head1 METHODS

This module does not declare any (public) methods.

=cut


sub _approved {
    my $self = shift;
    die 'Bad approval code: ' . $self->is_approved
        unless exists $_approval_map->{$self->is_approved};
    return $_approval_map->{$self->is_approved}
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2016-2018 The LedgerSMB Core Team

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
