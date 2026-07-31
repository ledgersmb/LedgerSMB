
use v5.38;

package LedgerSMB::Workflow::Persister;

=head1 NAME

LedgerSMB::Workflow::Persister - Store workflow data in a LedgerSMB company

=head1 SYNOPSIS

  <persisters>
    <persister class="LedgerSMB::Workflow::Persister"
               driver="Pg" />
    </persister>
  </persisters>

=head1 DESCRIPTION

This module handles persistence of workflow (history) data through the
existing database connection in C<<$app->dbh>>. Workflow state, context
and history are all written using the existing database connection.

The class inherits from Workflow::Persister and uses
the same configuration semantics, but modifies the protocol of
the persister to include a C<$app> parameter on C<create_workflow>
and C<fetch_workflow>. This parameter provides access to the existing
C<$dbh> database handle. The C<<$wf->app>> field is set to the value
of this parameter too: it is used by actions and conditions to access
the active database handle as well as the global configuration via
C<$app->wire>. All other methods take advantage of the C<app> field
in the workflow object.


=head1 METHODS

=cut

use parent qw( Workflow::Persister );

use DateTime;
use DateTime::Format::Strptime;
use JSON::MaybeXS;
use Log::Any qw($log);

my $json = JSON::MaybeXS->new(
    pretty => 0, indent => 0, convert_blessed => 0,
    allow_bignum => 1, utf8 => 0, space_before => 0,
    space_after => 0, canonical => 0, allow_barekey => 0,
    allow_singlequote => 0 );

my $parser = DateTime::Format::Strptime->new( pattern => '%Y-%m-%d %H:%M:%S' );


sub _persist_context($self, $dbh, $wf) {
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

=head2 create_workflow( $app, $wf )

Implements Workflow::Persister protocol; in addition to initializing
the workflow state (as pertheparent persister Workflow::Persister::DBI),
also persists the workflow context.

=cut


sub create_workflow($self, $app, $wf) {
    my $dbh = $app->dbh;

    my $query = <<~'SQL';
      INSERT INTO workflow (workflow_id, type, state, last_update)
         VALUES (nextval('workflow_seq'), ?, ?, ?)
      RETURNING workflow_id
      SQL

    my $now = $parser->format_datetime( DateTime->now( time_zone => 'UTC' ) );
    my $rows = $dbh->selectall_arrayref(
        $query, {},
        $wf->type, $wf->state, $now)
        or die $dbh->errstr;
    my $wf_id = $rows->[0]->[0]; # first column first row

    $wf->{id} = $wf_id;
    $self->_persist_context( $dbh, $wf );

    return $wf_id;
}

=head2 fetch_workflow( $app, $wf_id )

Implements Workflow::Persister protocol; in addition to restoring the
workflow state (as per the parent persister Workflow::Persister::DBI),
also restores the workflow context.

=cut


sub fetch_workflow($self, $app, $wf_id) {
    my $dbh   = $app->dbh;
    my $query = <<~'SQL';
       SELECT state, last_update FROM workflow WHERE workflow_id = ?
       SQL
    my $row = $dbh->selectrow_arrayref( $query, {}, $wf_id );
    die $dbh->errstr if $dbh->err;

    my $time = $parser->parse_datetime( $row->[1] );
    my $wf_info = {
        'state' => $row->[0],
        'last_update' => $time
    };

    my $sth = $dbh->prepare(
        q{SELECT * FROM workflow_context WHERE workflow_id = ?}
        )
        or die $dbh->errstr;

    $sth->execute( $wf_id )
        or die $sth->errstr;
    if (my $row = $sth->fetchrow_hashref( 'NAME_lc' )) {
        $wf_info->{context} = {
            ($wf_info->{context} // {})->%*,
                $json->decode( $row->{context} )->%*
        };
    }
    else {
        $sth->err and die $sth->errstr;
    }

    return $wf_info;
}


=head2 update_workflow( $wf )

Implements Workflow::Persister protocol; in addition to updating
the workflow state (as pertheparent persister Workflow::Persister::DBI),
also updates the workflow context.

=cut

sub update_workflow {
    my ($self, $wf) = @_;

    my $now = $parser->format_datetime( DateTime->now( time_zone => 'UTC' ) );
    my $query = <<~'SQL';
       UPDATE workflow SET state = ?, last_update = ? WHERE workflow_id = ?
       SQL
    my $dbh = $wf->app->dbh;
    $dbh->do( $query, {},
              $wf->state, $now, $wf->id )
        or die $dbh->errstr;

    $self->_persist_context( $dbh, $wf );
}

=head2 create_history( $app, $wf, @history )

Implements Workflow::Persister protocol; in addition to updating
the workflow state (as pertheparent persister Workflow::Persister::DBI),
also updates the workflow context.

=cut

sub create_history($self, $wf, @history) {
    my $dbh = $wf->app->dbh;
    my $query = <<~'SQL';
       INSERT INTO workflow_history (workflow_hist_id, workflow_id, action, description, state, workflow_user, history_date)
              VALUES (nextval('workflow_history_seq'), ?, ?, ?, ?, ?, ?)
       RETURNING workflow_hist_id
       SQL
    my $sth = $dbh->prepare( $query )
        or die $dbh->errstr;

    for my $h (@history) {
        my $timestamp = $parser->format_datetime($h->date);
        $sth->execute( $wf->id, $h->action, $h->description, $h->state, $h->user,
                       $timestamp )
            or die $sth->errstr;

        my ($id) = $sth->fetchrow_array;
        die $sth->errstr if $sth->err;

        $h->{id} = $id;
        $h->set_saved;
    }
    return @history;
}

=head2 fetch_history( $wf, @history )

Implements Workflow::Persister protocol; in addition to updating
the workflow state (as pertheparent persister Workflow::Persister::DBI),
also updates the workflow context.

=cut

sub fetch_history($self, $wf) {
    my $dbh = $wf->app->dbh;
    my $query = <<~'SQL';
       SELECT workflow_hist_id as id, workflow_id, action, description, state, user, history_date as date FROM workflow_history WHERE workflow_id = ?
       SQL

    my $rows = $dbh->selectall_arrayref( $query, { Slice => {} }, $wf->id )
        or die $dbh->errstr;

    my @history = map {
            $_->{date} = $parser->parse_datetime( $_->{date} );
            $_;
    } $rows->@*;

    return @history;
}



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020-2026 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

