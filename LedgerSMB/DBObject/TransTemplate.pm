package LedgerSMB::DBObject::TransTemplate;
use base qw(LedgerSMB::PGOld);
use strict;
use warnings;
use Log::Log4perl;

sub save {
   my $self = shift @_;
   my $logger = Log::Log4perl->get_logger("LedgerSMB");

   $self->{is_template} = '1';
   $self->{approved} = 0;
   $self->{reference} = $self->{invnumber} if $self->{invnumber};
   my ($ref) = $self->exec_method(funcname => 'journal__add');
   $self->merge($ref);
   $self->{journal_id} = $self->{id};
   for my $line (@{$self->{journal_lines}}){
       my $l = bless $line, 'LedgerSMB::DBObject';
       $l->{_locale} = $self->{_locale};
       $l->{dbh} = $self->{dbh};
       $l->{journal_id} = $self->{id};
       my ($ref) = $l->call_dbmethod(funcname => 'account__get_from_accno');
       $l->{account_id} = $ref->{id};
       $logger->debug( "$l->{accno}\n" );
       if (!$ref->{id}){
           $self->error($self->{_locale}->text('No Account id for [_1]', $l->{accno}));
       }
       $l->call_dbmethod(funcname=> 'journal__add_line');
   }
   if ($self->{is_invoice}){
       $self->call_dbmethod(funcname => 'journal__make_invoice');
   }
   if ($self->{recurringreference}){
       $self->call_dbmethod(funcname => 'journal__save_recurring');
       $self->call_dbmethod(funcname => 'journal__save_recurring_print');
   }
}

sub search {
   my $self = shift @_;
   $self->{approved} = 'false';
   $self->{is_template} = 'true';
   @{$self->{search_results}} = $self->call_dbmethod(
            funcname => 'journal__search'
   );
}

sub retrieve {
   my $self = shift @_;
   my @vals = $self->call_dbmethod(funcname => 'journal__retrieve');
   $self->merge(shift @vals);
   @{$self->{line_items}} = $self->call_dbmethod(funcname => 'journal__retrieve_lines');
   ($self->{inv_data}) = $self->call_dbmethod(funcname => 'journal__retrieve_invoice');
}

sub get {
    my ($self) = @_;
    my ($ref) = $self->call_dbmethod(funcname => 'journal__get_entry');
    $self->merge($ref);
    @{$self->{line_items}} =  $self->call_dbmethod(funcname => 'journal__lines');
    ($self->{invoice_data}) =
                 $self->call_dbmethod(funcname => 'journal__get_invoice');
    if ($self->{invoice_data}->{credit_id}){
        ($self->{credit_data}) = $self->call_procedure(
               funcname => 'entity_credit__get',
               args     => [$self->{invoice_data}->{credit_id}]
        );
    }
}

sub get_account_info {
    my ($self, $acct_id) = @_;
    my ($ref) = $self->call_procedure(
               funcname => 'account_get',
               args     => [$acct_id]
    );
    return $ref;
}

1;
