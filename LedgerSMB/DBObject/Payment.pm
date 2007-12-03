
=head1 NAME

LedgerSMB::Payment:  Payment Handling Back-end Routines for LedgerSMB

=head1 SYNOPSIS

Provides the functions for generating the data structures payments made in 
LedgerSMB.   This module currently handles only basic payment logic, and does
handle overpayment logic, though these features will be moved into this module
in the near future.

=head1 COPYRIGHT

Copyright (c) 2007 The LedgerSMB Core Team.  Licensed under the GNU General 
Public License version 2 or at your option any later version.  Please see the
included COPYRIGHT and LICENSE files for more information.

=cut

package LedgerSMB::DBObject::Payment;
use base qw(LedgerSMB::DBObject);
use strict;
use Math::BigFloat lib => 'GMP';
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

=cut

sub __validate__ {
  my ($self) = shift @_;
  # If the account class is not set, we don't know if it is a payment or a 
  # receipt.  --CT
  if (!$self->{account_class}) {
    $self->error("account_class must be set")
  }; 
  # We should try to re-engineer this so that we don't have to include SQL in
  # this file.  --CT
  ($self->{current_date}) = $self->{dbh}->selectrow_array('select current_date');
}

sub get_metadata {
    my ($self) = @_;
    $self->list_open_projects();
    @{$self->{departments}} = $self->exec_method(funcname => 'department_list');
    $self->get_open_currencies();
    $self->{currencies} = [];
    for my $c (@{$self->{openCurrencies}}){
        push @{$self->{currencies}}, $c->{payments_get_open_currencies};
    }
    @{$self->{businesses}} = $self->exec_method(
		funcname => 'business_type__list'
    );
    @{$self->{debt_accounts}} = $self->exec_method(
		funcname => 'chart_get_ar_ap');
}

sub get_open_accounts {
    my ($self) = @_;
    @{$self->{accounts}} = 
        $self->exec_method(funcname => 'payment_get_open_accounts');
    return @{$self->{accounts}};
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
        $self->exec_method(funcname => 'payment_get_all_accounts');
    return @{$self->{accounts}};
}

=over

=item $payment->get_open_invoices()

This function returns a list of open invoices depending on the 
$payment->{account_class}, $payment->{entity_id}, and $payment->{curr} 
properties.  Account classes follow the conventions above.  This list is hence
specific to a customer or vendor and currency as well.

The returned list of hashrefs is stored in the $payment->{open_invoices} 
property. Each hashref has the following keys:  id (entity id), name, and 
entity_class.

=back

=cut

sub get_open_invoices {
    my ($self) = @_;
    @{$self->{open_invoices}} = 
        $self->exec_method(funcname => 'payment_get_open_invoices');
    return @{$self->{open_invoices}};
}

=over

=item $oayment->get_all_contact_invoices()

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
        $self->exec_method(funcname => 'payment_get_all_contact_invoices');

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
                          Math::BigFloat->new($new_invoice->{$_});
                 }
            }
            push(@$processed_invoices, $new_invoice);
        }
        $contact->{invoice} = $processed_invoices;
    }
    return @{$self->{contacts}};
}

=over

=item list_open_projects

This method gets the current date attribute, and provides a list of open
projects.  The list is attached to $self->{projects} and returned.

=back

=cut

sub list_open_projects {
    my ($self) = @_;
    @{$self->{projects}} = $self->call_procedure( 
         procname => 'project_list_open',  args => [$self->{current_date}] 
    );
    return  @{$self->{projects}};
}

=over
=item list_departments

This method gets the type of document as a parameter, and provides a list of departments
of the required type.
The list is attached to $self->{departments} and returned.

=back
=cut

sub list_departments {
  my ($self) = shift @_;
  my @args = @_;
  @{$self->{departments}} = $self->call_procedure( 
      procname => 'department_list', 
      args => \@args
  );
  return @{$self->{departments}};
}

=item list_open_vc

This method gets the type of vc (vendor or customer) as a parameter, and provides a list of departments
of the required type.
The list is attached to $self->{departments} and returned.

=back
=cut

sub list_departments {
  my ($self) = shift @_;
  my @args = @_;
  @{$self->{departments}} = $self->call_procedure(
     procname => 'department_list',
     args => \@args
   );
  return @{$self->{departments}};
}
                      
=item get_open_currencies

This method gets a list of the open currencies inside the database, it requires that  
$self->{account_class} (must be 1 or 2)  exist to work.

=back
=cut

sub get_open_currencies {
  my ($self) = shift @_;
  @{$self->{openCurrencies}} = $self->exec_method( funcname => 'payments_get_open_currencies');
  return @{$self->{openCurrencies}};
}

=item list_accounting

This method lists all accounts that match the role specified in account_class property and
are availible to store the payment or receipts. 
=back
=cut

sub list_accounting {
 my ($self) = @_;
 @{$self->{pay_accounts}} = $self->exec_method( funcname => 'chart_list_cash');
 return @{$self->{pay_accounts}}; 
}

=item get_sources

This method builds all the possible sources of money,
in the future it will look inside the DB. 
=back

=cut

sub get_sources {
 my ($self, $locale) = @_;
 @{$self->{cash_sources}} = ($locale->text('cash'),
                             $locale->text('check'),
                             $locale->text('deposit'),
                             $locale->text('other'));
 return @{$self->{cash_sources}}; 
}

=item get_exchange_rate(currency, date)

This method gets the exchange rate for the specified currency and date

=cut 

sub get_exchange_rate { 
 my ($self) = shift @_;
 ($self->{currency}, $self->{date}) = @_;
 ($self->{exchangerate}) = $self->exec_method(funcname => 'currency_get_exchangerate'); 
  return $self->{exchangerate}->{currency_get_exchangerate};
 
}

=item get_default_currency

This method gets the default currency 
=back

=cut

sub get_default_currency {
 my ($self) = shift @_;
 ($self->{default_currency}) = $self->call_procedure(procname => 'defaults_get_defaultcurrency');
 return $self->{default_currency}->{defaults_get_defaultcurrency};
}

=item get_current_date

This method returns the system's current date

=cut

sub get_current_date {
 my ($self) = shift @_;
 return $self->{current_date}; 
}

=item get_vc_info

This method returns the contact informatino for a customer or vendor according to
$self->{account_class}

=cut

sub get_vc_info {
 my ($self) = @_; 
 #@{$self->{vendor_customer_info}} = $self->call_procedure(procname => 'vendor_customer_info');
 #return @{$self->{vendor_customer_info}};
}

=item get_payment_detail_data

This method sets appropriate project, department, etc. fields.

=cut

sub get_payment_detail_data {
    my ($self) = @_;
    @{$self->{cash_accounts}} = $self->exec_method(
		funcname => 'chart_list_cash');
    $self->get_metadata();

    my $source_inc;
    my $source_src;
    if (defined ($self->{source_start})){
        $self->{source_start} =~ /(\d*)\D*$/;
	$source_src = $1;
	if ($source_src) {
		$source_inc = $source_src;
	} else {
		$source_inc = $0;
	}
    }
    @{$self->{contact_invoices}} = $self->exec_method(
		funcname => 'payment_get_all_contact_invoices');
    for my $inv (@{$self->{contact_invoices}}){
        if (defined $self->{source_start}){
		my $source = $self->{source_start};
		$source =~ s/$source_src(\D*)$/$source_inc$1/;
		++ $source_inc;
		$inv->{source} = $source;
	}
	my $tmp_invoices = $inv->{invoices};
        $inv->{invoices} = [];
        @{$inv->{invoices}} = $self->_parse_array($tmp_invoices);
    }
}    

1;
