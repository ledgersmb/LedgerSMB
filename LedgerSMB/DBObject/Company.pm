
package LedgerSMB::DBObject::Company;

use base qw(LedgerSMB::DBObject);
use strict;

sub set_entity_class {
    my $self = shift @_;
    if (!defined $self->{entity_class}){
 	       $self->error("Entity ID Not Set and No Entity Class Defined!");
    }
}

sub save {
    my $self = shift @_;
    $self->set_entity_class();
    my ($ref) = $self->exec_method(funcname => 'entity_credit_save');
    $self->{entity_id} = $ref->{entity_credit_save};
    $self->{dbh}->commit;
}

sub save_location {
    my $self = shift @_;
    $self->{country_id} = $self->{country};
    $self->exec_method(funcname => 'company__location_save');

    $self->{dbh}->commit;
}

sub get_metadata {
    my $self = shift @_;

    @{$self->{location_class_list}} = 
         $self->exec_method(funcname => 'location_list_class');

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

sub get {
    my $self = shift @_;

    $self->set_entity_class()
    my ($ref) = $self->exec_method(funcname => 'entity__retrieve_credit');
    $self->merge($ref);

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
