
package LedgerSMB::Business_Unit;

=head1 NAME

LedgerSMB::Business_Unit - Accounting Reporting Dimensions for LedgerSMB

=head1 DESCRIPTION

This holds the information as to the handling of classes of buisness units.
Business units are reporting units which can be used to classify various line
items of transactions in different ways and include handling for departments,
funds, and projects.

=cut

use Moose;
use namespace::autoclean;
use LedgerSMB::MooseTypes;
with 'LedgerSMB::PGObject';

=head1 PROPERTIES

=over

=item id

This is the internal id of the unit class.  It is undef when the class has not
yet been saved in the database

=cut

has 'id' => (is => 'rw', isa => 'Maybe[Int]');

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

has 'description' => (is => 'rw', isa => 'Maybe[Str]');

=item start_date

The first date the business reporting unit is valid.  We use the PGDate class
here for conversion to/from input and to/from strings for the db.

=cut

has 'start_date' => (is => 'rw', isa => 'LedgerSMB::Moose::Date',
            coerce => 1);

=item end_date

The last date the business reporting unit is valid.  We use the PGDate class
here for conversion to/from input and to/from strings for the db.

=cut

has 'end_date' => (is => 'rw', isa => 'LedgerSMB::Moose::Date', coerce => 1);

=item parent_id

The internal id of the parent, if applicable.  undef means no parent.

=cut

has 'parent_id' => (is => 'rw', isa => 'Maybe[Int]');

=item parent

A reference to the parent business reporting unit

=cut

has 'parent' => (is => 'rw', isa => 'Maybe[LedgerSMB::Business_Unit]');

=item credit_id

The internal id of the customer, vendor, employee, etc. attached to this
unit.

=cut

has 'credit_id' => (is => 'rw', isa => 'Maybe[Int]');

=item children

The children of the current unit, if applicable, and desired.

This is not set unless get_tree has already been called.

=back

=cut

has 'children' => (is => 'rw', isa => 'Maybe[ArrayRef[LedgerSMB::Business_Unit]]');

=head1 METHODS

=over

=item get($id)

Returns the business reporting unit referenced by the id.

=cut

sub get {
    my ($self, $id) = @_;
    my ($unit) = $self->call_procedure(funcname => 'business_unit__get',
                                            args => [$id]
    );
    return $self->new(%$unit);
}

=item save

Saves the business reporting unit ot the database and updates changes to object.

=cut

sub save {
    my ($self) = @_;
    my ($ref) = $self->call_dbmethod(funcname => 'business_unit__save');
    $self = $self->new($ref);
    return $self;
}

=item list ($class_id, $credit_id, $strict, $active_on)

Lists all business reporting units active on $date, for $credit_id (or for all
credit_ids), and of $class.  Undef on date and credit_id match all rows.

=cut

sub list {
    my ($self, $class_id, $credit_id, $strict, $active_on) = @_;
    my @rows =  $self->call_procedure(funcname => 'business_unit__list_by_class',
                                      args => [$class_id, $active_on,
                                               $credit_id, $strict]);
    for my $row(@rows){
        $row = $self->new($row);
    }
    return @rows;
}

=item delete

Deletes the buisness reporting unit.  A unit can only be deleted if it has no
children and no transactions attached.

=cut

sub delete {
    my ($self) = @_;
    my ($ref) = $self->call_dbmethod(funcname => 'business_unit__delete');
    return;
}

=item search

Returns a list of buisness reporting units matching search criteria.

=item get_tree

Retrieves children recursively from the database and populates children
appropriately

=item tree_to_list

Returns tree as a list.

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

__PACKAGE__->meta->make_immutable;
1;
