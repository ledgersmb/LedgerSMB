

package LedgerSMB::Batch;
use base qw(LedgerSMB::DBObject);

sub create {
    $self = shift @_;
    my ($ref) = $self->exec_method(funcname => 'batch_create');
    print STDERR "$ref, $ref->{batch_create}, " . join (':', keys %$ref);
    $self->{id} = $ref->{batch_create};
    return $ref->{id};
}

1;
