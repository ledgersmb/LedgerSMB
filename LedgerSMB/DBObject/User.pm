package LedgerSMB::DBObject::User;

use base qw/LedgerSMB::DBObject/;

sub save {
    
    my $self = shift @_;
    
    my $user = $self->get();
    
    if ( $user->{id} && $self->{is_a_user} ) {
    
        # doesn't check for the password - that's done in the sproc.
        $self->{id} = shift @{ $self->exec_method(procname=>'admin_save_user', 
            args=>[$user->{id}, $self->{username}, $self->{password}] ) }; 
        if (!$self->{id}) {
            
            return 0;
        }
    }
    elsif ($user && !$self->{is_a_user}) {
        
        # there WAS a user, and we've decided we want that user to go away now.
        
        $self->{id} = $user->{id};
        return $self->remove();
        
    }
    elsif ($self->{is_a_user}) {
        
        # No user ID, meaning, creating a new one.        
        $self->{id} = shift @{ $self->exec_method(procname=>'admin_save_user', 
            args=>[undef, $self->{username}, $self->{password}] ) };
    }
    return 1;
}

sub get {
    
    my $self = shift @_;
    
    my ($user_id, $username) = @{ $self->exec_method(procname=>'admin_get_user',
        args=>[$self->{id}])};
        
    return {id=>$user_id, username=>$username};
}

sub remove {
    
    my $self = shift;
    
    my $code = $self->exec_method(procname=>"admin_delete_user", args=>[$self->{id}, $self->{username}]);
    $self->{id} = undef; # never existed..
    
    return $code->[0];
}

sub save_prefs {
    
    my $self = shift @_; 
    
    my $pref_id = $self->exec_method(procname=>"admin_save_preferences", 
        args=>[
            'language',
            'stylesheet',
            'printer',
            'dateformat',
            'numberformat'
        ]
    );
}

sub get_all_users {
    
    my $self = shift @_;
    
    $self->{users} = $self->exec_method( procname=>"user_get_all_users" );
}

1;
