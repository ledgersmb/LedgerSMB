=head1 NAME

LedgerSMB::Timecard - Time and Materials Cards for LedgerSMB

=head1 SYNPOSIS

To get a timecard:

   my $timecard = LedgerSMB::Timecard->get($id);

To save a timecard:

   my $timecard = LedgerSMB::Timecard->new(%$request);
   $timecard->save;

=head1 DESCRIPTION

LedgerSMB::Timecard provides generalized routines for timecard storage and
retrieval.  Reporting is handled separately using LedgerSMB::Report::Timecards.

A timecard is actually a simple device that allows us to track the utilization
of a resource, whether time in the offering of a billable service, labor in the
manufacturing process, utilization of materials, and the like.  Heavy
manufacturing solutions are likely to use the timecard system extensively to
track scrapped utilized, utilized components, and the like.  Payroll systems may
use timecards to track worker's labor for both utilization purposes, and the
like.

=cut

package LedgerSMB::Timecard;
use Moose;
with 'LedgerSMB::PGObject';
use LedgerSMB::MooseTypes;


=head1 PROPERTIES

=over

=item id int

This is the internal id of the timecard.  Not set before saving

=cut

has 'id' => (isa => 'Int', is => 'rw', required => '0');

=item business_unit_id int

This is the int of the business unit attached.

=cut

has business_unit_id => (isa => 'Int', is => 'ro', required => '1');

=item bu_class_id int

The business unit class id.

=cut

has bu_class_id => (isa => 'Int', is => 'ro', required => 0);

=item parts_id int

This is the id of the part utilized (labor/overhead or service for time)

=cut

has parts_id => (isa => 'Int', is => 'ro', required => '1');

=item description text

The description field is typically used as a description of the work done and
may show up on reports or sales orders.

=cut

has description  => (isa => 'Str', is => 'ro', required => '0');

=item qty numeric

Quantity consumed

=cut

has qty => (isa => 'LedgerSMB::Moose::Number', is => 'ro', required => '1',
         coerce => 1);


=item allocated numeric

Quantities allocated for manufacturing, orders etc.

=cut

has allocated  => (isa => 'LedgerSMB::Moose::Number', is => 'ro',
              required => '0', coerce => 1);

=item sellprice numeric

This is the sell price in the master currency.

=cut

has sellprice => (isa => 'LedgerSMB::Moose::Number', is => 'ro',
             required => '0', coerce => 1);


=item fxsellprice numeric

This is the sell price in the foreign currency if applicable.

=cut

has fxsellprice => (isa => 'LedgerSMB::Moose::Number', is => 'ro',
               required => '0', coerce => 1);


=item serialnumber text

This is for use in recording the serial number of the part used.

=cut

has serialnumber => (isa => 'Str', is => 'ro', required => 0);

=item checkedin timestamp

Time and date work started

=cut

has checkedin  => (isa => 'LedgerSMB::Moose::Date', is => 'ro', required => '0',
                coerce => 1);

=item checkedout timestamp

Time and date work ended for this card

=cut

has checkedout  => (isa => 'LedgerSMB::Moose::Date', is => 'ro',
               required => '0', coerce => 1);

=item person_id int

This is the id for the person record for the employee adding the timecard.

If it is not entered it will default to the one who is logged in.

=cut

has person_id => (isa => 'Int', is => 'ro', required => '0');

=item notes str

=cut

has notes => (isa => 'Str', is => 'ro', required => '0');

=item total numeric

=cut

has total => (is => 'ro', isa => 'LedgerSMB::Moose::Number', required => 0,
          coerce => 1);

=item non_billable numeric

=cut

has non_billable => (is => 'ro', isa => 'LedgerSMB::Moose::Number',
               required => 1,  coerce => 1);

=item jctype int

This is the ID of the LedgerSMB::Timecard::Type that the timecard is of.

=cut

has jctype => (is => 'ro', isa => 'Int', required => 0);

=item curr str

=cut

has curr => (is => 'ro', isa => 'Str', required => 1);

=back

=head1 METHODS

=over

=item get($id int)

Retrieves the timecard with the specified ID and returns it.

=cut

sub get {
    my ($self, $id) = @_;
    my ($retval) = __PACKAGE__->call_procedure(
         funcname => 'timecard__get', args => [$id]);
    my ($buclass) = __PACKAGE__->call_procedure(
         funcname => 'timecard__bu_class', args => [$id]);

    $retval->{bu_class_id} = $buclass->{id};
    return __PACKAGE__->new(%$retval);
}

=item get_part_id($partnumber)

Returns the part id for the given partnumber

=cut

sub get_part_id {
    my ($self, $partnumber) = @_;
    my ($ref) = __PACKAGE__->call_procedure(
                    funcname => 'inventory__get_item_by_partnumber',
                        args => [$partnumber]
    );
    return $ref->{id};
}

=item save()

Saves the current timecard to the database, sets id.

=cut

sub save {
    my ($self) = @_;
    my ($ref) = $self->call_dbmethod(funcname => 'timecard__save');
    $self->id($ref->{id});
}

=item find_part({is_timecard bool, is_service bool, partnumber text})

Returns a list of parts matching the criteria requested

=cut

sub find_part {
    my ($self, $args) = @_;
    return __PACKAGE__->call_procedure(
                 funcname => 'timecard__part',
                     args => [$args->{is_timecard},
                              $args->{is_service},
                              $args->{partnumber}]);
}

=item allocate($amount numeric)

Adds $amount to the allocation amount of the timecard.

=cut

sub allocate {
    my ($self, $amount) = @_;
    $self->call_procedure(funcname => 'timecard__allocate',
                              args => [$self->id, $amount]);
}

=back

=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of the LedgerSMB General Public License version 2 or at your option any
later version.  Please see enclosed LICENSE file for details.

=cut

__PACKAGE__->meta->make_immutable;

1;
