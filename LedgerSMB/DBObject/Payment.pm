
=head1:  LedgerSMB::DBObject::Payment:  Stub function for payments.
=head1:  Copyright (c) 2007.  LedgerSMB Core Team 

=cut

package LedgerSMB::DBObject::Payment;
use base qw(LedgerSMB::DBObject);
use strict;
use Math::BigFloat lib => 'GMP';
our $VERSION = '0.1.0';

sub get_open_accounts {
    my ($self) = @_;
    @{$self->{accounts}} = 
        $self->exec_method(funcname => 'payment_get_open_accounts');
    return @{$self->{accounts}};
}

sub get_all_accounts {
    my ($self) = @_;
    @{$self->{accounts}} = 
        $self->exec_method(funcname => 'payment_get_all_accounts');
    return @{$self->{accounts}};
}

sub get_open_invoices {
    my ($self) = @_;
    @{$self->{open_invoices}} = 
        $self->exec_method(funcname => 'payment_get_open_invoices');
    return @{$self->{open_invoices}};
}

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
