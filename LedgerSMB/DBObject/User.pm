package LedgerSMB::DBObject::User;

use base qw/LedgerSMB::DBObject/;
use Data::Dumper;

sub save {
    
    my $self = shift @_;
    
    my $user = $self->get();
    
    if ( $user->{id} && $self->{is_a_user} ) {
    
        # doesn't check for the password - that's done in the sproc.
        $self->{id} = shift @{ $self->exec_method(funcname=>'admin__save_user', 
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
        $self->{id} = shift @{ $self->exec_method(funcname=>'admin__save_user', 
            args=>[undef, $self->{username}, $self->{password}] ) };
    }
    return 1;
}

sub get {
    
    my $self = shift @_;
    my $id = shift;
    my $user = @{ $self->exec_method(funcname=>'admin__get_user',
        args=>[$id])}[0];
        
    return $user;
}

sub remove {
    
    my $self = shift;
    
    my $code = $self->exec_method(funcname=>"admin__delete_user", args=>[$self->{id}, $self->{username}]);
    $self->{id} = undef; # never existed..
    
    return $code->[0];
}

sub save_prefs {
    
    my $self = shift @_; 
    
    my $pref_id = $self->exec_method(funcname=>"admin__save_preferences", 
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
    
    my @ret = $self->exec_method( funcname=>"user__get_all_users" );
    $self->{users} = \@ret;
}

1;
