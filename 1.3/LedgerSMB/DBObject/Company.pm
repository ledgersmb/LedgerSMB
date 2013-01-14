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

=item get_by_cc

This retrieves the company header information by control code.  Leaves the 
overall account class untouched.

=back

=cut

sub get_by_cc {
    my $self = shift @_;
    my $entity_class = $self->{entity_class};
    my ($ref) = $self->exec_method({funcname => 'entity__get_by_cc'});
    $self->merge($ref);
    $self->{entity_id} = $self->{id};
    delete $self->{id};
    $self->get;
    $self->get_metadata;
    $self->{entity_class} = $entity_class;
}


=over

=item save()

This stores the company record including a credit account in the database.

TODO:  Separate company from credit account storage.

=back

=cut

sub save {
    my $self = shift @_;
    $self->set_entity_class();
    unless($self->{control_code}) {
        $self->{notice} = "You must set the Control Code";
        return;
    }
    unless($self->{name}) {
        $self->{notice} = "You must set the Name";
        return;
    }
    my ($ref) = $self->exec_method(funcname => 'company_save');
    $self->{entity_id} = (values %$ref)[0];
    $self->get;
    $self->get_metadata;
    $self->{dbh}->commit;
}


=over 

=item delete_contact

required request variables:

contact_class_id:  int id of contact class
contact: text of contact information

Must include at least one of:

credit_id: int of entity_credit_account.id, preferred value
company_id:  int of company.id, only used if credit_id not set.

returns true of a record was deleted.

=back

=cut

sub delete_contact {
    my ($self) = @_;
    my $rv;
    if ($self->{credit_id}){
        ($rv) = $self->exec_method(funcname => 'eca__delete_contact');
    } elsif ($self->{company_id}){
        ($rv) = $self->exec_method(funcname => 'company__delete_contact');
    } else {
       $self->error($self->{_locale}->text(
          'No company or credit id in LedgerSMB::DBObject::delete_contact'
       ));
    }
    $self->{dbh}->commit;
    return $rv;
}

=over

=item delete_location

Deletes a record from the location side.

Required request variables:

location_id
location_class_id

One of:

credit_id (preferred)
company_id (as fallback)

Returns true if a record was deleted.  False otherwise.

=back

=cut

