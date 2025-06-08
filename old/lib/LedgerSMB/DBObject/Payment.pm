
=head1 NAME

LedgerSMB::DBOject::Payment - Payment Handling Back-end Routines for LedgerSMB

=head1 SYNOPSIS

Provides the functions for generating the data structures payments made in
LedgerSMB.   This module currently handles only basic payment logic, and does
handle overpayment logic, though these features will be moved into this module
in the near future.

=head1 COPYRIGHT

Copyright (c) 2007-2020 The LedgerSMB Core Team.  Licensed under the GNU
General Public License version 2 or at your option any later version.  Please
see the included COPYRIGHT and LICENSE files for more information.

=cut

package LedgerSMB::DBObject::Payment;
use base qw(LedgerSMB::PGOld);
use strict;
use warnings;
use LedgerSMB::PGNumber;

use LedgerSMB::Magic qw(BC_PAYMENT);

our $VERSION = '0.1.0';

=head1 METHODS

=over

=item LedgerSMB::DBObject::Payment->new()

Inherited from LedgerSMB::DBObject.  Please see that documnetation for details.

=item $payment->get_open_accounts()

This function returns a list of open accounts depending on the
$payment->{account_class} property.  If this property is 1, it returns a list
of vendor accounts, for 2, a list of customer accounts are returned.

The returned list of hashrefs is stored in the $payment->{accounts} property.
Each hashref has the following keys:  id (entity id), name, and entity_class.

An account is considered open if there are outstanding, unpaid invoices
attached to it.  Customer/vendor payment threshold is not considered for this
calculation.

=back

=over

=item get_metadata()

Prepares the object for other tasks, such as displaying payment options.

Requires that the following object properties be defined:

  * dbh
  * account_class
  * batch_id
  * payment_type_id (optional)

Sets the following object properties:

  * currencies
  * default_currency
  * businesses
  * payment_types
  * debt_accounts
  * cash_accounts
  * batch_date
  * all_years

Additionally if payment_type_id is set:

  * payment_type_label_id
  * payment_type_return_id
  * payment_type_return_label

=back

=cut

sub get_metadata {
    my ($self) = @_;

    $self->get_default_currency;
    $self->get_open_currencies();
    $self->{currencies} = [];
    for my $c (@{$self->{openCurrencies}}) {
        push @{$self->{currencies}}, $c->{payments_get_open_currencies};
    }

    @{$self->{all_years}} = $self->call_procedure(
        funcname => 'date_get_all_years'
    );

    @{$self->{businesses}} = $self->call_dbmethod(
        funcname => 'business_type__list'
    );

    @{$self->{payment_types}} = $self->call_dbmethod(
        funcname => 'payment_type__list'
    );

    if ($self->{payment_type_id}) {
       @{$self->{payment_type_label_id}} = $self->call_dbmethod(
           funcname => 'payment_type__get_label'
       );

       $self->{payment_type_return_id}    = $self->{payment_type_label_id}->[0]->{id};
       $self->{payment_type_return_label} = $self->{payment_type_label_id}->[0]->{label};
    }

    @{$self->{debt_accounts}} = $self->call_dbmethod(
        funcname => 'chart_get_ar_ap'
    );

    @{$self->{cash_accounts}} = $self->call_dbmethod(
        funcname => 'chart_list_cash'
    );
    for my $ref(@{$self->{cash_accounts}}) {
        $ref->{text} = "$ref->{accno}--$ref->{description}";
    }

    if ($self->{batch_id}) {
        my ($ref) = $self->call_dbmethod(funcname => 'voucher_get_batch');
        $self->{batch_date} = $ref->{default_date};
    }

    return;
}

=over

=item search()

Seturns a series of payments matching the search criteria.

Search results are also stored at $payment->{search_results}.

=back

=cut

sub search {
    my ($self) = @_;
    if ($self->{meta_number} && !$self->{credit_id}){
        my ($ref) = $self->call_dbmethod(
        funcname => 'entity_credit_get_id_by_meta_number'
        );
        my @keys = keys %$ref;
        my $key = shift @keys;
        $self->{credit_id} = $ref->{$key};
    }
    @{$self->{search_results}} = $self->call_dbmethod(
        funcname => 'payment__search'
    );
    return @{$self->{search_results}};
}

=over

=item get_open_accounts()

Returns a list of open accounts for the payment operation.

These are also stored on $payment->{accounts}

=back

=cut

sub get_open_accounts {
    my ($self) = @_;
    @{$self->{accounts}} =
        $self->call_dbmethod(funcname => 'payment_get_open_accounts');
    return @{$self->{accounts}};
}


=over

=item $payment->get_entity_credit_account()

Returns billing information for the current account, and saves it to an arrayref
at $payment->{entity_accounts}/

