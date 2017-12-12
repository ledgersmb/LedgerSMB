package LedgerSMB::DBObject::TransTemplate;
use base qw(LedgerSMB::PGOld);
use strict;
use warnings;
use Log::Log4perl;

use LedgerSMB::Magic qw(JRNL_GJ JRNL_AR JRNL_AP EC_CUSTOMER EC_VENDOR);

=head1 NAME

LedgerSMB::DBObject::TransTemplate -- Template transactions for LedgerSMB

=head1 SYNOPSIS

  my $ttrans = LedgerSMB::DBObject::TransTemplate->new(base => $request);
  $ttrans->save();

=head1 DESCRIPTION

Template transactions are defined examples of transactions that are likely to
recur frequently.  They are stored in the database but never part of the books.

They can be modified and then posted.

These modules use what is expected to eventually become the next generation of journal schema for the database.

=head1 METHODS

=head2 save

Saves the given input as a template transaction.

=cut

sub save {
   my $self = shift @_;
   my $logger = Log::Log4perl->get_logger("LedgerSMB");

   $self->{is_template} = '1';
   $self->{approved} = 0;
   $self->{journal} = JRNL_GJ;
   $self->{journal} = JRNL_AR
       if $self->{entity_class} == EC_CUSTOMER;
   $self->{journal} = JRNL_AP
       if $self->{entity_class} == EC_VENDOR;
   if (not defined $self->{curr}){
      my ($curr) = $self->call_dbmethod(funcname => 'defaults_get_defaultcurrency');
      ($self->{curr}) = values(%$curr);
   }
   $self->{currency} //= $self->{curr};
   $self->{reference} = $self->{invnumber} if $self->{invnumber};
   for (qw(effective_start effective_end post_date reference)){
      delete $self->{$_} unless $self->{$_};
   }
   my ($ref) = $self->call_dbmethod(funcname => 'journal__add');
   $self->merge($ref);
   $self->{journal_id} = $self->{id};
   for my $line (@{$self->{journal_lines}}){
       my $l = bless $line, 'LedgerSMB::PGOld';
       $l->{_locale} = $self->{_locale};
       $l->set_dbh(LedgerSMB::App_State::DBH());
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
   return;
}

=head2 search

Searches on supplied criteria (by default just lists all templates)

Normal journal entry search criteria apply.

=cut

sub search {
   my $self = shift @_;
   $self->{approved} = 'false';
   $self->{is_template} = 'true';
   return @{$self->{search_results}} = $self->call_dbmethod(
            funcname => 'journal__search' );
}

=head2 get

Retrieves a given template transaction

=cut

sub get {
    my ($self) = @_;
    my ($ref) = $self->call_dbmethod(funcname => 'journal__get_entry');
    $self->merge($ref);
    @{$self->{line_items}} =  $self->call_dbmethod(funcname => 'journal__lines');
    ($self->{invoice_data}) =
                 $self->call_dbmethod(funcname => 'journal__get_invoice');
    if ($self->{invoice_data}->{credit_id}){
        return ($self->{credit_data}) = $self->call_procedure(
               funcname => 'entity_credit__get',
               args     => [$self->{invoice_data}->{credit_id}]
        );
    }
    return;
}

=head2 get_account_info

Gets information for a given chart of account entry.

DEPRECATED.  Retrieve via account class instead.

=cut

sub get_account_info {
    my ($self, $acct_id) = @_;
    my ($ref) = $self->call_procedure(
               funcname => 'account_get',
               args     => [$acct_id]
    );
    return $ref;
}

=head2 delete

Removes template from database

=cut

sub delete {
    my ($self, $id) = @_;

    return $self->call_procedure(funcname => 'journal__delete',
                          args => [ $id ]);
}

1;

=head1 COPYRIGHT

Copytight (C) 2016, the LedgerSMB Core Team.  This file may be re-used under the
terms of the GNU GPL version 2 or at your option any later version.  Please see
the included LICENSE.txt for more information.

