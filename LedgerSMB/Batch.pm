

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

sub post {
    my ($self) = @_;
    ($self->{post_return_ref}) = $self->exec_method(funcname => 'batch_post');
    return $self->{post_return_ref};
}

sub delete {
    my ($self) = @_;
    ($self->{delete_ref}) = $self->exec_method(funcname => 'batch_delete');
    return $self->{delete_ref};
}

1;
