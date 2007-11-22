package LedgerSMB::DBObject::Customer;

use base qw(LedgerSMB::DBObject);
use LedgerSMB::DBObject;
use LedgerSMB::Entity;

my $CUSTOMER_ENTITY_CLASS = 2;

sub save {
    my $self = shift @_;

    # This saves both the entity and the credit account. -- CT
    $self->{entity_class} = $CUSTOMER_ENTITY_CLASS;
    
    ($ref) = $self->exec_method(funcname => 'entity_credit_save');
    $self->{entity_id} = $ref->{entity_credit_save};
    $self->{dbh}->commit;
}

sub get_metadata {
    my $self = shift @_;

    @{$self->{location_class}} = 
         $self->exec_method(funcname => 'location_list_class');

    @{$self->{country}} = 
         $self->exec_method(funcname => 'location_list_country');

    @{$self->{contact_class}} = 
         $self->exec_method(funcname => 'entity_list_contact_class');
}

sub save_location {
    $self = shift @_;
    $self->{entity_class} = $CUSTOMER_ENTITY_CLASS;
    $self->{country_id} = $self->{country};
    $self->exec_method(funcname => 'customer_location_save');
}

sub save_contact {
}

sub save_bank_acct {
}

sub get {
    my $self = shift @_;
    $self->merge(shift @{$self->exec_method(funcname => 'customer__retrieve')});

    $self->{name} = $self->{legal_name};

    @{$self->{locations}} = $self->exec_method(
		funcname => 'company__list_locations');

    @{$self->{contacts}} = $self->exec_method(
		funcname => 'company__list_contacts');

    @{$self->{contacts}} = $self->exec_method(
		funcname => 'company__list_bank_accounts');

    @{$self->{notes}} = $self->exec_method(
		funcname => 'company__list_notes');
}


sub search {
    
    
}
1;
