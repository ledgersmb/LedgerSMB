
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
    @{$self->{cash_accounts}} = $self->exec_method(
		funcname => 'chart_list_cash');
    for my $ref(@{$self->{cash_accounts}}){
        $ref->{text} = "$ref->{accno}--$ref->{description}";
    }
}

sub search {
    my ($self) = @_;
    if ($self->{meta_number} && !$self->{credit_id}){
        my ($ref) = $self->exec_method(
		funcname => 'entity_credit_get_id_by_meta_number'
        );
        my @keys = keys %$ref;
        my $key = shift @keys;
        $self->{credit_id} = $ref->{$key};
    }
    @{$self->{search_results}} = $self->exec_method(
		funcname => 'payment__search'
    );
    return @{$self->{search_results}};
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

=item $payment->reverse()

This function reverses a payment.  A payment is defined as one source 
($payment->{source}) to one cash account ($payment->{cash_accno}) to one date 
($payment->{date_paid}) to one vendor/customer ($payment->{credit_id}, 
$payment->{account_class}).  This reverses the entries with that source.

=back

=cut

sub reverse {
    my ($self) = @_;
    $self->exec_method(funcname => 'payment__reverse');
    return $self->{dbh}->commit;
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
    $self->get_metadata();

    my $source_inc;
    my $source_src;
    if (defined ($self->{source_start})){
        $self->{source_start} =~ /(\d*)\D*$/;
	$source_src = $1;
	if ($source_src) {
		$source_inc = $source_src;
	} else {
		$source_inc = 0;
	}
    }
    my $source_length = length($source_inc);
   
    @{$self->{contact_invoices}} = $self->exec_method(
		funcname => 'payment_get_all_contact_invoices');
    for my $inv (@{$self->{contact_invoices}}){
        if (defined $self->{source_start}){
		my $source = $self->{source_start};
		if (length($source_inc) < $source_length){
                    $source_inc = sprintf('%0*s', $source_length, $source_inc);
                }
		$source =~ s/$source_src(\D*)$/$source_inc$1/;
		++ $source_inc;
		$inv->{source} = $source;
	}
	my $tmp_invoices = $inv->{invoices};
        $inv->{invoices} = [];
        @{$inv->{invoices}} = $self->_parse_array($tmp_invoices);
    }
    $self->{dbh}->commit; # Commit locks
}    

sub post_bulk {
    my ($self) = @_;
    my $total_count = 0;
    my ($ref) = $self->call_procedure(
          procname => 'setting_get', 
          args     => ['queue_payments'],
    );
    my $queue_payments = $ref->{setting_get};
    if ($queue_payments){
        my ($job_ref) = $self->exec_method(
                 funcname => 'job__create'
        );
        $self->{job_id} = $job_ref->{job__create};

         ($self->{job}) = $self->exec_method(
		funcname => 'job__status'
         );
    }
    $self->{payment_date} = $self->{datepaid};
    for my $contact_row (1 .. $self->{contact_count}){
        my $contact_id = $self->{"contact_$contact_row"};
        next if (!$self->{"id_$contact_id"});
        my $invoice_array = "{}"; # Pg Array
	for my $invoice_row (1 .. $self->{"invoice_count_$contact_id"}){
            my $invoice_id = $self->{"invoice_${contact_id}_${invoice_row}"};
            my $pay_amount = ($self->{"paid_$contact_id"} eq 'all' ) 
			? $self->{"net_$invoice_id"} 
			: $self->{"payment_$invoice_id"};
            next if ! $pay_amount;
            $pay_amount = $pay_amount * 1;
            my $invoice_subarray = "{$invoice_id,$pay_amount}";
            if ($invoice_subarray !~ /^\{\d+\,\-?\d*\.?\d+\}$/){
                $self->error("Invalid subarray: $invoice_subarray");
            }
            $invoice_subarray =~ s/[^0123456789{},.]//; 
	    if ($invoice_array eq '{}'){ # Omit comma
                $invoice_array = "{$invoice_subarray}";
	    } else {
                $invoice_array =~ s/\}$/,$invoice_subarray\}/;
            }
        }
        $self->{transactions} = $invoice_array;
	$self->{source} = $self->{"source_$contact_id"};
        if ($queue_payments){
             $self->{batch_class} = 3;
             $self->exec_method(
                 funcname => 'payment_bulk_queue'
             );
        } else {
            $self->exec_method(funcname => 'payment_bulk_post');
        }
    }
    $self->{queue_payments} = $queue_payments;
    return $self->{dbh}->commit;
}

sub check_job {
    my ($self) = @_;
    ($self->{job}) = $self->exec_method(funcname => 'job__status');
}

1;
