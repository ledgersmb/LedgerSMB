package LedgerSMB::Workflow::Email;

=head1 NAME

LedgerSMB::Workflow::Email - Class for e-mail sending state machines

=head1 SYNOPSIS

  <workflow class="LedgerSMB::Workflow::Email">
    ...
  </workflow>

=head1 DESCRIPTION

This module handles persistence of workflow (history) data through the
existing database connection in C<LedgerSMB::App_State::DBH()>.

The class inherits from Workflow::Persister::DBI and uses
the same configuration semantics.

=head1 METHODS

=cut

use warnings;
use strict;
use base qw( Workflow );

=head2 attachment_content( $id, disable_cache => $boolean )

Returns the content of an attachment to an e-mail, *if* the attachment
with C<$id> belongs to the Email workflow.

The C<disable_cache> parameter determines whether or not the content
will be cached in the workflow for later retrieval, or that future calls
will retrieve the content from the database again.

=cut

sub attachment_content {
    my ($self, $id, %args) = @_;

    return $self->{_content}->{$id} if $self->{_content}->{$id};

    my $persister = $self->_factory->get_persister( $self->type );
    my $dbh       = $persister->handle;
    my $sth       = $dbh->prepare(
        q{select content from file_email where ref_key = ? and id = ?})
        or die $dbh->errstr;
    $sth->execute( $self->id, $id )
        or die $sth->errstr;
    ($self->{_content}->{$id}) = $sth->fetchrow_array();
    if (not defined $self->{_content}->{$id} and $sth->err) {
        die $sth->errstr;
    }
    $sth->finish;

    return $args{disable_cache} ?
        delete $self->{_content}->{$id} : $self->{_content}->{$id};
}



1;


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2022 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

