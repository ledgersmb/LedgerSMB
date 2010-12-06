

package LedgerSMB::Batch;
use LedgerSMB::Setting;
use base qw(LedgerSMB::DBObject);

sub get_new_info {
    $self = shift @_;
    my $cc_object = LedgerSMB::Setting->new({base => $self});
    $cc_object->{key} = 'batch_cc';
    $self->{batch_number} = $cc_object->increment;
    $self->{dbh}->commit;
}

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
    unshift @{$self->{batch_users}}, {username => $self->{_locale}->text('Any'), id => '0', entity_id => '0'};
}

sub get_search_method {
	my ($self, @args) = @_;
	my $search_proc;
	
	if ($self->{empty}){
        $search_proc = "batch_search_empty";
    } elsif ($args->{mini}){
        $search_proc = "batch_search_mini";
    } else {
        $search_proc = "batch_search";
    }

    if ( !defined $self->{created_by_eid} || $self->{created_by_eid} == 0){
		delete $self->{created_by_eid};
    }

    if ( !defined $self->{class_id} )
    {
        delete $self->{class_id};
    }

    if ( ( defined $args->{custom_types} ) && ( defined $self->{class_id} ) && ( $args->{custom_types}->{$self->{class_id}}->{select_method} ) ){
        $search_proc 
             = $args->{custom_types}->{$self->{class_id}}->{select_method}; 
    } elsif ( ( defined $self->{class_id} ) && ( $self->{class_id} =~ /[\D]/ ) ){
          $self->error("Invalid Batch Type");
    }

	return $search_proc;
}

sub get_search_results {
    my ($self, $args) = @_;
	my $search_proc = $self->get_search_method($args);
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
