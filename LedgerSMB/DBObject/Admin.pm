package LedgerSMB::DBObject::Admin;

use base LedgerSMB::DBObject;

use LedgerSMB::Location;
use LedgerSMB::DBObject::Employee;
use LedgerSMB::Contact;
use LedgerSMB::DBObject::Employee;

#[18:00:31] <aurynn> I'd like to split them employee/user and roles/prefs
#[18:00:44] <aurynn> edit/create employee and add user features if needed.

sub save {
    
    $self->error("Cannot save an Adminstrator object.");
}

sub save_user {
    
    my $self = shift @_;
    
    my $entity = LedgerSMB::DBObject::Employee->new(base=>$self, copy=>'none');
    
    $entity->set(name=>$self->{first_name}." ".$self->{last_name});
    $entity->save();
    
    $self->{entity_id} = $entity->{entity};
    
    
    my ($user_id) = $self->exec_method( funcname => "admin__save_user" );
    $self->{user_id} = $user_id->{admin__save_user};
    
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
    # now, check for user-specific stuff. Is this person a user or not?
    
    my $user = LedgerSMB::DBObject::User->new(base=>$self, copy=>'list',
        merge=>[
            'username',
            'password',
            'is_a_user',
            'user_id',
        ]
    );
    $user->get();
    $self->{user} = $user;
    $self->{employee} = $employee;
    $self->debug({file => '/tmp/user11'});

    if ($self->{password}){
       return;
    }
 
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
    
}

sub save_roles {
    
    my $self = shift @_;
    
    my $user = LedgerSMB::DBObject::User->new( base=>$self, copy=>'all' );
    
    my $roles = $self->exec_method( procname => "admin__all_roles" );
    my $user_roles = $self->exec_method(procname => "admin__get_user_roles", args=>[ $user->{id} ] );
    
    my %active_roles;
    for my $role (@{ $user_roles }) {
       
       # These are our user's roles.
        
       $active_roles{$role} = 1;
    }
    
    my $status;
    
    for my $role ( @{ $roles } ) {
        
        # These roles are were ALL checked on the page, so they're the active ones.
        
        if ( $active_roles{$role} && $self->{$role} ) {
            
            # do nothing.
            ;
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
    
    my $self = shift @_;
#    print STDERR "attempting to get roles";
    my @s_rows = $self->call_procedure(procname=>'admin__get_roles');
    my @rows;
    for my $role (@s_rows) {
        my $rolname = $role->{'admin__get_roles'};
        my $company = $self->{company};
        $rolname =~ s/lsmb_${company}__//gi;
        push @rows, $rolname;
    }
    return \@rows;
}

sub get_countries {
    
    my $self = shift @_;
    
    @{$self->{countries}} 
          =$self->exec_method(funcname => 'location_list_country'); 
	# returns an array of hashrefs.
    $self->debug({file => '/tmp/user'});
    return $self->{countries};
}
sub get_contact_classes {
    
    my $self = shift @_;
    my $sth = $self->{dbh}->prepare("select id, class as name from contact_class");
    my $code = $sth->execute();
    return $sth->fetchall_arrayref({});
}
1;
