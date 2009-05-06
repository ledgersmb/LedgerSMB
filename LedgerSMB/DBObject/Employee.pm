package LedgerSMB::DBObject::Employee;

use base qw(LedgerSMB::DBObject);
use strict;

my $ENTITY_CLASS = 3;

sub set_entity_class {
    my $self = shift @_;
    $self->{entity_class} = $ENTITY_CLASS;
}

sub save {
   my ($self) = @_;
   $self->set_entity_class();
   my ($ref) = $self->exec_method(funcname => 'person__save');
   $self->{entity} = $ref->{'person__save'};
   $self->exec_method(funcname => 'employee__save');
   $self->{dbh}->commit;
}

sub save_location {
}

sub save_contact {
}

sub save_bank_account {
}

sub save_note {
}
    
1;
