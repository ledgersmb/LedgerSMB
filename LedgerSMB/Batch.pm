

package LedgerSMB::Batch;
use base qw(LedgerSMB::DBObject);

sub create {
    $self = shift @_;
    my ($ref) = $self->exec_method(funcname => 'batch_create');
    $self->{id} = $ref->{batch_create};
    $self->{dbh}->commit;
    return $ref->{id};
}

sub delete_voucher {
    my ($self, $voucher_id) = @_;
    $self->call_procedure(procname => 'voucher__delete', args => [$voucher_id]);
    $self->{dbh}->commit;
}


sub get_search_criteria {
    $self = shift @_;
    my ($custom_types) = @_;
    @{$self->{batch_classes}} = $self->exec_method(
         funcname => 'batch_list_classes'
    );
    for (keys %$custom_types){
        if ($custom_types->{$_}->{map_to}){
            push @{$self->{batch_classes}}, {id => $_, class => $_};
        }
    }

    @{$self->{batch_users}} = $self->exec_method(
         funcname => 'batch_get_users'
    );
    unshift @{$self->{batch_users}}, {username => $self->{_locale}->text('Any'), id => '0', entity_id => ''};
}

sub get_search_results {
    my ($self, $args) = @_;
    if ($args->{mini}){
        $search_proc = "batch_search_mini";
    } else {
        $search_proc = "batch_search";
    }
    if ($args->{custom_types}->{$self->{class_id}}->{select_method}){
        $search_proc 
             = $args->{custom_types}->{$self->{class_id}}->{select_method}; 
    } elsif ($self->{class_id} =~ /[\D]/){
          $self->error("Invalid Batch Type");
    }
    @{$self->{search_results}} = $self->exec_method(funcname => $search_proc);
    return @{$self->{search_results}};
}

sub get_class_id {
    my ($self, $type) = @_;
    @results = $self->call_procedure(
                                    procname => 'batch_get_class_id', 
                                     args     => [$type]
    );
    my $result = pop @results;
    return $result->{batch_get_class_id};
}

sub post {
    my ($self) = @_;
    ($self->{post_return_ref}) = $self->exec_method(funcname => 'batch_post');
    $self->{dbh}->commit;
    return $self->{post_return_ref};
}

sub delete {
    my ($self) = @_;
    ($self->{delete_ref}) = $self->exec_method(funcname => 'batch_delete');
    $self->{dbh}->commit;
    return $self->{delete_ref};
}

sub list_vouchers {
    my ($self) = @_;
    @{$self->{vouchers}} = $self->exec_method(funcname => 'voucher_list');
    return @{$self->{vouchers}};
}

sub get {
    my ($self) = @_;
    my ($ref) = $self->exec_method(funcname => 'voucher_get_batch');
    $self->merge($ref);
}

1;
