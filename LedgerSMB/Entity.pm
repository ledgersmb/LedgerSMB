package LedgerSMB::Entity;

use base qw/LedgerSMB::DBObject/;

sub save {
    
    my $self = shift @_;
    
    my $id = @{ $self->exec_method(procname=>'entity_save', 
        args=>[
            $self->{name},
            $self->{entity_class},
        ]
    )};
    
    $self->{id} = shift @{ $id };
    return $self->{id};
}

sub get {
    
    my $self = shift @_;
    
    my $hashref = $self->exec_method(procname=>'entity_get', args=>[$self->{id}]);
    $self->merge($hashref);
    return $self->{id};
    
}

sub search {
    
    # Shouldn't really be necessary.. 
    
    # anyway, Search on name.
    my $self = shift @_;
    
    my @list = @{ $self->exec_method( procname=>'entity_search', 
        args=>[ 
            $self->{name}
        ]
    ) };
}
1;
