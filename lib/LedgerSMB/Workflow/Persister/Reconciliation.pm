package LedgerSMB::Workflow::Persister::Reconciliation;

=head1 NAME

LedgerSMB::Workflow::Persister::Reconciliation - Reconciliation workflow persistence

=head1 DESCRIPTION

This module provides e-mail attachment metadata to e-mail workflow.

The class inherits from LedgerSMB::Workflow::Persister::ExtraData; users are
expected to declare the email table and fields as "ExtraData" configuration.

=head1 CONTEXT VARIABLES

=head2 Persisted variables

=over 8

=item * account_id

=item * ending_balance

=item * end_date

=item * recon_fx

=back

=head2 Non-persisted variables

=over 8

=item * _book_todo

An array of items (payments, journal lines) represented as hashes with
keys C<source>, C<post_date>, C<amount>, C<links>; where C<links> is
an array of journal lines.

=item * _pending_items

An array of journal lines before the report end date which are available
for merging into the report (that is, lines which are not already part of
the report).

=item * _preceeding_draft_count

Number of draft transactions before the end date of the report.

=item * _recon_done

An array of hashes with the keys C<book> and C<stmt>; each a hash with
the same content as described under C<book_todo> and C<stmt_todo> respectively.

=item * _starting_cleared_balance

=item * _stmt_todo

An array of statement lines that have not been matched; hashes with at least
the keys C<post_date>, C<amount>, C<source>.

=back

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

    my @args = (
        $wf->context->param( 'account_id' ) // undef,
        $wf->context->param( 'ending_balance' ) // undef,
        $wf->context->param( 'end_date' ) // undef,
        $wf->context->param( 'recon_fx' ) // undef,
        $wf_id,
        );

    $sth->execute(@args)
        or die $sth->errstr;

    my ($id) = $sth->fetchrow_array;
    $wf->context->param( 'id', $id );

    return $wf_id;
}

=head2 fetch_workflow

=cut

sub fetch_workflow($self, $wf_id) {
    my $wf_info = $self->SUPER::fetch_workflow($wf_id);
    return unless $wf_info;

    my $dbh     = $self->handle;
    $wf_info->{context} //= {};

    # Retrieve pending book items (acc_trans lines)
    $wf_info->{context}->{_pending_items} = [];

    # Retrieve todo book lines
    $wf_info->{context}->{_book_todo} = [];

    # Retrieve todo statement lines
    $wf_info->{context}->{_stmt_todo} = [];

    # Retrieve reconciled book+statement items
    $wf_info->{context}->{_book_done} = [];

    # Retrieve draft transaction lines before report closing date
    $wf_info->{preceeding_draft_count} = 0;

    return $wf_info;
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

