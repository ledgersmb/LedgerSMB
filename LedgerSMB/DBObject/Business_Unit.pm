=head1 NAME

LedgerSMB::DBObject::Business_Unit_Class

=head1 SYNOPSYS

This holds the information as to the handling of classes of buisness units.  
Business units are reporting units which can be used to classify various line 
items of transactions in different ways and include handling for departments, 
funds, and projects.

=cut

package LedgerSMB::DBObject::Business_Unit;
use Moose;
use LedgerSMB::DBObject_Moose;
extends 'LedgerSMB::DBObject_Moose';

=head1 PROPERTIES

=over

=item id

This is the internal id of the unit class.  It is undef when the class has not
yet been saved in the database 

=cut

has 'id' => (is => 'rw', isa => 'Int');

=item class_id

Required. Internal id of class (1 for department, 2 for project, etc)

=cut

has 'class_id' => (is => 'ro', isa => 'Int', required => '1'); 

=item control_code  

This is a textual reference to the business reporting unit.  It must be unique
to the business units of its class.

=cut

has 'control_code' => (is => 'ro', isa => 'Str', required => '1');

=item description

Textual description of the reporting unit.

=cut

has 'description' => (is => 'rw', isa => 'Str');

=item start_date

The first date the business reporting unit is valid.  We use the PGDate class
here for conversion to/from input and to/from strings for the db.

=cut

has 'start_date' => (is => 'rw', isa => 'LedgerSMB::PGDate');

=item end_date

The last date the business reporting unit is valid.  We use the PGDate class
here for conversion to/from input and to/from strings for the db.

=cut

has 'end_date' => (is => 'rw', isa => 'LedgerSMB::PGDate');

=item parent_id

The internal id of the parent, if applicable.  undef means no parent.

=cut

has 'parent_id' => (is => 'rw', isa => 'Int');

=item parent

A reference to the parent business reporting unit

=cut

has 'parent' => (is => 'rw', isa => 'LedgerSMB::DBObject::Business_Unit');

=item credit_id

The internal id of the customer, vendor, employee, etc. attached to this 
unit.

=cut

has 'credit_id' => (is => 'rw', isa => 'Int');

=item children

The children of the current unit, if applicable, and desired.

This is not set unless get_tree has already been called.

=back

=cut

has 'children' => (is => 'rw', isa => 'ArrayRef[LedgerSMB::DBObject::Business_Unit]');

=head1 METHODS

=over

=item get($id)

Returns the business reporting unit referenced by the id.

=cut

sub get {
    my ($self, $id) = @_;
    my @units = $self->call_procedure(procname => 'business_unit__get',
                                            args => [$id]
    );
    return $self->new(shift @units);
} 

=item save

Saves the business reporting unit ot the database and updates changes to object.

=cut

sub save {
    my ($self) = @_;
    my ($ref) = $self->exec_method({funcname => 'business_unit__save'});
    $self = $self->new($ref);
}   

=item list ($date, $credit_id, $class)

Lists all business reporting units active on $date, for $credit_id (or for all
credit_ids), and of $class.  Undef on date and credit_id match all rows.

=item delete

Deletes the buisness reporting unit.  A unit can only be deleted if it has no 
children and no transactions attached.

=cut

sub delete {
    my ($self) = @_;
    my ($ref) = $self->exec_method({funcname => 'business_unit__delete'});
}   

=item search

Returns a list of buisness reporting units matching search criteria.

=item get_tree

Retrieves children recursively from the database and populates children 
appropriately

=item tree_to_list

Returns tree as a list.
 
=back

=head1 COPYRIGHT

Copyright (C) 2012 The LedgerSMB Core Team.  This module may be used under the
GNU GPL in accordance with the LICENSE file listed.

=cut

__PACKAGE__->meta->make_immutable;
1;
