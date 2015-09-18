=head1 NAME

LedgerSMB::PGOld - Old DBObject replacement for 1.3-era LedgerSMB code

=head1 SYNPOSIS

This is like DBObject but uses the PGObject::Simple for base functionality.

=head1 METHODS

See PGObject::Simple

=cut

# This is temporary until we can get rid of it.  Basically the following
# namespaces need to be moved to Moose:
#
# LedgerSMB::Setting
# LedgerSMB::DBObject
# Then we can delete this module.

package LedgerSMB::PGOld;

use strict;
use warnings;

use base 'PGObject::Simple';
use LedgerSMB::App_State;

sub new {
    my ($pkg, $args) = @_;
    my $mergelist = $args->{mergelist} || [keys %{$args->{base}}];
    my $self = { map { $_ => $args->{base}->{$_} } @$mergelist };
    $self =  PGObject::Simple::new($pkg, %$self);
    return $self;
}

sub set_dbh {
    my ($self) = @_;
    $self->{_DBH} =  LedgerSMB::App_State::DBH();
    return  LedgerSMB::App_State::DBH();
}

sub _parse_array {
    my ($self, $value) = @_;
    return @$value if ref $value eq 'ARRAY';
    return if !defined $value;
    # No longer needed since we require DBD::Pg 2.x
}

sub _db_array_scalars {
    my $self = shift @_;
    my @args = @_;
    return \@args;
    # No longer needed since we require DBD::Pg 2.x
}

sub _db_array_literal {
    my $self = shift @_;
    my @args = @_;
    return \@args;
    # No longer needed since we require DBD::Pg 2.x
}

sub merge {
     my ($self, $base, %args) = @_;
    my @keys = $args{keys} || keys %$base;
     foreach my $key (@keys) {
          $self->{$key} = $base->{$key};
     }
     return $self;
}


1;