=back

=cut

sub get_entity_credit_account{
  my ($self) = @_;

  # This is ugly but not sure what else to do for the moment.  Looking at
  # refactoring later.  -CT
  if ($self->{credit_id}){
    @{$self->{entity_accounts}} =
      $self->call_dbmethod(funcname => 'payment_get_entity_account_payment_info');
   } else {
     @{$self->{entity_accounts}} =
        $self->call_dbmethod(funcname => 'payment_get_entity_accounts');
   }
   return  @{$self->{entity_accounts}};
}


=over

=item $payment->get_all_accounts()

This function returns a list of open or closed accounts depending on the
$payment->{account_class} property.  If this property is 1, it returns a list
of vendor accounts, for 2, a list of customer accounts are returned.

The returned list of hashrefs is stored in the $payment->{accounts} property.
Each hashref has the following keys:  id (entity id), name, and entity_class.

=back

=cut

sub get_all_accounts {
    my ($self) = @_;
    @{$self->{accounts}} =
        $self->call_dbmethod(funcname => 'payment_get_all_accounts');
    return @{$self->{accounts}};
}
=over

=item $payment->reverse()

This function reverses a payment identified by C<payment_id> (passed upon
object instantiation).

=back

=cut

sub reverse {
    my ($self) = @_;
    return $self->call_dbmethod(funcname => 'payment__reverse');
}

=over

=item $payment->get_open_invoices()

This function returns a list of open invoices depending on the
$payment->{account_class}, $payment->{entity_id}, and $payment->{curr}
properties.  Account classes follow the conventions above.  This list is hence
specific to a customer or vendor and currency as well.

The returned list of hashrefs is stored in the $payment->{open_invoices}
property. Each hashref has the following keys:  invoice_id int, invnumber text,
invoice bool, invoice_date date, amount numeric, amount_fx numeric,
discount numeric, discount_fx numeric, due numeric, due_fx numeric,
 exchangerate numeric


=back

=cut

sub get_open_invoices {
    my ($self) = @_;
    @{$self->{open_invoices}} =
        $self->call_dbmethod(funcname => 'payment_get_open_invoices');
    return @{$self->{open_invoices}};
}

=over

=item $payment->get_open_invoice()

This function is an especific case of get_open_invoices(), because get_open_invoice()
can search for a specific invoice, which can be searched by the $payment->{invnumber}
variable

=back

=cut

sub get_open_invoice {
    my ($self) = @_;
    @{$self->{open_invoice}} =
        $self->call_dbmethod(funcname => 'payment_get_open_invoice');
    return @{$self->{open_invoice}};
}




=over

=item $payment->get_all_contact_invoices()

This function returns a list of open accounts depending on the
$payment->{account_class} property.  If this property is 1, it returns a list
of vendor accounts, for 2, a list of customer accounts are returned.  Attached
to each account is a list of open invoices.  The data structure is somewhat
complex.

Each item in the list has the following keys: contact_id, contact_name, \
account_number, total_due, and invoices.

The invoices entry is a reference to an array of hashrefs.  Each of these
hashrefs has the following keys: invoice_id, invnumber, invoice_date, amount,
discount, and due.

These are filtered based on the (required) properties:
$payment->{account_class}, $payment->{business_type}, $payment->{date_from},
$payment->{date_to}, and $payment->{ar_ap_accno}.

The $payment->{ar_ap_accno} property is used to filter out by AR or AP account.

The following can also be optionally passed: $payment->{batch_id}.  If this is
patched, vouchers in the current batch will be picked up as well.

The returned list of hashrefs is stored in the $payment->{contact} property.
Each hashref has the following keys:  id (entity id), name, and entity_class.

=back

=cut

sub get_all_contact_invoices {
    my ($self) = @_;
    @{$self->{contacts}} =
        $self->call_dbmethod(funcname => 'payment_get_all_contact_invoices');

    # When arrays of complex types are supported by all versions of Postgres
    # that this application supports, we should look at doing type conversions
    # in DBObject so this sort of logic is unncessary. -- CT
    for my $contact (@{$self->{contacts}}){
        my @invoices = $self->parse_array($contact->{invoices});
        my $processed_invoices = [];
        for my $invoice (@invoices){
            my $new_invoice = {};
            for (qw(invoice_id invnumber invoice_date amount discount due)){
                 $new_invoice->{$_} = shift @$invoice;
                 if ($_ =~ /^(amount|discount|due)$/){
                     $new_invoice->{$_} =
                          LedgerSMB::PGNumber->new($new_invoice->{$_});
                 }
            }
            push(@$processed_invoices, $new_invoice);
        }
        #$contact->{invoice} = sort { $a->{invoice_date} cmp $b->{invoice_date} } @{ $processed_invoices };
        my @sorted = sort { $a->{invoice_date} cmp $b->{invoice_date} } @{ $processed_invoices };
        $contact->{invoice} = $sorted[0];
        $contact->{invoice} = $processed_invoices;
    }
    return @{$self->{contacts}};
}

