package LedgerSMB::DBObject::Vendor;

use base qw(LedgerSMB::DBObject::Company);
use LedgerSMB::DBObject;

sub save {
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
    $self->set(entity_class=> 1);
    
    $entity->save();
    if (!self->{entity_id}) {
        
        $self->{entity_id} = $entity->{id};
    }
    $self->SUPER::save();
    
    return $self->{id};

}
1;