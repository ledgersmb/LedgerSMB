=head1 NAME

LedgerSMB::PGOld - Old DBObject replacement for 1.3-era LedgerSMB code

=head1 SYNPOSIS

This is like DBObject but uses the PGObject::Simple for base functionality.

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
use LedgerSMB::Sysconfig;

=head1 METHODS

See PGObject::Simple

=over

=item new(%args)

Constructor.

Recognized arguments are:

=over

=item base

A hashref which is imported as properties of the new object.

=back

=cut

sub new {
    my $pkg = shift;
    my $args = (ref $_[0]) ? $_[0] : { @_ };

    my $self = PGObject::Simple::new($pkg, %{$args->{base}});
    $self->__validate__  if $self->can('__validate__');
    return $self;
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

=item $self->funcschema()



=cut

sub funcschema {
    my ($self) = @_;

    return LedgerSMB::Sysconfig::db_namespace();
}


=back

=cut

1;
