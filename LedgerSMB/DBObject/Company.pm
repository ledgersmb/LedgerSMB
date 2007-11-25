
package LedgerSMB::DBObject::Company;

use base qw(LedgerSMB::DBObject);
use strict;

sub save_credit {
    my $self = shift @_;

    my ($ref) = $self->exec_method(funcname => 'entity_credit_save');
    $self->{entity_id} = $ref->{entity_credit_save};
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

sub get_company{
    my $self = shift @_;
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
