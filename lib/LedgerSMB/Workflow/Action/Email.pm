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
        $self->send($wf);
    }
    elsif ($self->action eq 'attach') {
        $self->attach($wf);
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
    my $ctx  = $wf->context;
    my $atts = $ctx->param( '_attachments' );

    push $atts->@*, $ctx->delete_param( 'attachment' );
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
        $mail->attach($att->{content},
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

    $ctx->param( 'sent', 1 );
    return;
}


1;

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020-2024 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

