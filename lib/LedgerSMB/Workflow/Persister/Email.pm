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
use Log::Any qw($log);
use List::Util qw(any);

use LedgerSMB::File::Email;
use LedgerSMB::Magic qw(FC_EMAIL);


my $json = JSON::MaybeXS->new(
    utf8 => 0, pretty => 0, indent => 0, convert_blessed => 0,
    allow_bignum => 1, canonical => 0, space_before => 0, space_after => 0
    );


sub _save_email_data {
    my ($self, $wf) = @_;
    my $ctx         = $wf->context;
    my $dbh         = $self->handle;
    my $old_data    = $ctx->param( '_email_data' );
    my $expansions  = $ctx->param( 'expansions' );
    my $data        = {
        expansions  => ( $expansions ? $json->encode( $expansions ) : undef ),
        ( map { $_ => $ctx->param( $_ ) }
          qw(from to cc bcc notify subject body) )
    };

    # Don't save data if the in-memory data hasn't been updated...
    if ( not defined $old_data
         or ( any { ($old_data->{$_} // '') ne ($data->{$_} // '') }
              qw(from to cc bcc notify subject body expansions) ) ) {

        $dbh->do(
            q{
            INSERT INTO email (workflow_id, "from", "to", cc, bcc, "notify",
                               subject, body, expansions)
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
              ON CONFLICT (workflow_id)
                 DO UPDATE SET "from" = $2, "to" = $3, cc = $4, bcc = $5, "notify" = $6,
                        subject = $7, body = $8, expansions = $9
            }, {},
            $wf->id, $data->@{qw(from to cc bcc notify subject body expansions)})
            or $log->error($dbh->errstr);
    }
}


sub _fetch_attachments {
    my ($self, $wf) = @_;

    my $dbh = $self->handle;
    my $sth = $dbh->prepare(
        q{SELECT id, file_name, description,
                 (select mime_type from mime_type
                   where id = mime_type_id) as mime_type
           FROM file_email
           WHERE ref_key = ?}
        ) or die $dbh->errstr;
    $sth->execute( $wf->id )
        or die $sth->errstr;

    my $rows = $sth->fetchall_arrayref( {} );
    $sth->finish;

    $wf->context->param( 'attachments' => $rows);
    for my $row ($rows->@*) {
        $row->{content} = sub {
            my %args = @_;
            return $row->{_content} if $row->{_content};

            my $sth = $dbh->prepare(
                q{select content from file_email where id = ?})
                or die $sth->errstr;
            $sth->execute( $row->{id} )
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


=head2 create_workflow($wf)

Implements Workflow::Persister::DBI protocol; creates a record in the database
and saves e-mail data from the workflow context, if available.

Additionally, saves any attachments given in the C<attachments> context
parameter. If it exists, it is assumed to be an array of hashes to be
passed to the C<attach> method.  On return, the C<attachments> parameter
has been replaced by the content as specified by C<fetch_extra_workflow_data>.

=cut


sub create_workflow {
    my ( $self, $wf ) = @_;

    my $wf_id  = $self->SUPER::create_workflow( $wf );
    $self->_save_email_data( $wf );

    if (my $attachments = $wf->context->param( 'attachments' )) {
        for my $attachment ($attachments->@*) {
            $self->attach( $wf, $attachment );
        }
        $self->_fetch_attachments( $wf );
    }

    return $wf_id;
}

=head2 update_workflow($wf)

Implements Workflow::Persister::DBI protocol; saves the e-mail data fields
when they have changed.

=cut


sub update_workflow {
    my ( $self, $wf ) = @_;

    $self->SUPER::update_workflow( $wf );
    $self->_save_email_data( $wf );
}

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

sub fetch_extra_workflow_data {
    my ($self, $wf) = @_;
    my $ctx = $wf->context;
    $self->SUPER::fetch_extra_workflow_data($wf);
    $self->context->param(
        '_email_data',
        { map { $_ => $ctx->param( $_ ) }
          qw(from to cc bcc notify subject body expansions)
        });
    if ( my $expansions = $ctx->param( 'expansions' ) ) {
        $ctx->param( 'expansions', $json->decode( $expansions ) );
    }

    $self->_fetch_attachments( $wf );
}


=head2 attach($wf, $atts)

Attaches a file to the e-mail. C<$atts> is a hashref with
the following keys in the hash:

=over

=item * content

=item * description

=item * file_name

=item * mime_type

=back

=cut

sub attach {
    my ($self, $wf, $data) = @_;
    my $file               = LedgerSMB::File::Email->new(
        dbh            => $self->handle,
        file_class     => FC_EMAIL,
        ref_key        => $wf->id,
        mime_type_text => $data->{mime_type},
        $data->%{qw( content description file_name )}
        );

    $file->get_mime_type;
    $file->attach;

    return;
}




1;

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

