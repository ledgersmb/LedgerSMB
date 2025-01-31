
package LedgerSMB::Entity::Credit_Account;

=head1 NAME

LedgerSMB::Entity::Credit_Account - Customer/Vendor Acct Management for LSMB

=head1 SYNOPSIS

To get by ID:

 my $eca = LedgerSMB::Entity::Credit_Account->get_by_id($id);

To get by customer/vendor number:

 my $eca = LedgerSMB::Entity::Credit_Account
     ->new(dbh => $dbh, entity_class => $entity_class)
     ->get_by_meta_number($customernumber);

To save

 $eca->save;

=head1 DESCRIPTION

This module provides customer/vendor credit account management features for
LedgerSMB.  These include credit limit, credit limit remaining, terms, discounts
and the like.


=cut

use Moose;
use namespace::autoclean;
use LedgerSMB::MooseTypes;
with 'LedgerSMB::PGObject';

our $VERSION = '1.4.0';

=head1 PROPERTIES

=over

=item id

This is the internal, machine readable id.

=cut

has 'id' => (is => 'rw', isa => 'Int', required => 0);

=item entity_id

The internal id for the entity to which this is attached.

=cut

has 'entity_id' => (is => 'ro', isa => 'Int', required => 0);

=item entity_class

This is the entity class.  These are hard-coded values.  The main ones used here
are 1 for vendor and 2 for customer.

=cut

has 'entity_class' => (is => 'ro', isa => 'Int', required => 1);

=item pay_to_name

This is the name that checks are written to or from.

=cut

has 'pay_to_name' => (is => 'rw', isa => 'Maybe[Str]', required => 0);

=item discount

Early payment discount percent.

=cut

has 'discount' => (is => 'rw', isa => 'LedgerSMB::PGNumber');

=item description

This is the general description for the account.

=cut

has 'description' => (is => 'rw', isa => 'Maybe[Str]', required => 0);

=item discount_terms

The number of days before the payment discount expires.

=cut

has 'discount_terms' => (is => 'rw', isa => 'Maybe[Int]', required => 0);

=item discount_account_id

The id of the account that the discounts are tracked against.

=cut

has 'discount_account_id' => (is => 'rw', isa => 'Maybe[Int]', required => 0);

=item taxincluded

Whether taxes are included by default.

=cut

has 'taxincluded' => (is => 'rw', isa => 'Bool');

=item creditlimit

The total debt that is acceptable for the account

=cut

has 'creditlimit' => (is => 'rw', isa => 'LedgerSMB::PGNumber');

=item current_debt

This is a number that represents the amount of debt currently carried.  This is
not populated by a simple retrieve since it is a somewhat performance sensitive
operation.  Use get_current_debt() to set it.

=cut

has 'current_debt' => (is => 'rw', isa => 'LedgerSMB::PGNumber',
                       lazy => 1, builder => 'get_current_debt');

=item terms

This is the number of days before an invoice is considered overdue.

=cut

has 'terms' => (is => 'rw', isa => 'Maybe[Int]', required => 0);

=item meta_number

This is the human readable account number.

=cut

has 'meta_number' => (is => 'rw', isa => 'Str', required => 0);

=item business_id

This is the id of the business type.

=item business_type

This is the name of the business type associated.

=cut

has 'business_id'   => (is => 'rw', isa => 'Maybe[Int]', required => 0);
has 'business_type' => (is => 'rw', isa => 'Maybe[Str]', required => 0);

=item language_code

This is the standard language code to set for communications to the customer or
vendor.  This allows us to print localized invoices.  Values are ones such as
'en_US'.

=cut

has 'language_code' => (is => 'rw', isa => 'Str', required => 0);

=item pricegroup_id

This is the numeric id of the pricegroup in which the customer is placed.  It
has no effect for vendors.

=cut

has 'pricegroup_id' => (is => 'rw', isa => 'Maybe[Int]', required => 0);

=item curr

The currency to use for billing this customer or for bills received from this
vendor. This field is required for customers, vendors and employees.

Note: we *want* to make this field required (in the database too), but due to
its use for non-financial counterparties (hot/cold leads, etc), for which no
currency is required, we can't (yet) make it so.

=cut

has 'curr' => (is => 'ro', isa => 'Str');

=item startdate

The first allowed date for invoices.

=item enddate

The last allowable date for invoices

=cut

has 'startdate' => (is => 'rw', isa => 'LedgerSMB::PGDate');
has 'enddate'   => (is => 'rw', isa => 'LedgerSMB::PGDate');

=item threshold

Do not show invoices as available for payment/receipt until over this threshold

=cut

has 'threshold' => (is => 'rw', isa => 'LedgerSMB::PGNumber');

=item employee_id

This is the ID for the salesman who is attached to the credit account.  Used by
some for commissions calculations and the like

=cut

has 'employee_id' => (is => 'rw', isa => 'Int', required => 0);

=item ar_ap_account_id

The id for the AR or AP account, use for payment reversals.  Required on save.

=cut

has 'ar_ap_account_id' => (is => 'rw', isa => 'Int');

=item cash_account_id

The id that is the default for the cash account.

=cut

has 'cash_account_id' => (is => 'rw', isa => 'Maybe[Int]', required => 0);

=item bank_account

This is a link to the bank account record.  Note that multiple bank accounts can
be linked to an entity, but only one can be primary, for things like payments by
wire or ACH.

=item tax_ids

This is an arrayref of ints for the tax accounts linked to the customer.

=cut

