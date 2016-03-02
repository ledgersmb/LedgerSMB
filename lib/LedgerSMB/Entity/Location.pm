=head1 NAME

LedgerSMB::Entity::Location - Address Handling for LedgerSMB Contacts

=head1 SYNPOSIS

 my $loc = LedgerSMB::Entity::Location->new(%$request);
 $loc->save;

=head1 DESCRIPTION

This contains a the basic handling of addresses for LedgerSMB contacts.

Addresses may be tacked for billing, marketing, and shipping, and may be
attached either to the entity (person or company) or credit account
(customer/vendor account).

=cut

package LedgerSMB::Entity::Location;
use Moose;
use LedgerSMB::MooseTypes;
use LedgerSMB::App_State;
use LedgerSMB::Locale;
with 'LedgerSMB::PGObject';

my $locale = $LedgerSMB::App_State::Locale;
if (!$locale){
   $locale = LedgerSMB::Locale->get_handle('en');
}

=head1 PROPERTIES

=over

=item active

Bool, whether the address is active.

=cut

has 'active' => (is => 'rw', isa => 'Bool');

=item inactive_date

Date when the location became inactive.

=cut

has 'inactive_date' => (is => 'rw', coerce=>1, isa => 'LedgerSMB::Moose::Date');

=item id

Internal id of the actual location entry.

=cut

has 'id' => (is => 'rw', isa => 'Int', required => 0);

=item entity_id

Internal id of linked entity.  Is undef if linked to an entity credit account
instead

=cut

has 'entity_id' => (is => 'ro', isa => 'Int', required => 0);

=item credit_id

Internal id of lined entity credit account.  Is undef if linked to entity
instead.

=cut

has 'credit_id' => (is => 'rw', isa => 'Int', required => 0);

=item location_class

Internal id of location class.

=over

=item 1 for Billing

=item 2 for Sales

=item 3 for Shipping

=back

=cut

has 'location_class' => (is => 'ro', isa => 'Int', required => 1);

=item old_location_class

Old location class for updating

=cut

has 'old_location_class' => (is => 'ro', isa => 'Int', required => 0);

=item class_name

The name of the class that goes with the id.  This is not set until
$self->set_class_name is called.

=cut

our %classes = ( 1 => $locale->text('Billing'),
                 2 => $locale->text('Sales'),
                 3 => $locale->text('Shipping'),
);

has 'class_name' => (is => 'rw', isa => 'Str', required => 0);

=item line_one

The first line of the street address.

=cut

has 'line_one' => (is => 'rw', 'isa' => 'Str', required => 1);

=item line_two

The second line of the street address

=cut

has 'line_two' => (is => 'rw', 'isa' => 'Maybe[Str]', required => 0);

=item line_three

The third line of the street address

=cut

has 'line_three' => (is => 'rw', 'isa' => 'Maybe[Str]', required => 0);

=item city

Name of the city.

=cut

has 'city' => (is => 'rw', 'isa' => 'Str', required => 1);

=item state

Name of the state or province

=cut

has 'state' => (is => 'rw', 'isa' => 'Maybe[Str]', required => 0);

=item mail_code

Zip or postal code

=cut

has 'mail_code' => (is => 'rw', 'isa' => 'Maybe[Str]', required => 0);

=item country_id

This is the internal id of the country for the address.

=cut

has 'country_id' => (is => 'rw', 'isa' => 'Int', required => 1);

=item counry_name

The name of the country

=cut

has 'country_name' => (is => 'rw', 'isa' => 'Str', required => 0);

=back

=head1 METHODS

=over

=item get($args hashref)

Retrieves locations and returns them.  Args include:

=over

=item entity_id (required)

=item credit_id (optional)

=item only_class int (optional)

=back

This function returns all locations attached to the entity_id and, if the credit_id is provided, all locations attached to the credit_id as well.  The two
are appended together with the ones at the entity level coming first.

If only_class is set, all results will be discarded that are not a specific
class (useful for retrieving billing info only).

=cut

sub get_active {
    my ($self, $args) = @_;
    my @results;
    for my $ref (__PACKAGE__->call_procedure(funcname => 'entity__list_locations',
                                           args => [$args->{entity_id}]))
    {
       next if ($args->{only_class})
               and ($args->{only_class} != $ref->{location_class});
        push @results, __PACKAGE__->new(%$ref);
    }
    return @results unless $args->{credit_id};

    for my $ref (__PACKAGE__->call_procedure(funcname => 'eca__list_locations',
                                           args => [$args->{credit_id}]))
    {
       next if ($args->{only_class})
               and ($args->{only_class} != $ref->{location_class});
        $ref->{credit_id} = $args->{credit_id};
        push @results, __PACKAGE__->new(%$ref);
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
    $self->call_dbmethod(funcname => $procname);
}

=item delete()

Deletes the current location

This can be called from $self->delete() if you have  a location object, or it
can be called as LedgerSMB::Entity::Location::delete($hashref) if the hashref
contains either entity_id or credit_id, and location_id, and location class.

=cut

sub delete{
    my ($ref) = @_;
    my $procname;
    my $args;
    if ($ref->{credit_id}){
        $procname = 'eca__delete_location';
        $args = [
           $ref->{credit_id}, $ref->{location_id}, $ref->{location_class}
        ];
    } else {
        $procname = 'entity__delete_location';
        $args = [
           $ref->{entity_id}, $ref->{location_id}, $ref->{location_class}
        ];
    }
    __PACKAGE__->call_procedure(funcname => $procname, args => $args );
}

=back

=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of the GNU General Public License version 2 or at your option any later
version.  Please see the enclosed LICENSE file for details.

=cut

__PACKAGE__->meta->make_immutable;

1;
