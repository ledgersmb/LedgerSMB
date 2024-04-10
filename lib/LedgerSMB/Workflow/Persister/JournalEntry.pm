package LedgerSMB::Workflow::Persister::JournalEntry;

=head1 NAME

LedgerSMB::Workflow::Persister::Email - Attachment metadata

=head1 DESCRIPTION

This module provides e-mail attachment metadata to e-mail workflow.

The class inherits from LedgerSMB::Workflow::Persister::ExtraData; users are
expected to declare the email table and fields as "ExtraData" configuration.

=head1 METHODS

=cut


use v5.36;
use warnings;
use parent qw( LedgerSMB::Workflow::Persister::ExtraData );

=head2 create_workflow

Creates a new workflow and associates it with the transaction identified
by the C<trans_id> context parameter.

Throws an exception if the identified transaction already has a workflow
associated.

=cut

sub create_workflow($self, $wf) {
    my $id  = $self->SUPER::create_workflow( $wf );
    my $ctx = $wf->context;
    $ctx->param( "_old_$_", $ctx->param( $_ ) )
        for (qw( approved deleted ));

    return $id;
}

=head2 update_workflow

Saves the workflow and synchronizes the workflow state to the
C< transactions > table using the context parameter C< id >.

=cut

sub update_workflow($self, $wf) {
    my $ctx = $wf->context;

    if ($ctx->param( 'approved' )
        and not $ctx->param( '_old_approved' )) {
        my $dbh = $self->handle;
        my $sth = $dbh->prepare(<<~'SQL')
              select draft_approve(id)
                from transactions
               where id = ? and not approved
              SQL
            or die $dbh->errstr;
        $sth->execute($wf->context->param('id'))
            or die $sth->errstr;
        $sth->finish;
    }
    elsif ($ctx->param( 'deleted' )) {
        my $dbh = $self->handle;
        my $sth = $dbh->prepare(<<~'SQL')
              select draft_delete(id)
                from transactions
               where id = ?
              SQL
            or die $dbh->errstr;
        $sth->execute($wf->context->param('id'))
            or die $sth->errstr;
        $sth->finish;
    }

    $self->SUPER::update_workflow( $wf );
    $ctx->param( "_old_$_", $ctx->param( $_ ) )
        for (qw( approved deleted ));
    return;
}


1;

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020-2024 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

