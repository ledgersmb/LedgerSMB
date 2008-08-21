package LedgerSMB::DBObject::Admin;

use base LedgerSMB::DBObject;

use LedgerSMB::DBObject::Location;
use LedgerSMB::DBObject::Employee;
use LedgerSMB::DBObject::Contact;

sub save_user {
    
    my $self = shift @_;
    
    my $entity_id = shift @{ $self->exec_method( funcname => "save_user" ) };
    $self->merge($entity_id);
    
    my $employee = LedgerSMB::DBObject::Employee->new(base=>$self, copy=>'list',
        merge=>[
            'salutation',
            'first_name',
            'last_name',
            'employeenumber',
        ]    
    );
    
    $employee->{entity_id} = $entity_id->{id};    
    $employee->save_employee();
        
    my $loc = LedgerSMB::DBObject::Location->new(base=>$self, copy=>'list', 
        merge=>[
            'address1',
            'address2',
            'city',
            'state',
            'zipcode',
            'country',
            'companyname',            
        ]
    );
    $loc->save_location();
    $loc->join_to_person(person=>$employee);
    
    
    my $contact = LedgerSMB::DBObject::Contact->new(base=>$self, copy=>'list', 
        merge=>[
            'workphone',
            'homephone',
            'email',
        ]
    );
    
    $contact->save_homephone(person=>$employee);
    $contact->save_workphone(person=>$employee);
    $contact->save_email(person=>$employee);
    
    my $roles = $self->exec_method( funcname => "all_roles" );
    my $user_roles = $self->exec_method(funcname => "get_user_roles", args=>[ $self->{ modifying_user } ] );
    
    my %active_roles;
    for my $role (@{$user_roles}) {
       
       # These are our user's roles.
        
       $active_roles{$role} = 1;
    }
    
    my $status;
    
    for my $role ( @{ $roles } ) {
        
        # These roles are were ALL checked on the page, so they're the active ones.
        
        if ($active_roles{$role} && $self->{incoming_roles}->{$role}) {
            
            # do nothing.
        }
        elsif ($active_roles{$role} && !($self->{incoming_roles}->{$role} )) {
            
            # do remove function
            $status = $self->exec_method(funcname => "remove_user_from_role",
                args=>[ $self->{ modifying_user }, $role ] 
        }
        elsif ($self->{incoming_roles}->{$role} and !($active_roles{$role} )) {
            
            # do add function
            $status = $self->exec_method(funcname => "add_user_to_role",
               args=>[ $self->{ modifying_user }, $role ] 
            );
        }         
    }
}

sub save_group {
    
     my $self = shift @_;
     
     my $existant = shift @{ $self->exec_method (funcname=> "is_group", args=>[$self->{modifying_group}]) };
     
     my $group = shift @{ $self->exec_method (funcname=> "save_group") };
     
     # first we grab all roles
     
     my $roles = $self->exec_method( funcname => "all_roles" );
     my $user_roles = $self->exec_method(funcname => "get_user_roles", 
        args=>[ $self->{ group_name } ] 
    );

     my %active_roles;
     for my $role (@{$user_roles}) {

        # These are our user's roles.

        $active_roles{$role} = 1;
     }

     my $status;

     for my $role ( @{ $roles } ) {

         # These roles are were ALL checked on the page, so they're the active ones.

         if ($active_roles{$role} && $self->{incoming_roles}->{$role}) {

             # we don't need to do anything.
         }
         elsif ($active_roles{$role} && !($self->{incoming_roles}->{$role} )) {

             # do remove function
             $status = $self->exec_method(
                 funcname => "remove_group_from_role",
                 args=>[ $self->{ modifying_user }, $role ] 
             );
         }
         elsif ($self->{incoming_roles}->{$role} and !($active_roles{$role} )) {

             # do add function
             $status = $self->exec_method(
                 funcname => "add_group_to_role",
                 args=>[ $self->{ modifying_user }, $role ] 
             );
         }         
     }     
}


sub delete_user {
    
    my $self = shift @_;
    
    my $status = shift @{ $self->exec_method(funcname=>'delete_user', args=>[$self->{modifying_user}]) };
    
    if ($status) {
        
        return 1;
    } else {
        
        my $error = LedgerSMB::Error->new("Delete user failed.");
        $error->set_status($status);
        return $error;
    }
}

sub delete_group {
    
    my $self = shift @_;
    
    my $status = shift @{ $self->exec_method(funcname=>'delete_group', args=>[$self->{groupname}])};
    
    if ($status) {
        
        return 1;
    } else {
        
        my $error = LedgerSMB::Error->new("Delete group failed.");
        $error->set_status($status);
        return $error;
    }
}

sub get_entire_user {
    
    my $self = shift @_;
    my $id = shift @_;
    my $user = {};
    my $u = LedgerSMB::DBObject::User->new(base=>$self,copy=>'all');
    $user->{user} = $u->get($id);
    $user->{pref} = $u->preferences($id);
    $user->{employee} = $u->employee($user->{user}->{entity_id});
    $user->{person} = $u->person($user->{user}->{entity_id});
    $user->{entity} = $u->entity($id);
    $user->{roles} = $u->roles($id);
    
    return $user;
}

sub get_roles {
    
    my $self = shift @_;
    
    return $self->exec_method(funcname=>'get_roles',args=>[$self->{company}]);
}

1;