has 'tax_ids' => (is => 'rw', isa => 'ArrayRef[Int]', required => 0);

=item bank_account

Bank account for the credit account

=cut

has 'bank_account' => (is => 'rw', isa => 'Maybe[Int]', required => 0);

=item taxform_id

This is the tax reporting form associated with the account.

=cut

has 'taxform_id' => (is => 'rw', isa => 'Maybe[Int]', required => 0);

=item is_used

Boolean indicating whether the credit account is used (and therefor not
deletable).

=cut

has 'is_used' => (is => 'ro', isa => 'Bool', required => 0);

=back

=head1 METHODS

=over

=item get_by_id($id int);

Retrieves and returns the entity credit account corresponding with the id
mentioned.

=cut

sub get_by_id {
    my ($self, $id) = @_;
    my ($ref) = __PACKAGE__->call_procedure(funcname => 'entity_credit__get',
                                          args => [$id]);
    $ref->{tax_ids} = $self->_get_tax_ids($id);
    for (keys %$ref) {
        delete $ref->{$_}
        if ! defined $ref->{$_};
    }
    return __PACKAGE__->new(%$ref);
}

=item get_by_meta_number($meta_number string)

Retrieves and returns the entity credit account, of entity class $entity_class,
identified by $meta_number

=cut

sub get_by_meta_number {
    my ($self, $meta_number) = @_;
    my $entity_class = $self->entity_class;
    my ($ref) = $self->call_procedure(funcname => 'eca__get_by_meta_number',
                                          args => [$meta_number,
                                                   $entity_class]);
    $ref->{tax_ids} = $self->_get_tax_ids($ref->{id});
    return __PACKAGE__->new(dbh => $self->{_dbh},
                            entity_class => $entity_class,
                            %$ref);
}

# Private methid _get_tax_ids
# returns an array ref of chart ids for the taxes.

sub _get_tax_ids {
    my ($self, $id) = @_;
    my @tax_ids;
    my @results = $self->call_procedure(funcname => 'eca__get_taxes',
                                            args => [$id]);
    for my $ref (@results){
        push @tax_ids, $ref->{chart_id};
    }
    return \@tax_ids
}

=item list_for_entity($entity_id int, [$entity_class int]);

Returns a list of entity credit accounts for the entity (company or person)
identified by $entity_id

=cut

sub list_for_entity {
    my ($self, $entity_id, $entity_class) = @_;
    my @results = __PACKAGE__->call_procedure(funcname => 'entity__list_credit',
                                            args => [$entity_id, $entity_class]
    );
    for my $ref (@results){
        $ref->{tax_ids} = $self->_get_tax_ids($ref->{id});
        for (keys %$ref) {
            delete $ref->{$_}
               if ! defined $ref->{$_};
        }
        $ref = __PACKAGE__->new(%$ref);
    }
    return @results;
}

=item get_current_debt()

Sets $self->current_debt and returns the same value.

=cut

sub get_current_debt {
    my ($self) = @_;
    my ($ref) = $self->call_dbmethod(funcname => 'eca__get_current_debt');
    $self->current_debt($ref->{eca__get_current_debt});
    return $self->current_debt;
}

=item del()

Removes the entity credit account.

=cut

sub del {
    my ($self) = @_;

    $self->call_dbmethod(funcname => 'eca__delete');
}

=item save()

Saves the entity credit account.  This also sets db defaults if not set.

=cut

sub save {
    my ($self) = @_;
    die 'No AR/AP Account ID Set' unless $self->ar_ap_account_id;
    my ($ref) = $self->call_dbmethod(funcname => 'eca__save');
    $self->{id}=$ref->{eca__save};
    $self->call_dbmethod(funcname => 'eca__set_taxes');
    return $self->get_by_id($ref->{eca__save});
}

=item get_pricematrix

This routine gets the price matrix for the customer or vendor.  This returns a
hashref with up to two keys:  pricematrix for all vendors and customers, and
pricematrix_pricegroup for customers.

=cut

sub get_pricematrix {
    my $self = shift @_;
    my $retval = {};
    @{$retval->{pricematrix}} = $self->call_procedure(
               funcname => 'eca__get_pricematrix',
        args => [$self->{id}]
    );
    if ($self->{entity_class} == 1){
        @{$retval->{pricematrix_pricegroup}}= $self->call_procedure(
               funcname => 'eca__get_pricematrix_by_pricegroup',
        args => [$self->{id}]
        );
    }
    return $retval;
}

=item delete_pricematrix($entry_id)

This deletes a pricematrix line identified by $entry_id

=cut

sub delete_pricematrix {
    my $self = shift @_;
    my ($entry_id) = @_;
    my ($retval) = $self->call_procedure(funcname => 'eca__delete_pricematrix',
                           args => [$self->credit_id, $entry_id]
    );
    return $retval;
}


=item save_pricematrix

Updates or inserts the price matrix.

=cut

sub save_pricematrix {
    my ($self, $request)  = @_;
    for my $count (1 .. $request->{pm_rowcount}){
        my $entry_id = $request->{"pm_$count"};
        my @args = ();
        for my $prop (qw(parts_id credit_id pricebreak price lead_time
                         partnumber validfrom validto curr entry_id)){
            push @args, $request->{"${prop}_$entry_id"};
            $self->call_procedure(funcname => 'eca__save_pricematrix',
                                      args => \@args);
        }
    }
    return;
}


=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012-2023 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

__PACKAGE__->meta->make_immutable;

1;
