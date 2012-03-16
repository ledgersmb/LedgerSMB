=head1 NAME 

LedgerSMB::DBObject::Entity::Credit_Account - Customer/Vendor Acct Management for LSMB

=head1 SYNOPSYS

This module provides customer/vendor credit account management features for
LedgerSMB.  These include credit limit, credit limit remaining, terms, discounts
and the like.

=head1 DESCRIPTION

TODO

=head1 INHERITS

=over

=item LedgerSMB::DBObject_Moose

=back

=cut

package LedgerSMB::DBObject::Entity::Credit_Account;
use Moose;
extends 'LedgerSMB::DBObject_Moose';

our $VERSION = '1.4.0';

=head1 PROPERTIES

=over

=item id

This is the internal, machine readable id.

=cut

has 'id' => (is => 'rw', isa => 'Maybe[Int]');

=item entity_id

The internal id for the entity to which this is attached.

=cut

has 'entity_id' => (is => 'ro', isa => 'Maybe[Int]');

=item entity_class

This is the entity class.  These are hard-coded values.  The main ones used here
are 1 for vendor and 2 for customer.

=cut

has 'entity_class' => (is => 'ro', isa => 'Maybe[Int]');

=item pay_to_name

This is the name that checks are written to or from.

=cut

has 'pay_to_name' => (is => 'rw', isa => 'Maybe[Str]');

=item discount

Early payment discount percent.

=cut

has 'discount' => (is => 'rw', isa => 'Maybe[LedgerSMB::PGNumber]');

=item description

This is the general description for the account.

=cut

has 'description' => (is => 'rw', isa => 'Maybe[Str]');

=item discount_terms

The number of days before the payment discount expires.

=cut

has 'discount_terms' => (is => 'rw', isa => 'Maybe[Int]');

=item discount_account_id

The id of the account that the discounts are tracked against.

=cut

has 'discount_account_id' => (is => 'rw', isa => 'Maybe[Int]');

=item taxincluded

Whether taxes are included by default.

=cut

has 'taxincluded' => (is => 'rw', isa => 'Maybe[Bool]');

=item creditlimit

The total debt that is acceptable for the account

=cut

has 'creditlimit' => (is => 'rw', isa => 'Maybe[LedgerSMB::PGNumber]');

=item current_debt

This is a number that represents the amount of debt currently carried.  This is
not populated by a simple retrieve since it is a somewhat performance sensitive
operation.  Use get_current_debt() to set it.

=cut

has 'current_debt' => (is => 'rw', isa => 'Maybe[LedgerSMB::PGNumber]');

=item terms

This is the number of days before an invoice is considered overdue.

=cut

has 'terms' => (is => 'rw', isa => 'Maybe[Int]');

=item meta_number

This is the human readable account number.

=cut

has 'meta_number' => (is => 'rw', isa => 'Maybe[Str]');

=item business_id

This is the id of the business type.

=item business_type

This is the name of the business type associated.

=cut

has 'business_id'   => (is => 'rw', isa => 'Maybe[Int]');
has 'business_type' => (is => 'rw', isa => 'Maybe[Str]');

=item language_code

This is the standard language code to set for communications to the customer or
vendor.  This allows us to print localized invoices.  Values are ones such as
'en_US'.

=cut

has 'language_code' => (is => 'rw', isa => 'Maybe[Str]');

=item pricegroup_id

This is the numeric id of the pricegroup in which the customer is placed.  It
has no effect for vendors.

=cut

has 'pricegroup_id' => (is => 'rw', isa => 'Maybe[Int]');

=item curr

The currency to use for billing this customer or for bills received from this
vendor.

=cut

has 'curr' => (is => 'ro', isa => 'Maybe[Str]');

=item startdate

The first allowed date for invoices.

=item enddate

The last allowable date for invoices

=cut

has 'startdate' => (is => 'rw', isa => 'Maybe[LedgerSMB::PGDate]');
has 'enddate'   => (is => 'rw', isa => 'Maybe[LedgerSMB::PGDate]');

=item threshold

Do not show invoices as available for payment/receipt until over this threshold

=cut

has 'threshold' => (is => 'rw', isa => 'Maybe[LedgerSMB::PGNumber]');

=item employee_id

