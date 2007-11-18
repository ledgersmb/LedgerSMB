package LedgerSMB::DBObject::Customer;

use base qw(LedgerSMB::DBObject);
use LedgerSMB::DBObject;
use LedgerSMB::Entity;

sub save {
    
    # this is doing way too much.
    
    my $self = shift @_;
    
    my $entity;
    
    # this is a fairly effective way of telling if we need to create a new
    # entity or not.
    
    if (!$self->{entity_id}) {
        
        $entity = LedgerSMB::Entity->new(base=>$request);
    }
    else {
        
        $entity = LedgerSMB::Entity->get(id=>$self->{entity_id});
    }
    
    $entity->set(name=> $reqeust->{first_name}." ".$request->{last_name} );
    $entity->set(entity_class=>2);

    $self->set(entity_id=>$entity->{id});
    $self->set(entity_class=> 2);
    
    $entity->save();
    if (!self->{entity_id}) {
        
        $self->{entity_id} = $entity->{id};
    }
    $self->SUPER::save();
    
    return $self->{id};
}

sub search {
    
    
}
1;