=over

=item get_open_currencies

This method gets a list of the open currencies inside the database, it requires that
$self->{account_class} (must be 1 or 2)  exist to work.

WARNING THIS IS NOT BEING USED BY THE SINGLE PAYMENT SYSTEM....

=back

=cut

sub get_open_currencies {
  my ($self) = shift @_;
  @{$self->{openCurrencies}} = $self->call_dbmethod( funcname => 'payments_get_open_currencies');
  return @{$self->{openCurrencies}};
}


=over

=item list_accounting

This method lists all accounts that match the role specified in account_class property and
are available to store the payment or receipts.

=cut

sub list_accounting {
 my ($self) = @_;
 @{$self->{pay_accounts}} = $self->call_dbmethod( funcname => 'chart_list_cash');
 return @{$self->{pay_accounts}};
}

=item list_overpayment_accounting

This method lists all accounts that match the role specified in account_class property and
are available to store an overpayment / advanced payment / pre-payment.

=cut

sub list_overpayment_accounting {
 my ($self) = @_;
 @{$self->{overpayment_accounts}} = $self->call_dbmethod( funcname => 'chart_list_overpayment');
 return @{$self->{overpayment_accounts}};
}


=item get_default_currency

This method gets the default currency from the database (as a three-character
currency code), setting the object's C<default_currency> property to this
value.

Returns:
The three-character default currency code (e.g. 'USD').

=cut

sub get_default_currency {
    my ($self) = shift @_;

    my $result = $self->call_procedure(
        funcname => 'defaults_get_defaultcurrency'
    );

    $self->{default_currency} = $result->{defaults_get_defaultcurrency};
    return $self->{default_currency};
}

=item get_vc_info

This method returns the contact informatino for a customer or vendor according to
$self->{account_class}

=cut

sub get_vc_info {
 my ($self) = @_;
 my $temp = $self->{"id"};
 $self->{"id"} = $self->{"entity_credit_id"};
 @{$self->{vendor_customer_info}} = $self->call_dbmethod(funcname => 'company_get_billing_info');
 $self->{"id"} = $temp;
 return ${$self->{vendor_customer_info}}[0];
}

=item get_payment_detail_data($request)

This method calls C<get_metadata()> to populate various object properties.
See that method's documentation for details.

Additionally a set of contact invoices properties are set,
filtered according to the supplied parameters.

C<$request> is a L<LedgerSMB> request object.

Required request parameters:

  * dbh
  * account_class [1|2]
  * batch_id

Optionally accepts the following filtering parameters:

  * currency [e.g. 'GBP']
  * ar_ap_accno
  * meta_number

Though the following filtering parameters appear to be available,
they are not supported by the underlying C<payment_get_all_contact_invoices>
database query:

  * business_id
  * date_from
  * date_to

=cut

