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
use LedgerSMB::Sysconfig;

=head1 METHODS

=over

=item new(%args)
=item rew(\%args)

Constructor.

=cut

sub new {
    my $pkg = shift;
    my $args = (ref $_[0]) ? $_[0] : { @_ };
    if ($args->{_DBH}) {
        $args->{dbh} = $args->{_DBH};
        delete $args->{_DBH};
    };
    my $mergelist = $args->{mergelist} || [keys %{$args->{base}}];
    my $self = { map { $_ => $args->{base}->{$_} } @$mergelist };
    $self =  PGObject::Simple::new($pkg, %$self);
    $self->__validate__  if $self->can('__validate__');
    return $self;
}

=item set_dbh

Attribute _DBH builder.  Should probably have been named _set_dbh.

=cut

sub set_dbh {
    my ($self) = @_;
    $self->{_DBH} =  LedgerSMB::App_State::DBH();
    return  LedgerSMB::App_State::DBH();
}

=item dbh

This is a wrapper around PGObject::Simple->dbh with the exception that we provide a
a static/class invocation possibility as well.

=cut

sub dbh {
    my ($self) = @_;
    return $self->SUPER::dbh() if ref $self;
    return LedgerSMB::App_State::DBH();
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

=item $self->merge(\%base, %args)

Sets the values from hash 'base' in $self, optionally limited by the
keys enumerated in the array @$args{keys}.

=cut

sub merge {
     my ($self, $base, %args) = @_;
    my @keys = $args{keys} || keys %$base;
     foreach my $key (@keys) {
          $self->{$key} = $base->{$key};
     }
     return $self;
}

=item $self->is_allowed_role([@rolelist])

Accepts an arrayref of roles to check.  For each role on the list, checks to
see if the current session is granted that.  Returns true if any are, false if
none are.

=cut

sub is_allowed_role {
    my ($self, $rolelist) = @_;
    my ($access) =  $self->call_procedure(
         procname => 'lsmb__is_allowed_role', args => [$rolelist]
    );
    return $access->{lsmb__is_allowed_role};
}

sub _get_schema {
    return LedgerSMB::Sysconfig::db_namespace();
}

=back

=cut

1;
