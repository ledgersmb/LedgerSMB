
use v5.36;
use warnings;

package LedgerSMB::Workflow::Action::TransactionApprove;

=head1 NAME

LedgerSMB::Workflow::Action::TransactionApprove - Approve draft AR/AP/GL transactions

=head1 SYNOPSIS

  # action configuration
  <actions>
    <action name="Approve" class="LedgerSMB::Workflow::Action::TransactionApprove"
            history-text="Some description for the workflow history" />
  </actions>


=head1 DESCRIPTION

This module implements an action which approves a transaction, synchronizing the
workflow state to the C< transactions > table.

=head1 METHODS

=cut

use parent qw( LedgerSMB::Workflow::Action::Null );

=head2 execute($wf)

Implements the C<Workflow::Action> protocol.

=cut

my $query = <<~'SQL';
  select draft_approve(id)
    from transactions
   where workflow_id = ? and not approved
  SQL

sub execute( $self, $wf ) {
    $self->SUPER::execute($wf);

    my $dbh = $wf->handle;
    $dbh->do($query, {}, $wf->id)
        or die $dbh->errstr;

    return;
}

1;

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2024 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

