=head1 NAME

LedgerSMB::Inventory::Adjust_Line - Inventory Adjustemnt Lines for LedgerSMB

=head1 SYNPOSIS

 my $line = LedgerSMB::Inventory::Adjust_Line->new(%$hashref);
 $line->check_variance($date);
 $line->save($adjustment_set_id);

=cut

package LedgerSMB::Inventory::Adjust_Line;
use Moose;
use LedgerSMB::MooseTypes;
with 'LedgerSMB::PGObject';

=head1 DESCRIPTION

This module provides the actual inventory check routines for inventory
adjustments.  This module handles things like checking expected values and the
like.

=head1 PROPERTIES

=over

=item parts_id int

This is the id of the part.  It is required on saving but not before then as
it may be looked up.

=cut

has parts_id => (is => 'rw', isa => 'Int', required => 0);

=item partnumber

This matches either the barcode or partnumber of the part.  If there is a
conflict, partnumber wins.  Note that this is an exact match, not a prefix
search.

=cut

has partnumber  => (is => 'rw', isa => 'Str', required => 0);

=item expected

This is the number expected.  If blank we will look up the expected amount from
the database during the check_variance method.

=cut

has expected => (is => 'rw', isa => 'LedgerSMB::Moose::Number', coerce => 1,
           required => 0);

=item counted

The number counted.  Obviously for a valid inventory count, we need to have
this....

=cut

has counted => (is => 'ro', isa => 'LedgerSMB::Moose::Number', coerce => 1,
          required => 1);

=item variance

This is the variance.  It is usually calculated during the variance check
or, if expected is set and variance not, on save.

=cut

has variance => (is => 'rw', isa => 'LedgerSMB::Moose::Number', coerce => 1,
           required => 1);

=item adjust_id int

This is the adjustment set id, usually set during the save process.

=cut

has adjust_id => (is => 'rw', isa => 'Int', required => 0);

=item counted_date date

This is the counted date, usually set during the variance check.

=cut

has counted_date => (is => 'rw', isa => 'LedgerSMB::Moose::Date', coerce => 1,
               required => 0);

=back

=head1 METHODS

=over

=item search_part($partnumber, $count_on)

This routine searches for a part based on partnumber and returns a hashref with
the parts_id and counted if it is found.  The $count_on parameter provides an
optional date which to use to calculate.  If none is provided, current date is
used.

=cut

sub search_part{
    my ($self, $partnumber, $count_on) = @_;
    my $ref;
    if ($partnumber){
        ($ref) = $self->call_procedure(
           funcname => 'inventory__search_part',
                args => [$partnumber, $count_on]
        );
    } else {
        die 'Bad call for search_part' if !$self->{parts_id};
        ($ref) = $self->call_dbmethod(funcname => 'inventory__search_part');
    }
    return $ref;
}

=item check_variance($date)

This routine calculates the variance and sets it as of the date provided.  Note
that if $self->expected is set, then that value is used instead of calculating
the value from the database.

=cut

sub check_variance {
    my ($self, $date) = @_;
    $self->counted_date($date);
    if (defined $self->expected){
        $self->variance($self->counted - $self->expected);
        return $self->variance;
    }
    my $ref;
    if ($self->parts_id){
       $ref = $self->search_part;
    } else {
       $ref = $self->search_part($self->partnumber, $date);
       $self->parts_id($ref->{parts_id});
    }
    $self->expected($ref->{expected});
    $self->variance($self->counted - $self->expected);
    return $self->variance;
}

=item save($adjustment_id)

Saves the adjustment to the report indicated.

=cut

sub save {
    my ($self, $adjustment_id) = @_;
    $self->adjust_id($adjustment_id);
    die 'No part specified' unless $self->parts_id;
    $self->check_variance unless defined $self->variance;
    $self->call_dbmethod(funcname => 'inventory_adjust__save_line');
}

=back

=head1 COPYRIGHT

COPYRIGHT (C) 2013 The LedgerSMB Core Team.  This file may be re-used under the
terms of the LedgerSMB General Public License version 2 or at your option any
later version.  Please see enclosed LICENSE file for details.

=cut

__PACKAGE__->meta->make_immutable;

1;