sub get_payment_detail_data {
    my ($self) = @_;
    $self->get_metadata();

    @{$self->{contact_invoices}} = $self->call_dbmethod(
        funcname => 'payment_get_all_contact_invoices');

    for my $inv (@{$self->{contact_invoices}}) {
        $inv->{invoices} =
            [  sort { $a->{transdate} cmp $b->{transdate} }
               map { { id => $_->[0],
                       invnumber => $_->[1],
                       transdate => $_->[2],
                       amount => $_->[3], ## no critic (ProhibitMagicNumbers)
                       paid => $_->[4],   ## no critic (ProhibitMagicNumbers)
                       net => $_->[5],    ## no critic (ProhibitMagicNumbers)
                       due => $_->[6],    ## no critic (ProhibitMagicNumbers)
                   } } @{$inv->{invoices} // []} ];

        for my $invoice (@{$inv->{invoices}}){
            for my $fld (qw/ due net paid amount /) {
                $invoice->{$fld} =
                    LedgerSMB::PGNumber->new($invoice->{$fld});
            }
        }
    }
    return;
}

=over

=item script()

Returns the script to direct a transaction to (currently ar, ap, is, or ir)

=back

=cut

sub script {
    my ($self, $invoice) = @_;
    $invoice //= $self->{invoice};
    if ($invoice) {
       return $self->{account_class} == 1 ? 'ir' : 'is';
    }
    else {
       return $self->{account_class} == 1 ? 'ap' : 'ar';
    }
}


=item post_bulk($data)

This function posts the payments in bulk.

Uses the following object properties:

  * account_class
  * ar_ap_accno
  * batch_id
  * cash_accno
  * currency
  * exchangerate
  * payment_date

The C<$data> hashref has the following keys:

=over

=item contacts

An arrayref of hashrefs holding details on payments per customer.
Each customer hash holds the following keys:

=over

=item id

The value associated with this key indicates whether the contact
was selected to be included in the payment batch (C<true>-ish means
selected).

=item paid

This key indicates whether the outstanding amount for all invoices
of this customer was paid (C<all>) or that only partial payment is
to be recorded (C<some>) -- note that the latter may mean either of
'all invoices, but only partially' as well 'only some invoices, but
full payment'.

=item source

The source system identifier for the payment transaction -- will be
used for automated reconciliation when possible.

=item invoices

An array reference to the invoices included in the payment, with
a hashref per included invoice. The per-invoice hashref has the
following keys:

=over

=item net

The amount to be posted in case the contact is set to have
full/complete payment (C<paid == 'all'>).

=item payment

The amount to be posted in case the contact is set to have
partial payment (C<paid == 'some'>).

=back

=back

=back

=cut

sub post_bulk {
    my ($self, $data) = @_;

    for my $contact (@{$data->{contacts}}) {

        my @invoice_elements;
        for my $invoice (@{$contact->{invoices}}) {

            next if $invoice->{payment} == 0.0;
            my $db_amount = $invoice->{payment}->to_db();
            my $invoice_subarray = "{$invoice->{invoice},$db_amount}";
            if ($invoice_subarray !~ /^\{\d+\,\-?\d*\.?\d+\}$/){
                die "Invalid subarray: $invoice_subarray";
            }

            push @invoice_elements, $invoice_subarray;
        }

        # Generate a postgresql array of arrays in the form:
        # {{1700,0.01},{1353,0.01},{454,0.01}}
        # Each sub element comprises the ar/ap table id being paid and
        # the amount being paid.
        my $transactions = '{' . join(',', @invoice_elements) . '}';

        $self->call_dbmethod(
            funcname => 'payment_bulk_post',
            args => {
                source       => $contact->{source},
                payment_date => $self->{payment_date},
                transactions => $transactions,
            }
        );
    }

    return;
}

=item post_payment

This method uses payment_post to store a payment (not a bulk payment) on the database.

=cut

sub post_payment {
 my ($self) = @_;
 # We have to check if it was a fx_payment
 $self->{currency} = $self->{curr};


 for (@{$self->{amount}}){
    $_ = $_->bstr if ref $_;
 }
 $self->{amount} = [map {ref $_ ? $_->bstr() : $_ } @{$self->{amount}}]
      if ref $self->{amount};
 my @TMParray = $self->call_dbmethod(funcname => 'payment_post');
 $self->{payment_id} = $TMParray[0]->{payment_post};
 return $self->{payment_id};
}

=item gather_printable_info

This method retrieves all the payment related info needed to build a
document and print it. IT IS NECESSARY TO ALREADY HAVE payment_id on $self

=cut


sub gather_printable_info {
my ($self) = @_;
@{$self->{header_info}} = $self->call_dbmethod(funcname => 'payment_gather_header_info');
@{$self->{line_info}}   = $self->call_dbmethod(funcname => 'payment_gather_line_info');
for my $row(@{$self->{line_info}}){
    $row->{invoice_date} = $row->{trans_date};
}
return;
}

=item get_open_overpayment_entities

This method retrieves all the entities with the specified
account_class which have unused overpayments

=cut

sub get_open_overpayment_entities {
my ($self) = @_;
@{$self->{open_overpayment_entities}} = $self->call_dbmethod(funcname => 'payment_get_open_overpayment_entities');
return @{$self->{open_overpayment_entities}};
}

=item get_unused_overpayments

This is a simple wrapper around payment_get_unused_overpayments sql function.

This is now used by AA.pm

=cut

sub get_unused_overpayments {
my ($self) = @_;
@{$self->{unused_overpayment}} = $self->call_dbmethod(funcname => 'payment_get_unused_overpayment');
return @{$self->{unused_overpayment}};
}

=item get_available_overpayment_amount

Simple wrapper around payment_get_available_overpayment_amount sql function.

=cut

sub get_available_overpayment_amount {
my ($self) = @_;
@{$self->{available_overpayment_amount}} = $self->call_dbmethod(funcname => 'payment_get_available_overpayment_amount');
return @{$self->{available_overpayment_amount}};
}

=item overpayment_reverse($payment_id, $batch_id);

=cut

sub overpayment_reverse {
    my ($self, $args) = @_;
    return $self->call_procedure(
        funcname => 'overpayment__reverse',
        args => [$args->{id},
                 $args->{post_date},
                 $args->{batch_id},
                 $args->{account_class},
        ] );
}

=item init

Initializes the num2text system

=item num2text

Translates numbers into words.

=back

=cut

1;
