
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

=item $oayment->get_open_accounts()

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

sub get_open_accounts {
    my ($self) = @_;
    @{$self->{accounts}} = 
        $self->exec_method(funcname => 'payment_get_open_accounts');
    return @{$self->{accounts}};
}

=over

=item $oayment->get_all_accounts()

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

=item $oayment->get_open_invoices()

This function returns a list of open invoices depending on the 
$payment->{account_class}, $payment->{entity_id}, and $payment->{currency} 
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

This method uses the $payment->{date} attribute, and provides a list of open 
projects.  The list is attached to $payment->{projects} and returned by the 
function.

=back

=cut

sub list_open_projects {
    my ($self) = @_;
    @{$self->{projects}} = $self->exec_method('project_list_open');
    return  @{$self->{projects}};
}

1;
