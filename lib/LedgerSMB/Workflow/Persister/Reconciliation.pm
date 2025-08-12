package LedgerSMB::Workflow::Persister::Reconciliation;

=head1 NAME

LedgerSMB::Workflow::Persister::Reconciliation - Reconciliation workflow persistence

=head1 DESCRIPTION

This module provides e-mail attachment metadata to e-mail workflow.

The class inherits from LedgerSMB::Workflow::Persister::ExtraData; users are
expected to declare the email table and fields as "ExtraData" configuration.

=head1 METHODS

=cut


use v5.36;
use strict;
use parent qw( LedgerSMB::Workflow::Persister );



=head2 create_workflow

Creates a new workflow and associates it with the transaction identified
by the C<trans_id> context parameter.

Throws an exception if the identified transaction already has a workflow
associated.

=cut

sub create_workflow($self, $wf) {
    my $wf_id = $self->SUPER::create_workflow( $wf );
    my $dbh   = $self->handle;
    my $sth   = $dbh->prepare(
        q|select reconciliation__new_report(?,?,?,?,?)|
        ) or die $dbh->errstr;

    $sth->execute(
        $wf->context->param( 'account_id' ),
        $wf->context->param( 'ending_balance' ),
        $wf->context->param( 'end_date' ),
        $wf->context->param( 'recon_fx' ),
        $wf_id,
        )
        or die $sth->errstr;

    my ($id) = $sth->fetchrow_array;
    $wf->context->param( 'id', $id );

    return $wf_id;
}

=head2 update_workflow

Stores updates to existing workflows.

=cut

sub update_workflow($self, $wf) {
    my $ctx = $wf->context;
    my $dbh = $self->handle;

    if ($ctx->delete_param( 'approved' )) {
        $dbh->do(q|select reconciliation__report_approve(?)|,
                 {},
                 $ctx->param( 'id' ))
            or die $dbh->errstr;
    }
    elsif ($ctx->delete_param( 'rejected' )) {
        $dbh->do(q|select reconciliation__reject_set(?)|,
                 {},
                 $ctx->param( 'id' ))
            or die $dbh->errstr;
    }
    elsif ($ctx->delete_param( 'submitted' )) {
        $dbh->do(q|select reconciliation__submit_set(?)|,
                 {},
                 $ctx->param( 'id' ))
            or die $dbh->errstr;
    }
    elsif ($ctx->delete_param( 'deleted' )) {
        if ($wf->state eq 'APPROVED') {
            $dbh->do(q|select reconciliation__delete_my_report(?)|,
                     {},
                     $ctx->param( 'id' ))
                or die $dbh->errstr;
        }
        else {
            $dbh->do(q|select reconciliation__delete_unapproved(?)|,
                     {},
                     $ctx->param( 'id' ))
                or die $dbh->errstr;
        }
    }

    $self->SUPER::update_workflow( $wf );
    return;
}


1;

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2024 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

