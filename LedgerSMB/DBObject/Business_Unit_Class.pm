=head1 NAME

LedgerSMB::DBObject::Business_Unit_Class

=head1 SYNOPSYS

This holds the information as to the handling of classes of buisness units.  
Business units are reporting units which can be used to classify various line 
items of transactions in different ways and include handling for departments, 
funds, and projects.

=cut

package LedgerSMB::DBObject::Business_Unit_Class;
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

=item label

This is the human-readible label for the class.  It must be unique among
classes.

=cut

has 'label' => (is => 'rw', isa => 'Str');

=item active bool

If true, indicates that this will show up on screens.  If not, it will be
hidden.

=cut

has 'active' => (is => 'rw', isa => 'Bool');

# Hmm should we move this to per-module restrictions? --CT

=item non_accounting bool

If true, indicates that this will not show up on accounting transaction screens.
this is indivated for CRM and other applications.

=cut

has 'non_accounting' => (is => 'rw', isa => 'Bool');

=item ordering 

The entry boxes (drop down or text entry) are set arranged from low to high
by this field on the data entry screens.

=cut

has 'ordering' => (is => 'rw', isa => 'Int');

=back

=head1 METHODS

=over

=item get($id)

returns the business unit class that corresponds to the id requested.

=cut

sub get {
    my ($self, $id) = @_;
    my @classes = $self->call_procedure(procname => 'business_unit_class__get', 
                                            args => [$id]
    );
    return $self->new(shift @classes);
}

=item save

Saves the existing buisness unit class to the database, and updates any fields 
changed in the process.

=cut

sub save {
    my ($self) = @_;
    my ($ref) = $self->exec_method({funcname => 'business_unit_class__save'});
    $self = $self->new($ref);
}   

=item list

Returns a list of all business unit classes.

=cut

sub list {
    my ($self) = @_;
    my @classes = $self->exec_method({funcname => 'business_unit_class__list'});
    for my $class (@classes){
        $class = $self->new($class);
    }
    return @classes;
}

=item delete

Deletes a business unit class.  Such classes may not have business units attached.

=cut
 
sub delete {
    my ($self) = @_;
    my ($ref) = $self->exec_method({funcname => 'business_unit_class__delete'});
}   

=back

=head1 PREDEFINED CLASSES

=over

=item Department, ID: 1

=item Project, ID: 2

=item Job, ID: 3

Used for manufacturing lots

=item Fund, ID: 4

Used by non-profits for funds accounting

=item Customer, ID 5

Used in some countries/industries for multi-customer receipts

=item Vendor, ID 6

Used in some countries/industries for multi-vendor payments

=head1 COPYRIGHT

Copyright (C) 2012 The LedgerSMB Core Team.  This module may be used under the
GNU GPL in accordance with the LICENSE file listed.

=cut

1;