sub delete_location {
    my ($self) = @_;
    my $rv;
    if ($self->{credit_id}){
        ($rv) = $self->exec_method(funcname => 'eca__delete_location');
    } elsif ($self->{company_id}){
        ($rv) = $self->exec_method(funcname => 'company__delete_location');
    } else {
       $self->error($self->{_locale}->text(
          'No company or credit id in LedgerSMB::DBObject::delete_location'
       ));
    }
    $self->{dbh}->commit;
    return $rv;
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

=pod

=over

=item save_credit 

This method saves the credit account for the company.

Expected inputs:
credit_id (int): (Optional) Id for the account
entity_class (int):  Class of the account, required (1 = vendor, 2 = customer)
entity_id (int):  ID of entity to attach to. 
description (text):  Description of account
discount (numeric):  Early payment discount 
taxincluded (bool):  Whether prices include tax. 
creditlimit (numeric):  Credit limit
discount_terms (int):  How many days can elapse before the discount lapses too.
terms (int):  How many days can lapse before the invoice is overdue. 
meta_number (varchar):  Account string identifier for the account.
business_id (int):  ID for business type.
language (varchar): Language code for invoices.
pricegroup_id (int): Price group
curr (char):  Currency  identifier, three characters long.
startdate (date):  Date of the start of the relationship. 
enddate (date):  Date of the end of the relationship.
threshold (NUMERIC):  How much must be owed before the invoices can be paid.
ar_ap_account_id (int):  ID of ar/ap account.  REQUIRED
cash_account_id (int):  ID of cash account (Optional)
pay_to_name (text):  Name to pay to or receive from.
taxform_id (int);  ID of tax form

=back

=cut

sub save_credit {

    my $self = shift @_;
    $self->set_entity_class();
    $self->{threshold} = $self->parse_amount(amount => $self->{threshold});
    $self->{tax_ids} = $self->_db_array_scalars(@{$self->{tax_ids}});
    my ($ref) = $self->exec_method(funcname => 'entity_credit_save');
    $self->{credit_id} = (values %$ref)[0];
    my $dbh=$self->{dbh};
    if ($self->{taxform1_id}) {
       my $sth = $dbh->prepare(
           "update entity_credit_account 
                set country_taxform_id=? 
              where id=?"
       );
       $sth->execute($self->{taxform1_id}, $self->{credit_id});
    }
    if ($self->{tax_ids} ne '{}'){
        $self->exec_method(funcname => 'eca__set_taxes');
    }
    $self->{threshold} = $self->format_amount(amount => $self->{threshold});
    $self->{dbh}->commit;
}

=over

=item save_location

This method saves an address for a company.

Requires the following variables on the object:
credit_id
location_id 
location_class (1 = billing, 2 = shipping, 3 = sales)
line_one
line_two
city
state (can hold province info)  
mail_code (zip or postal code) 
country_code (ID of country)


=back

=cut

sub save_location {
    my $self = shift @_;

    $self->{country_id} = $self->{country_code};

    if($self->{credit_id}){
        $self->exec_method(funcname => 'eca__location_save');
    } else {
        my ($ref) = $self->exec_method(funcname => 'company__location_save');
        my @vals = values %$ref;
        $self->{location_id} = $vals[0];
    }

    $self->{dbh}->commit;
}

=over

=item get_credit_id 

This method returns the current credit id from the screen.

Requires entity_id, meta_number, and entity_class be set.

=back

=cut

sub get_credit_id {
    my $self = shift @_;
    my ($ref) = $self->exec_method(
           funcname => 'entity_credit_get_id'
    );
    $self->{credit_id} = $ref->{'entity_credit_get_id'};
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

    @{$self->{contact_class_list}} = 
         $self->exec_method(funcname => 'entity_list_contact_class');
    #HV was $country_setting , given it a more general name, not only for country
    my $setting_module = LedgerSMB::Setting->new({base => $self, copy => 'base'});
    $setting_module->{key} = 'default_country';
    $setting_module->get;
    $self->{default_country} = $setting_module->{value};
    $setting_module->{key} = 'default_language';
    $setting_module->get;
    $self->{default_language} = $setting_module->{value};
}

=item save_contact

Saves a contact.  Requires credit_id, contact_class, description, and contact to 
be set.

Requires the following be set:
credit_id or entity_id
contact_class
description
contact
old_contact
old_contact_class

=cut

sub save_contact {
    my ($self) = @_;
    if ($self->{credit_id}){
        $self->exec_method(funcname => 'eca__save_contact');
    } else {
        $self->exec_method(funcname => 'company__save_contact');
    }
    $self->{dbh}->commit;
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



# I don't believe account() is used.  At any rate the stored proc called 
# doesn't exist and therefore it can't work.  Therefore deleting the account() 
# function. Not the same as the accounts() function which is used. --CT 

=item accounts

Returns all accounts, and sets these to $self->{accounts}.

id and entity_class must be set.

=cut

sub accounts {
    
    my ($self) = @_;
    
    $self->set_entity_class();
    @{$self->{accounts}} = $self->exec_method(funcname => 'company__get_all_accounts');
}

=item address($id)

Returns the location if it is specified by the $id argument.

=cut 

sub address {
    
    my ($self, $id) = @_;
    
    for my $loc (@{ $self->{locations} }) {
        if ($loc->{id} == $id) {
            return $loc;
        }
    }
}

=item get

Retrieves a company record and all info.

taxform_list is set to a list of tax forms for the entity's country
credit_list is set to a list of credit accounts
locations is set to a list of locations
contacts to a list of contacts
notes to a list of notes
bank_account to a list of bank accounts

=cut

sub get {
    my $self = shift @_;

    $self->set_entity_class();

    if($self->{entity_id})
    {
        @{$self->{taxform_list}} = $self->exec_method(funcname => 'list_taxforms');
    }

    my ($ref) = $self->exec_method(funcname => 'company_retrieve');
    $self->merge($ref);
    $self->{threshold} = $self->format_amount(amount => $self->{threshold});

    @{$self->{credit_list}} = 
         $self->exec_method(funcname => 'entity__list_credit');
    $self->{eca_tax} = [];
    for (@{$self->{credit_list}}){
	if (($_->{credit_id} eq $self->{credit_id}) 
                   or ($_->{meta_number} eq $self->{meta_number})
                   or ($_->{id} eq $self->{credit_id})){
            $self->merge($_);
            if ($_->{entity_class} == 1 || $_->{entity_class} == 2){
                my @taxes = $self->exec_method(funcname => 'eca__get_taxes');
                
                for my $tax (@taxes){
                    push @{$self->{eca_tax}}, $tax->{chart_id};
                }
            }
            last;
        }
    }
    $self->{name} = $self->{legal_name};
    if ($self->{credit_id} and $self->{meta_number}){
        $self->get_credit_id;
    }

    if ($self->{credit_id}){
        @{$self->{locations}} = $self->exec_method(
		funcname => 'eca__list_locations');
        @{$self->{contacts}} = $self->exec_method(
		funcname => 'eca__list_contacts');
        @{$self->{notes}} = $self->exec_method(
		funcname => 'eca__list_notes');
        
    }
    else {
        @{$self->{locations}} = $self->exec_method(
		funcname => 'company__list_locations');
        @{$self->{contacts}} = $self->exec_method(
		funcname => 'company__list_contacts');
        @{$self->{notes}} = $self->exec_method(
		funcname => 'company__list_notes');

    }

    if ($self->{location_id}){
        for (@{$self->{locations}}){
            if ($_->{id} == $self->{location_id}){
                my $old_id = $self->{id};
                $self->merge($_);
                for my $c (@{$self->{country_list}}){
                     if ($c->{name} eq $self->{country}){
                         $self->{country_code} = $c->{id};
                     }
                }
                last;
            }
        }
    }

    if ($self->{contact_id}){
        for (@{$self->{contacts}}){
            if ($_->{id} = $self->{contact_id}){
                my $old_id = $self->{id};
                $self->merge($_);
                $self->{id} = $old_id;
                last;
            }
        }
    }

    @{$self->{bank_account}} = $self->exec_method(
		funcname => 'company__list_bank_account');
};

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
