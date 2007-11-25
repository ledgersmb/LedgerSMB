package LedgerSMB::DBObject::Customer;

use base qw(LedgerSMB::DBObject::Company);
use strict;

my $CUSTOMER_ENTITY_CLASS = 2;

sub save {
    my $self = shift @_;

    $self->{entity_class} = $CUSTOMER_ENTITY_CLASS;
    $self->save_credit(); # inherited from Company    
}


sub save_location {
    my $self = shift @_;
    $self->{entity_class} = $CUSTOMER_ENTITY_CLASS;
    $self->{country_id} = $self->{country};
    $self->exec_method(funcname => 'company__location_save');

    $self->{dbh}->commit;
}



sub get {
    my $self = shift @_;
    $self->{entity_class} = $CUSTOMER_ENTITY_CLASS;
    my ($ref) = $self->exec_method(funcname => 'entity__retrieve_credit');
    $self->merge($ref);

    $self->{name} = $self->{legal_name};
    $self->get_company();
}


sub search {
    
    
}
1;
