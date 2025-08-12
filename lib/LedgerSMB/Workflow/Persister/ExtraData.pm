package LedgerSMB::Workflow::Persister::ExtraData;

=head1 NAME

LedgerSMB::Workflow::Persister::ExtraData - Store additional workflow data

=head1 SYNOPSIS

  <persisters>
    <persister name="Email"
               class="LedgerSMB::Workflow::Persister::ExtraData"
               driver="Pg"
               extra_table="email"
               extra_data_field="from,to,cc,bcc,notify,subject,body,sent_date">
    </persister>
  </persisters>

=head1 DESCRIPTION

This module loads additional data for workflows from a specified table.

The class inherits from Workflow::Persister::DBI::ExtraData and uses
the same configuration semantics. Like L<LedgerSMB::Workflow::Persister>,
this module uses the existing database connection from
C<LedgerSMB::App_State::DBH>.

=head1 METHODS

=cut


use warnings;
use strict;
use parent qw( Workflow::Persister::DBI::ExtraData );

use Log::Any qw($log);

use JSON::MaybeXS;

use LedgerSMB::App_State;

=head2 create_handle()

Implements Workflow::Persister::DBI protocol; returns undef.

=cut

sub create_handle {
    return undef;
}

=head2 handle()

Implements Workflow::Persister::DBI protocol; returns the handle for the
current request from C<LedgerSMB::App_State::DBH()>.

=cut

sub handle {
    LedgerSMB::App_State::DBH()->{RaiseError} = 1
        if LedgerSMB::App_State::DBH();
    return LedgerSMB::App_State::DBH();
}

=head2 fetch_workflow( $wf_id )


Implements Workflow::Persister protocol; in addition to restoring the
workflow state (as per the parent persister Workflow::Persister::DBI),
also restores the workflow context.

=cut


my $json = JSON::MaybeXS->new(
    pretty => 0, indent => 0, convert_blessed => 0,
    allow_bignum => 1, utf8 => 0, space_before => 0,
    space_after => 0, canonical => 0, allow_barekey => 0,
    allow_singlequote => 0 );

sub fetch_workflow {
    my ($self, $wf_id) = @_;

    my $wf_info = $self->SUPER::fetch_workflow( $wf_id );
    if ($wf_info) { # found
        my $dbh = $self->handle;
        my $sth = $dbh->prepare(
            q{SELECT * FROM workflow_context WHERE workflow_id = ?}
            )
            or die $dbh->errstr;

        $sth->execute( $wf_id )
            or die $sth->errstr;
        if (my $row = $sth->fetchrow_hashref( 'NAME_lc' )) {
            $wf_info->{context} = {
                $json->decode( $row->{context} )->%*,
                ($wf_info->{context} // {})->%*
            };
        }
        else {
            $sth->err and die $sth->errstr;
        }
    }

    return $wf_info;
}

=head2 create_workflow( $wf )

Implements Workflow::Persister protocol; in addition to initializing
the workflow state (as per the parent persister Workflow::Persister::DBI),
also persists the workflow context.

=cut

sub _persist_context {
    my ($self, $wf) = @_;
    my $dbh = $self->handle;
    my $sth = $dbh->prepare(
        q{
        INSERT INTO workflow_context (workflow_id, context) VALUES ($1, $2)
            ON CONFLICT (workflow_id) DO UPDATE SET context = $2 }
        ) or die $dbh->errstr;

    my $params = $wf->context->{PARAMS};
    my $ctx = {
        map { $_ => $params->{$_} }
        grep { ! /^_/ }
        keys $params->%*
    };
    $sth->execute( $wf->id, $json->encode($ctx) )
        or die $sth->errstr;
}


sub create_workflow {
    my ($self, $wf) = @_;
    my $id = $self->SUPER::create_workflow( $wf );
    $self->_persist_context( $wf );

    return $id;
}

=head2 update_workflow( $wf )

Implements Workflow::Persister protocol; in addition to updating
the workflow state (as pertheparent persister Workflow::Persister::DBI),
also updates the workflow context.

=cut

sub update_workflow {
    my ($self, $wf) = @_;

    $self->SUPER::update_workflow( $wf );
    $self->_persist_context( $wf );
}


1;


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

