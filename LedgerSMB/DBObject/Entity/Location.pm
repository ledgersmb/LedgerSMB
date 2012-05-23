=head1 NAME

LedgerSMB::DBObject::Entity::Location - Address Handling for LedgerSMB Contacts

=head1 SYNPOSIS

This contains a the basic handling of addresses for LedgerSMB contacts.

Addresses may be tacked for billing, marketing, and shipping, and may be
attached either to the entity (person or company) or credit account
(customer/vendor account).

=head1 INHERITS

=over

=item LedgerSMB::DBObject_Moose

=cut

package LedgerSMB::DBObject::Entity::Location;
use Moose;
extends 'LedgerSMB::DBObject_Moose';

=head1 PROPERTIES

=over

=item active

Bool, whether the address is active.

=cut

has 'active' => (is => 'rw', isa => 'Maybe[Bool]');

=item inactive_date

Date when the location became inactive.

=cut

has 'inactive_date' => (is => 'rw', isa => 'Maybe[LedgerSMB::PGDate]');

=item location_id

Internal id of the actual location entry.

=cut

has 'location_id' => (is => 'rw', isa => 'Maybe[Int]');

=item entity_id

Internal id of linked entity.  Is undef if linked to an entity credit account 
instead

=cut

has 'entity_id' => (is => 'ro', isa => 'Maybe[Int]');

=item credit_id

Internal id of lined entity credit account.  Is undef if linked to entity
instead.

=cut

has 'credit_id' => (is => 'ro', isa => 'Maybe[Int]');

=item location_class

Internal id of location class.

=over

=item 1 for Billing

=item 2 for Sales

=item 3 for Shipping

=back

=cut

has 'location_class' => (is => 'ro', isa => 'Maybe[Int]');

=item class_name

The name of the class that goes with the id.  This is not set until
$self->set_class_name is called.

=cut

our %classes = ( 1 => $LedgerSMB::App_State::Locale->text('Billing'),
                 2 => $LedgerSMB::App_State::Locale->text('Sales'),
                 3 => $LedgerSMB::App_State::Locale->text('Shipping'),
);

has 'class_name' => (is => 'rw', isa => 'Maybe[Str]');

=item line_one

The first line of the street address.

=cut

has 'line_one' => (is => 'rw', 'isa' => 'Maybe[Str]');

=item line_two

The second line of the street address

=cut

has 'line_two' => (is => 'rw', 'isa' => 'Maybe[Str]');

=item line_three

The third line of the street address

=cut

has 'line_three' => (is => 'rw', 'isa' => 'Maybe[Str]');

=item city

Name of the city.

=cut

has 'city' => (is => 'rw', 'isa' => 'Maybe[Str]');

=item state

Name of the state or province

=cut

has 'state' => (is => 'rw', 'isa' => 'Maybe[Str]');

=item mail_code

Zip or postal code

=cut

has 'mail_code' => (is => 'rw', 'isa' => 'Maybe[Str]');

=item country_id

This is the internal id of the country for the address.

=cut

has 'country_id' => (is => 'rw', 'isa' => 'Maybe[Int]');

=item counry_name

The name of the country

=cut

has 'country_name' => (is => 'rw', 'isa' => 'Maybe[Str]');

=back

=head1 METHODS

=over

=item get($args hashref)

Retrieves locations and returns them.  Args include:

=over 

=item entity_id (required)

=item credit_id (optional)

=item only_class int (optional)

=item

This function returns all locations attached to the entity_id and, if the credit_id is provided, all locations attached to the credit_id as well.  The two 
are appended together with the ones at the entity level coming first.

If only_class is set, all results will be discarded that are not a specific 
class (useful for retrieving billing info only).

=cut

sub get_active {
    my ($self, $request, $args) = @_;
    my @results;
    for my $ref ($self->call_procedure(procname => 'entity__list_locations',
                                           args => [$args->{entity_id}]))
    {
       next if ($args->{only_class}) 
               and ($args->{only_class} != $ref->{location_class});
        LedgerSMB::DBObject_Moose::prepare_dbhash($request, $ref);
        push @results, $self->new(%$ref);
    }
    return @results unless $args->{credit_id};

    for my $ref ($self->call_procedure(procname => 'eca__list_locations',
                                           args => [$args->{credit_id}]))
    {
       next if ($args->{only_class}) 
               and ($args->{only_class} != $ref->{location_class});
        $ref->{credit_id} = $args->{credit_id};
        LedgerSMB::DBObject_Moose::prepare_dbhash($request, $ref);
        push @results, $self->new(%$ref);
    }

    return @results;

}

=item save()

Saves the current location to the database

=cut

sub save {
    my ($self) = @_;
    my $procname;

    if ($self->credit_id){
        $procname = 'eca__location_save';
    } else {
        $procname = 'entity__location_save';
    }
    $self->exec_method({funcname => $procname});
}

=item deactivate()

Deactivates the current location

=cut

sub deactivate {
    my ($self) = @_;
    $self->exec_method({funcname => 'location__deactivate'});
}

=back

=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of the GNU General Public License version 2 or at your option any later
version.  Please see the enclosed LICENSE file for details.

=cut

return 1;
