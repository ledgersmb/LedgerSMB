package LedgerSMB::DBObject::Location;

use base LedgerSMB::DBObject;

sub create {
    
    my $self = shift @_;
}

sub save {
    
    my $self = shift @_;
    my $type = shift @_;
    
    # assumes all the parameters are present...
    
    my ($ret) = $self->exec_method(funcname=>$type."__save_location", args=>[
        $self->{user_id}, # entity_id           
        $self->{location_id}, # location_id
        $self->{location_class}, # location class, for _to_contact
        $self->{line_one},
        $self->{line_two},
        $self->{line_three}, # address info
        $self->{city}, # city
        $self->{state}, # state/province
        $self->{mail_code},
        $self->{country} # obviously, country.
    ]);
    $self->{id} = $ret->{$type."__save_location"};
    $self->{dbh}->commit();
    return $self->{id};
}

sub delete {
    
    my $self = shift @_;
    my $type = shift @_;
    my $id = shift @_;
    my $e_id = shift @_;
    
    # e_id is an entity
    # id is the location_id
    
    
    if (!$id && !$self->{location_id}) {
        $self->error("Must call delete with an ID...");
    }
    unless ($id) {
        $id = $self->{location_id};
    }
    
    my ($res) = $self->exec_method(funcname=>$type."__delete_location", args=>[$e_id,$id]);
    
    return $res->[0];
}

sub get {
    
    my $self = shift @_;
    my $id = shift @_;
    
    my ($ret) = $self->exec_method(funcname=>"location__get", args=>[$id]);
    
    return $ret->{location__get};
}

sub get_all {
    
    my $self = shift @_;
    my $user_id = shift @_;
    my $type = shift @_;
    
    my @locations = $self->exec_method(funcname=>$type."__all_locations", args=>[$user_id]);
    return \@locations;
}
1;