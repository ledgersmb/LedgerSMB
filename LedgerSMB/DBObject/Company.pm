=head1 NAME

LedgerSMB::DBObject::Company.pm, LedgerSMB Base Class for Customers/Vendors

=head1 SYNOPSIS

This library contains the base utility functions for creating, saving, and
retrieving customers and vendors.

=cut

package LedgerSMB::DBObject::Company;

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

=item save()

This stores the company record including a credit accoun tin the database.

TODO:  Separate company from credit account storage.

=back

=cut

sub save {
    my $self = shift @_;
    $self->set_entity_class();
    $self->{threshold} = $self->parse_amount(amount => $self->{threshold});
    my ($ref) = $self->exec_method(funcname => 'entity_credit_save');
    $self->{entity_id} = $ref->{entity_credit_save};
    $self->{threshold} = $self->format_amount(amount => $self->{threshold});
    $self->{dbh}->commit;
}

=over

=item save_location

This method saves an address for a company.

=back

=cut

sub save_location {
    my $self = shift @_;
    $self->{country_id} = $self->{country};
    $self->exec_method(funcname => 'company__location_save');

    $self->{dbh}->commit;
}

=over

=item get_metadata()

This retrieves various information vor building the user interface.  Among other
things, it sets the following properties:
$self->{ar_ap_acc_list} = qw(list of ar or ap accounts)
$self->{cash_acc_list} = qw(list of cash accounts)

=back

=cut

sub get_metadata {
    my $self = shift @_;

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

    @{$self->{location_class_list}} = 
         $self->exec_method(funcname => 'location_list_class');

    @{$self->{business_types}} = 
         $self->exec_method(funcname => 'business_type__list');

    @{$self->{country_list}} = 
         $self->exec_method(funcname => 'location_list_country');

    @{$self->{contact_class_list}} = 
         $self->exec_method(funcname => 'entity_list_contact_class');
}

sub save_contact {
    my ($self) = @_;
    $self->exec_method(funcname => 'company__save_contact');
    $self->{dbh}->commit;
}

sub save_bank_account {
    my $self = shift @_;
    $self->exec_method(funcname => 'entity__save_bank_account');
    $self->{dbh}->commit;
}

sub save_notes {
    my $self = shift @_;
    $self->exec_method(funcname => 'entity__save_notes');
    $self->{dbh}->commit;
}

sub search {
    my ($self) = @_;
    @{$self->{search_results}} = 
	$self->exec_method(funcname => 'company__search');
    return @{$self->{search_results}};
}

sub get {
    my $self = shift @_;

    $self->set_entity_class();
    my ($ref) = $self->exec_method(funcname => 'entity__retrieve_credit');
    $self->merge($ref);
    $self->{threshold} = $self->format_amount(amount => $self->{threshold});

    $self->{name} = $self->{legal_name};

    @{$self->{locations}} = $self->exec_method(
		funcname => 'company__list_locations');

    @{$self->{contacts}} = $self->exec_method(
		funcname => 'company__list_contacts');

    @{$self->{bank_account}} = $self->exec_method(
		funcname => 'company__list_bank_account');

    @{$self->{notes}} = $self->exec_method(
		funcname => 'company__list_notes');
};

1;
