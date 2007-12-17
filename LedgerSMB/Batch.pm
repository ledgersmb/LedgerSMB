

package LedgerSMB::Batch;
use base qw(LedgerSMB::DBObject);

sub create {
    $self = shift @_;
    my ($ref) = $self->exec_method(funcname => 'batch_create');
    $self->{id} = $ref->{batch_create};
    $self->{dbh}->commit;
    return $ref->{id};
}

sub get_search_criteria {
    $self = shift @_;
    @{$self->{batch_classes}} = $self->exec_method(
         funcname => 'batch_list_classes'
    );

    @{$self->{batch_users}} = $self->exec_method(
         funcname => 'batch_get_users'
    );
}

sub get_search_results {
    my ($self) = @_; 
    @{$self->{search_results}} = $self->exec_method(funcname => 'batch_search');
    return @{$self->{search_results}};
}

1;
