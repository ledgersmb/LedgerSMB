package LedgerSMB::DBObject::Customer;

use base qw(LedgerSMB::DBObject);
use LedgerSMB::DBObject;
use LedgerSMB::Entity;

sub save {
    my $self = shift @_;

    # This saves both the entity and the credit account. -- CT
    $self->{entity_class} = 2;
    
    $self->{entity_id} = $self->exec_method(funcname => 'entity_credit_save');
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

sub search {
    
    
}
1;
