package LedgerSMB::DBObject::Draft;

use base qw/LedgerSMB::DBObject/;

sub search {
    my ($self) = @_;
    @{$self->{draft_results}} = $self->exec_method(funcname => 'draft__search');
    return @{$self->{draft_results}};
}

sub approve {
   my ($self) = @_;
   if (!$self->{id}){
       $self->error($self->{_locale}->text('No ID Set'));
   }
   ($self->{approved}) = $self->exec_method(funcname => 'draft_approve');
   $self->{dbh}->commit;
   return $self->{approved};
}

sub delete {
   my ($self) = @_;
   if (!$self->{id}){
       $self->error($self->{_locale}->text('No ID Set'));
   }
   ($self->{deleted}) = $self->exec_method(funcname => 'draft_delete');
   return $self->{deleted};
}

1;
