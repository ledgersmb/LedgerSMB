
# A few things that are suboptimmal about this file.
# 1)  No use of discovery in stored proc arg lists means that API's are brittle
# 2)  Dynamic generation of sproc names makes this extremely hard to use to 
# find if a sproc is used or not.  This also (as per #1) forces sprocs to share
# exactly identical argument lists which is a problem in terms of API 
# flexibility.  I am inclined to mark this "depricated" despite the fact that 
# this is new code.    Right now this is only used by user management routines
# and it should stay that way.
#
# --CT
#

package LedgerSMB::DBObject::Location;

use base LedgerSMB::DBObject;

sub create {
    
    my $self = shift @_;
}

sub save {
    
    my $self = shift @_;
    my $type = shift @_;
    
    # assumes all the parameters are present...
            'address1',
            'address2',
            'city',
            'state',
            'zipcode',
            'country',
            'companyname',            
    
    my ($ret) = $self->exec_method(funcname=>$type."__save_location", args=>[
        $self->{user_id}, # entity_id           
        $self->{location_id}, # location_id
        $self->{location_class} || 1, # location class, for _to_contact
        $self->{line_one} || $self->{'address1'},
        $self->{line_two} || $self->{'address2'},
        $self->{line_three}, # address info
        $self->{city}, # city
        $self->{state}, # state/province
        $self->{mail_code} || $self->{'zipcode'},
        $self->{country}, # obviously, country.
        $self->{old_location_class} || 1 # obviously, country.
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

1;
