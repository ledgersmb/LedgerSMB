package LedgerSMB::DBObject::Admin;

use base LedgerSMB::DBObject;

use LedgerSMB::Location;
use LedgerSMB::DBObject::Employee;
use LedgerSMB::Contact;
use LedgerSMB::Entity;

#[18:00:31] <aurynn> I'd like to split them employee/user and roles/prefs
#[18:00:44] <aurynn> edit/create employee and add user features if needed.

sub save {
    
    $self->error("Cannot save an Adminstrator object.");
}

sub save_user {
    
    my $self = shift @_;
    
    my $entity = LedgerSMB::DBObject::Entity->new(base=>$self, copy=>'none');
    
    $entity->set(name=>$self->{first_name}." ".$self->{last_name});
    $entity->save();
    
    $self->{entity_id} = $entity->{id};
    
    
    my $user_id = shift @{ $self->exec_method( procname => "admin__save_user" ) };
    $self->merge($user_id);
    
    my $person = LedgerSMB::DBObject::Person->new( base=>$self, copy=>'list',     
        merge=>[
            'salutation',
            'first_name',
            'last_name',
        ]
    );
    my $employee = LedgerSMB::DBObject::Employee->new( base=>$self, copy=>'list',
        merge=>[
            'salutation',
            'first_name',
            'last_name',
            'employeenumber',
        ]    
    );
    
    $employee->{entity_id} = $entity_id->{id};    
    $employee->save();
        
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
    
    $loc->save();
    $employee->set_location($loc->{id});
    $loc->(person=>$employee);
        
    my $workphone = LedgerSMB::Contact->new(base=>$self);
    my $homephone = LedgerSMB::Contact->new(base=>$self);
    my $email = LedgerSMB::Contact->new(base=>$self);
    
    $workphone->set(person=>$employee, class=>1, contact=>$self->{workphone});
    $homephone->set(person=>$employee, class=>11, contact=>$self->{homephone});
    $email->set(person=>$employee, class=>12, contact=>$self->{email});
    $workphone->save();
    $homephone->save();
    $email->save();
    
    # now, check for user-specific stuff. Is this person a user or not?
    
    my $user = LedgerSMB::DBObject::User->new(base=>$self, copy=>'list',
        merge=>[
            'username',
            'password',
            'is_a_user'
        ]
    );
    $user->get();
    $user->save();
}

sub save_roles {
    
    my $self = shift @_;
    
    my $user = LedgerSMB::DBObject::User->new( base=>$self, copy=>'all' );
    
    my $roles = $self->exec_method( procname => "admin__all_roles" );
    my $user_roles = $self->exec_method(procname => "admin__get_user_roles", args=>[ $self->{ username } ] );
    
    my %active_roles;
    for my $role (@{ $user_roles }) {
       
       # These are our user's roles.
        
       $active_roles{$role} = 1;
    }
    
    my $status;
    
    for my $role ( @{ $roles } ) {
        
        # These roles are were ALL checked on the page, so they're the active ones.
        
        if ($active_roles{$role} && $self->{$role}) {
            
            # do nothing.
        }
        elsif ($active_roles{$role} && !($self->{$role} )) {
            
            # do remove function
            $status = $self->exec_method(procname => "admin__remove_user_from_role",
                args=>[ $self->{ modifying_user }, $role ] );
        }
        elsif ($self->{incoming_roles}->{$role} and !($active_roles{$role} )) {
            
            # do add function
            $status = $self->exec_method(procname => "admin__add_user_to_role",
               args=>[ $self->{ modifying_user }, $role ] 
            );
        }         
    }
}

sub save_group {
    
     my $self = shift @_;
     
     my $existant = shift @{ $self->exec_method (procname=> "is_group", args=>[$self->{modifying_group}]) };
     
     my $group = shift @{ $self->exec_method (procname=> "save_group") };
     
     # first we grab all roles
     
     my $roles = $self->exec_method( procname => "admin__all_roles" );
     my $user_roles = $self->exec_method(procname => "admin__get_user_roles", 
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
                 procname => "admin__remove_group_from_role",
                 args=>[ $self->{ modifying_user }, $role ] 
             );
         }
         elsif ($self->{incoming_roles}->{$role} and !($active_roles{$role} )) {

             # do add function
             $status = $self->exec_method(
                 procname => "admin__add_group_to_role",
                 args=>[ $self->{ modifying_user }, $role ] 
             );
         }         
     }     
}


sub delete_user {
    
    my $self = shift @_;
    
    my $status = shift @{ $self->exec_method(procname=>'admin__delete_user', 
        args=>[$self->{modifying_user}]) 
    };
    
    if ($status) {
        
        return 1;
    } else {
        
        $self->error('Delete user failed.');
        #my $error = LedgerSMB::Error->new("Delete user failed.");
        #$error->set_status($status);
        #return $error;
    }
}

sub delete_group {
    
    my $self = shift @_;
    
    my $status = shift @{ $self->exec_method(procname=>'admin__delete_group', 
        args=>[$self->{groupname}]) }
    ;
    
    if ($status) {
        
        return 1;
    } else {
        
        $self->error('Delete group failed.');
        #my $error = LedgerSMB::Error->new("Delete group failed.");
        #$error->set_status($status);
        #return $error;
    }
}

sub get_salutations {
    
    my $self = shift;
    
    my $sth = $self->{dbh}->prepare("SELECT * FROM salutation ORDER BY id ASC");
    
    $sth->execute();
    
    # Returns a list of hashrefs
    return $sth->fetchall_arrayref( {} );
}


sub get_roles {
    
    # These are direct, assignable roles. 
    my $self = shift;
    
    return $self->exec_method( procname => "admin__all_roles" );
}
1;
