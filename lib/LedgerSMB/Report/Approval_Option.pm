package LedgerSMB::Report::Approval_Option;
use Moose::Role;

=head1 NAME

LedgerSMB::Report::Approval_Option - Report interface for approval

=head1 SYNOPSIS

This includes an is_approved user-settable flag (Y/N/All) which is mapped to
a boolean (True/False/Null).  Null is used to request all.

=head1 ADDED PROPERTIES

=head2 is_approved string

Y, N, All

=head2 approved bool

mapped from is_approved

=cut

has is_approved => (is => 'ro', isa => 'Str', required => 1);
has approved => (is => 'ro', lazy => 1, builder => '_approved');

my $_approval_map = {
   Y => 1,
   N => 0,
  All => undef
};

sub _approved {
    my $self = shift;
    die 'Bad approval code: ' . $self->is_approved
        unless exists $_approval_map->{$self->is_approved};
    return $_approval_map->{$self->is_approved}
}

1;
