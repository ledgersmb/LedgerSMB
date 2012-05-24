=head1 NAME

LedgerSMB::DBObject::Company - Base utility functions for processing customers and vendors.

=head1 SYNOPSIS

This library contains the base utility functions for creating, saving, and
retrieving customers and vendors.

=cut

# This module has the following problems associated with it which need to be 
# revised.
#
# 1)  The data in this module is too free-form.  There needs to be more 
# structure, and that probably requires breaking it out into a Location.pm, 
# Contact.pm, Notes.pm, etc.
#
# 2)  The current code ties the company to the credit account too much.  This
# needs to be separated. --CT

package LedgerSMB::DBObject::Company;

use LedgerSMB::Setting;
use base qw(LedgerSMB::DBObject);
use strict;

=head1 METHODS

=over

=item $company->set_entity_class()

This is a stub for a private method that subclasses are expected to overwrite. 
It will be set to the account class of the entity (1 for vendor, 2 for customer,
etc).

=back

=cut

sub set_entity_class {
    my $self = shift @_;
    if (!defined $self->{entity_class}){
 	       $self->error("Entity ID Not Set and No Entity Class Defined!");
    }
}

=over 

=item delete_bank_account

Deletes a bank account

Requires:

entity_id
bank_account_id

Returns true if a record was deleted, false otherwise.

=back

=cut

sub delete_bank_account {
    my ($self) = @_;
    my $rv;
    ($rv) = $self->exec_method(funcname => 'entity__delete_bank_account',
                               args => [$self->{entity_id}, 
                                        $self->{bank_account_id}]);
    $self->{dbh}->commit;
    return $rv;
}

=over 

=item get_history 

Retrieves customer/vendor purchase.

Search Criteria
name:  search string for company name
contact_info:  Search string for contact info, can match phone, fax, or email.
salesperson:  Search string for employee name in the salesperson field
notes: Notes search.  Not currently implemented
meta_number:  Exact match for customer/vendor number
address_line:  Search string for first or second line of address.
city:  Search string for city name
state:  Case insensitive, otherwise exact match for state or province
zip:  leading match for zip/mail code
country_id:  integer for country id.  Exact match
tartdate_from:  Earliest date for startdate of entity credit account
startdate_to:  Lates date for entity credit accounts' start date
type:  either 'i' for invoice, 'o' for orders, 'q' for quotations
from_date:  Earliest date for the invoice/order
to_date:  Latest date for the invoice/order

Unless otherwise noted, partial matches are sufficient.

Control variables:
inc_open:  Include open invoices/orders.  If not true, no open invoices are
           displayed
inc_closed: Include closed invoices/orders.  If not true, no closed invoices are
            displayed
report_type:  Either summary or detail

returns a list of rows of the summary report and sets these to 
@{$self->{history_rows}}

=back

=cut



sub get_history {
    my ($self) = @_;
    my @results;
    if ($self->{report_type} eq 'summary') {
        @results = $self->exec_method(funcname => 'eca_history_summary');
    } elsif ($self->{report_type} eq 'detail'){
        @results = $self->exec_method(funcname => 'eca_history');
    } else {
        $self->error('Invalid report type in history report');
    }
    $self->{history_rows} = \@results;
    return @results;
}

=over

=item get_metadata()

This retrieves various information vor building the user interface.  Among other
things, it sets the following properties:
$self->{ar_ap_acc_list} = qw(list of ar or ap accounts)
$self->{cash_acc_list} = qw(list of cash accounts)
$self->{entity_classes} = qw(list of entity classes)
$self->{all_taxes}  =qw(list of taxes)

=cut

sub get_metadata {
    my $self = shift @_;

    @{$self->{entity_classes}} = 
		$self->exec_method(funcname => 'entity__list_classes');

    @{$self->{all_taxes}} = 
                $self->exec_method(funcname => 'account__get_taxes');

    @{$self->{ar_ap_acc_list}} = 
         $self->exec_method(funcname => 'chart_get_ar_ap');

    for my $ref (@{$self->{ar_ap_acc_list}}){
        $ref->{text} = "$ref->{accno}--$ref->{description}";
    }

    @{$self->{cash_acc_list}} = 
         $self->exec_method(funcname => 'chart_list_cash');

    for my $ref (@{$self->{cash_acc_list}}){
        $ref->{text} = "$ref->{accno}--$ref->{description}";
    }

    @{$self->{language_code_list}} = 
         $self->exec_method(funcname => 'person__list_languages');

    for my $ref (@{$self->{language_code_list}}){
        $ref->{text} = "$ref->{code}--$ref->{description}";
    }
    
    @{$self->{discount_acc_list}} =
         $self->exec_method(funcname => 'chart_list_discount');

    for my $ref (@{$self->{discount_acc_list}}){
        $ref->{text} = "$ref->{accno}--$ref->{description}";
    }

    @{$self->{location_class_list}} = 
         $self->exec_method(funcname => 'location_list_class');

    @{$self->{business_types}} = 
         $self->exec_method(funcname => 'business_type__list');

    @{$self->{country_list}} = 
         $self->exec_method(funcname => 'location_list_country');

    ($self->{all_currencies}) =
         $self->exec_method(funcname => 'setting__get_currencies');
    $self->{all_currencies} = $self->{all_currencies}->{setting__get_currencies};

    for my $curr (@{$self->{all_currencies}}){
        $curr = { text => $curr };
    }

    #HV was $country_setting , given it a more general name, not only for country
    my $setting_module = LedgerSMB::Setting->new({base => $self, copy => 'base'});
    $setting_module->{key} = 'default_country';
    $setting_module->get;
    $self->{default_country} = $setting_module->{value};
    $setting_module->{key} = 'default_language';
    $setting_module->get;
    $self->{default_language} = $setting_module->{value};
}

