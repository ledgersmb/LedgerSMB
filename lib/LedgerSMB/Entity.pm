
package LedgerSMB::Entity;

=head1 NAME

LedgerSMB::Entity -- Entity Management base classes for LedgerSMB

=head1 DESCRIPTION

This module manages basic entity management for persons and companies,
both of which will likely inherit this class.

TODO: "will likely"????

=cut

use Moose;
use namespace::autoclean;
with 'LedgerSMB::PGObject';

=head1 PROPERTIES

=over

=item id

This is the internal, system id, which is a surrogate key.  This will be undefined when
the entity has not yet been saved to the database and set once it has been saved or
retrieved.

=cut

has 'id' => (is => 'rw', isa => 'Str', required => '0');

=item control_code

The control code is the internal handling number for the operator to use to pull up
an entity,

=cut

has 'control_code' => (is => 'rw', isa => 'Str', required => 1);

=item name

The unofficial name of the entity.  This is usually copied in from company.legal_name
or prepared (using some sort of locale-specific logic) from person.first_name and
person.last_name.

=cut

has 'name' => (is => 'rw', isa => 'Str', required => 1);

=item country_id

ID of country of entiy.

=cut

has 'country_id' => (is => 'rw', isa => 'Int', required => 1);

=item country_name

Name of country (optional)

=cut

has 'country_name' => (is => 'rw', isa => 'Str', required => 0);

=item is_used

Boolean (Readonly). True if the company entity is used in the database
(and hence can't be deleted).

=cut

has 'is_used' => (is => 'ro');

=back

=head1 METHODS

=over

=item get($id)

Returns an entity by id

=cut

sub get{
    my ($id) = @_;
    my ($result) =  __PACKAGE__->call_procedure(funcname => 'entity__get',
                                                   args => [$id]);
    return __PACKAGE__->new(%$result);
}

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;
    my %args;
    if (ref $_[0]){
        %args = %{$_[0]};
    } else {
        %args = @_;
    }
    if (!$args{name}){
        $args{name} = $args{legal_name} if $args{legal_name};
        $args{name} = "$args{first_name} $args{last_name}" if $args{first_name};
    }
    $class->$orig(%args);
};

__PACKAGE__->meta->make_immutable;

1;
