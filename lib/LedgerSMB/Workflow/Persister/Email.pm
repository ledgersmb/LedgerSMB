package LedgerSMB::Workflow::Persister::Email;

=head1 NAME

LedgerSMB::Workflow::Persister::Email - Attachment metadata

=head1 DESCRIPTION

This module provides e-mail attachment metadata to e-mail workflow.

The class inherits from LedgerSMB::Workflow::Persister::ExtraData; users are
expected to declare the email table and fields as "ExtraData" configuration.

=head1 METHODS

=cut


use warnings;
use strict;
use base qw( LedgerSMB::Workflow::Persister::ExtraData );

use JSON::MaybeXS;

=head2 fetch_extra_workflow_data($wf)

Implements Workflow::Persister::DBI protocol; loads an array of hashrefs
with e-mail attachment data into C<$wf->{attachments}>.

Each hashref contains these keys:

=over

=item id

Row C<id> number of the attachment in the C<file_email> table.

=item file_name

Name of the file as provided on upload.

=item description

Description of the file as provided on upload.

=item mime_type

MIME type as provided or detected on upload.

=item content

coderef to a function which returns the actual attachment content. Takes the
named argument C<disable_cache> to prevent caching the content in-memory:

  $mail->attach( $att->{content}->(disable_cache => 1) );

=back

=cut

my $json = JSON::MaybeXS->new( utf8 => 0 );

sub fetch_extra_workflow_data {
    my ($self, $wf) = @_;
    $self->SUPER::fetch_extra_workflow_data($wf);
    if ( my $expansions = $wf->context->param( 'expansions' ) ) {
        $wf->context->param( 'expansions', $json->decode( $expansions ) );
    }

    my $dbh = $self->handle;
    my $sth = $dbh->prepare(
        q{SELECT id, file_name, description,
                 (select mime_type from mime_type
                   where id = mime_type_id) as mime_type
           FROM file_email
           WHERE ref_key = ?}
        ) or die $dbh->errstr;
    $sth->execute($wf->id)
        or die $sth->errstr;

    my $rows = $sth->fetchall_arrayref({});
    $sth->finish;

    $wf->context->param( 'attachments' => $rows);
    for my $row ($rows->@*) {
        $row->{content} = sub {
            my %args = @_;
            return $row->{_content} if $row->{_content};

            my $sth = $dbh->prepare(
                q{select content from file_email where id = ?})
                or die $sth->errstr;
            $sth->execute($row->{id})
                or die $sth->errstr;
            ($row->{_content}) = $sth->fetchrow_array();
            if (not defined $row->{_content} and $sth->err) {
                die $sth->errstr;
            }
            $sth->finish;

            return $args{disable_cache} ?
                delete $row->{_content} : $row->{_content};
        };
    }
}


1;

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