=item save_bank_account

Saves a bank account.  Requires the following be set:
entity_id 
bic (bank id)
iban (account number)
bank_account_id (id for record, optional)

=cut

sub save_bank_account {
    my $self = shift @_;
    $self->exec_method(funcname => 'entity__save_bank_account');
    $self->{dbh}->commit;
}

=item save_notes

Saves notes. The following must be set:
credit_id:  credit account to annotate.  Must be set to annotate credit account
entity_id:  entitity to annotate.
note:  Note contents
subject:  Note subject

=cut

sub save_notes {
    my $self = shift @_;
    if ($self->{credit_id} && $self->{note_class} eq '3'){
        $self->exec_method(funcname => 'eca__save_notes');
    } else {
        $self->exec_method(funcname => 'entity__save_notes');
    }
    $self->{dbh}->commit;
}

=item search

Searches for matching company records.  Populates $self->{search_results} with 
records found.  

Search criteria and inputs:
account_class:  required (1 for vendor, 2 for customer, etc)
contact
contact_info
meta_number
address
city
state
mail_code
country
date_from
date_to
business_id
legal_name
control_code

Account class may not be undef.  meta_number is an exact match, as is 
control_code.  All others specify ranges or partial matches.

=cut

sub search {
    my ($self) = @_;
    @{$self->{search_results}} = 
	$self->exec_method(funcname => 'company__search');
    return @{$self->{search_results}};
}

=item get_billing_info

Requires that the id field is set.  Sets the following:

legal_name
meta_number
control_code
tax_id
street1
street2
street3
city
state
mail_code
country 

=cut

sub get_billing_info {
    my $self = shift @_;
    $self->set_entity_class();
    my ($ref) = $self->exec_method(funcname => 'company_get_billing_info');
    $self->merge($ref);
}



=item accounts

Returns all accounts, and sets these to $self->{accounts}.

id and entity_class must be set.

=cut

sub accounts {
    
    my ($self) = @_;
    
    $self->set_entity_class();
    @{$self->{accounts}} = $self->exec_method(funcname => 'company__get_all_accounts');
}

=item get_pricematrix

This routine gets the price matrix for the customer or vendor.  The pricematrix
info is stored in the pricematrix hash entry.  If a customer (account_class=1), 
it also populates a pricematrix_pricegroup entry.

=cut

sub get_pricematrix {
    my $self = shift @_;
    @{$self->{pricematrix}} = $self->exec_method(
               funcname => 'eca__get_pricematrix'
    );
    if ($self->{account_class} == 1){
        @{$self->{pricematrix_pricegroup}}= $self->exec_method(
               funcname => 'eca__get_pricematrix_by_pricegroup'
        );
    }
}

=item delete_pricematrix($entry_id)

This deletes a pricematrix line identified by $entry_id

=cut

sub delete_pricematrix {
    my $self = shift @_;
    my ($entry_id) = @_;
    my ($retval) = $self->exec_method(funcname => 'eca__delete_pricematrix', 
                           args => [$self->{credit_id}, $entry_id]
    );
    return $retval;
}


=item save_pricematrix

Updates or inserts the price matrix.

=cut

sub save_pricematrix {
    my $self  = shift @_;
    for my $count (1 .. $self->{pm_rowcount}){
        my $entry_id = $self->{"pm_$count"};
        my @args = ();
        for my $prop (qw()){
            push @args, $self->{"${prop}_$entry_id"};
            $self->execute_method(funcname => 'eca__save_pricematrix',
                                      args => \@args);
        }
    }
}

=back

=head1 COPYRIGHT

Copyright (c) 2009, the LedgerSMB Core Team.  This is licensed under the GNU 
General Public License, version 2, or at your option any later version.  Please 
see the accompanying License.txt for more information.

=cut

1;