This is the ID for the salesman who is attached to the credit account.  Used by
some for commissions calculations and the like

=cut

has 'employee_id' => (is => 'rw', isa => 'Maybe[Int]');

=item ar_ap_account_id

The id for the AR or AP account, use for payment reversals.  Required on save.

=cut

has 'ar_ap_account_id' => (is => 'rw', isa => 'Maybe[Int]');

=item cash_account_id

The id that is the default for the cash account.

=cut

has 'cash_account_id' => (is => 'rw', isa => 'Maybe[Int]');

=item bank_account

This is a link to the bank account record.  Note that multiple bank accounts can
be linked to an entity, but only one can be primary, for things like payments by
wire or ACH.

=item tax_ids

This is an arrayref of ints for the tax accounts linked to the customer.

=cut

has 'tax_ids' => (is => 'rw', isa => 'Maybe[ArrayRef[Int]]');

=cut

has 'bank_account' => (is => 'rw', isa => 'Maybe[Int]');

=item taxform_id   

This is the tax reporting form associated with the account.

=cut

has 'taxform_id' => (is => 'rw', isa => 'Maybe[Int]');

=back

=head1 METHODS

=over

=item prepare_input($hashref)

Takes all PGNumber and PGDate inputs and constructs appropriate classes.

=cut

sub prepare_input {
    my ($self, $request) = @_;

    $request->{startdate} =
       LedgerSMB::PGDate->from_input($request->{startdate}) 
            if defined $request->{startdate};
    $request->{enddate} =
       LedgerSMB::PGDate->from_input($request->{enddate}) 
            if defined $request->{enddate};
    $request->{discount} = 
       LedgerSMB::PGNumber->from_input($request->{discount})
            if defined $request->{discount};
    $request->{threshold} = 
       LedgerSMB::PGNumber->from_input($request->{threshold})
            if defined $request->{threshold};
    $request->{creditlimit} = 
       LedgerSMB::PGNumber->from_input($request->{creditlimit})
            if defined $request->{creditlimit};
}

=item get_by_id($id int);

Retrieves and returns the entity credit account corresponding with the id 
mentioned.

=cut

sub get_by_id {
    my ($self, $id) = @_;
    my ($ref) = $self->call_procedure(procname => 'entity_credit__get',
                                          args => [$id]);
    $self->prepare_dbhash($ref);
    return $self->new(%$ref);
}

=item get_by_meta_number($meta_number string, $entity_class int)

Retrieves and returns the entity credit account, of entity class $entity_class, 
identified by $meta_number

=cut

sub get_by_meta_number {
    my ($self, $meta_number, $entity_class) = @_;
    my ($ref) = $self->call_procedure(procname => 'eca__get_by_met_number',
                                          args => [$meta_number, 
                                                   $entity_class]);
    $self->prepare_dbhash($ref);
    return $self->new(%$ref);
}

=item list_for_entity($entity_id int, [$entity_class int]);

Returns a list of entity credit accounts for the entity (company or person)
identified by $entity_id

=cut

sub list_for_entity {
    my ($self, $entity_id, $entity_class) = @_;
    my @results = $self->call_procedure(procname => 'entity__list_credit',
                                            args => [$entity_id, $entity_class]
    );
    for my $ref (@results){
        $self->prepare_dbhash($ref);
        $ref = $self->new(%$ref);
    }
    return @results;
}

=item get_current_debt()

Sets $self->current_debt and returns the same value.

=cut

sub get_current_debt {
    my ($self) = @_;
    my ($ref) = $self->exec_method({funcname => 'eca__get_current_debt'});
    $self->current_debt($ref->{eca__get_current_debt});
    return $self->current_debt;
}

=item save()

Saves the entity credit account.  This also sets db defaults if not set.

=cut

sub save {
    my ($self) = @_;
    my ($ref) = $self->exec_method({funcname => 'eca__save'});
    $self->prepare_dbhash($ref);
    $self = $self->new(%$ref);
}


=head1 COPYRIGHT

Copyright (C) 2012 The LedgerSMB Core Team. This file may be reused under the 
terms of the GNU General Public License version 2 or at your option any later 
version.  Please see the attached LICENSE file for details.

=cut

__PACKAGE__->meta->make_immutable;

return 1;
