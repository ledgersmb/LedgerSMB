

package LedgerSMB::Batch;
use base qw(LedgerSMB::DBObject);

sub create {
    $self = shift @_;
    my ($ref) = $self->exec_method(funcname => 'batch_create');
    $self->{id} = $ref->{id}
    return $ref->{id};
}

1;
