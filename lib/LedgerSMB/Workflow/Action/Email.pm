package LedgerSMB::Workflow::Action::Email;

=head1 NAME

LedgerSMB::Workflow::Action::Email - Workflow Actions for e-mail workflows

=head1 SYNOPSIS

  # action configuration
  <actions>
    <action name="Send" class="LedgerSMB::Workflow::Action::Email" action="send"
            order="1" />
  </actions>


=head1 DESCRIPTION

This module implements the actions for managing e-mail workflows: Attach, Save
and Send. It uses the generic C<execute> entry point as per the protocol of
C<Workflow::Actoin> and dispatches internally based on the C<action>
configuration attribute.

This set of actions operates on the following keys in the workflow context:

=over

=item * from

=item * to

=item * cc

=item * bcc

=item * subject

=item * body

=item * attachments

=item * notify

=item * expansions

=back


=head1 METHODS

=cut


use strict;
use warnings;
use parent qw( LedgerSMB::Workflow::Action );

use Email::MessageID;
use Email::Sender::Simple;
use Email::Stuffer;

use Log::Any qw($log);
use Workflow::Factory qw(FACTORY);


my @PROPS = qw( action );
__PACKAGE__->mk_accessors(@PROPS);

=head2 init($wf, $params)

Implements the C<Workflow::Action> protocol.

=cut

sub init {
    my ($self, $wf, $params) = @_;
    $self->SUPER::init($wf, $params);

    $self->action( $params->{action} );
}

=head2 execute($wf)

Implements the C<Workflow::Action> protocol.

Dispatches based on the C<action> attribute:

  attribute      method
   send           send
   attach         attach
   save           save
   queue          save

=cut

sub execute {
    my ($self, $wf) = @_;

    $log->info('Action name: ', $self->action);
    if ($self->action eq 'send') {
        $self->save($wf);
        $self->send($wf);
    }
    elsif ($self->action eq 'attach') {
        $self->save($wf);
        $self->attach($wf);
    }
    elsif ($self->action eq 'save'
           or $self->action eq 'queue') {
        $self->save($wf);
    }
    elsif ($self->action eq 'initial-save') {
        $self->initial_save($wf);
    }
    elsif ($self->action eq 'expand') {
        $self->expand($wf);
    }
    return;
}

=head2 attach($wf)

Attaches a file to the e-mail. Takes its data from the
C<attachment> key in the context. It should be a hash with these
keys:

=over

=item content

=item description

=item file_name

=item mime_type

=back

@@TODO: attachment removal!

=cut

sub attach {
    my ($self, $wf) = @_;
    my $persister   = FACTORY()->get_persister( $wf->type );
    my $att         = $wf->context->delete_param( 'attachment' );

    $persister->attach( $wf, $att );
    $persister->fetch_extra_workflow_data( $wf );
    return;
}


=head2 expand($wf)

Expands variables in the message content of the e-mail. Takes its data from the
C<expansions> key in the context.

=cut

sub expand {
    my ($self, $wf) = @_;

    my $body       = $wf->context->param( 'body' );
    my $expansions = $wf->context->param( 'expansions' );

    if ( $body and $expansions ) {
        $body =~ s/<%(.+?)%>/$expansions->{$1}/g;

        $wf->context->param( 'body', $body );
        $self->save($wf)
    }

    return;
}


=head2 send($wf)

Sends e-mail based on the workflow context data. Retrieves attachments
from the database.

This step requires valid content for at least C<from>, C<to>, C<subject>.

Uses e-mail transfer configuration from the context.

=cut

sub send {
    my ($self, $wf) = @_;

    my $dbh = $self->_factory->
        get_persister_for_workflow_type($wf->type)->handle;
    $dbh->do(q{UPDATE email SET sent_date = NOW() WHERE workflow_id = ?},
             {}, $wf->id)
        or $log->error($dbh->errstr);


    my $ctx  = $wf->context;
    my $mail = Email::Stuffer
        ->from(      $ctx->param( 'from' ) )
        ->to(        $ctx->param( 'to' ) )
        ->subject(   $ctx->param( 'subject' ) )
        ->text_body( $ctx->param( 'body' ),
                     encoding     => '8bit',
                     content_type => 'text/plain',
                     charset      => 'utf8' )
        ->header( 'Message-Id' => Email::MessageID->new->in_brackets );

    $mail->cc( $ctx->param( 'cc' ) ) if $ctx->param( 'cc' );
    if ($ctx->param( 'notify' )) {
        $mail->header( 'Disposition-Notification-To' => $ctx->param( 'from' ) );
    }

    for my $att ( ($ctx->param( '_attachments' ) // [])->@* ) {
        $mail->attach($wf->attachment_content($att->{id}, disable_cache => 1),
                      content_type => $att->{mime_type},
                      disposition  => 'attachment',
                      filename     => $att->{file_name});
    }

    local $@ = undef;
    eval {
        # On failure, send() throws an exception
        if ( my $bcc = $ctx->param( 'bcc' ) ) {
            # Split $bcc into separate addresses and de-duplicate them
            my %bcc = map { $_ => 1 } split /\s*,\s*/, $bcc;
            Email::Sender::Simple->send(
                $mail->email,
                {
                    to => [ keys %bcc ],
                    transport => $ctx->param( '_transport' ),
                });
        }
        Email::Sender::Simple->send(
            $mail->email,
            {
                transport => $ctx->param( '_transport' ),
            });
    };
    die "Could not send email: $@.  Please check your configuration." if $@;

    return;
}

=head2 save($wf)

Stores the e-mail data from the workflow context, except C<attachments>.
To create attachments, use the C<attach> workflow item.

All fields in the e-mail are optional for this step.

=cut

sub save {
    my ($self, $wf) = @_;
    # Saving is built into the persister and happens automatically
    # after each successful action; no additional code required
}


=head2 initial_save($wf)

Stores the e-mail data from the workflow context, including C<attachments>.

This step should be used to store e-mail data passed into the workflow on
workflow creation.

=cut

sub initial_save {
    my ($self, $wf) = @_;

    my $persister   = FACTORY()->get_persister( $wf->type );
    my $atts        = $wf->context->delete_param( '_attachments' );

    for my $att ( $atts->@* ) {
        $persister->attach( $wf, $att );
    }
    $persister->fetch_extra_workflow_data( $wf );

    # Saving is built into the persister and happens automatically
    # after each successful action; no additional code required
}


1;

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020-2022 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

