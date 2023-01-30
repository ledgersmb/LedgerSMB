

package LedgerSMB::Template::Sink::Email;

=head1 NAME

LedgerSMB::Template::Sink::Email - Consume templates for sending mail

=head1 SYNOPSIS

   use LedgerSMB::Template;
   use LedgerSMB::Template::Sink::Email;

   sub collect {
      my $sink = LedgerSMB::Template::Sink::Email->new();
      for my $item (@list) {
         my $template = LedgerSMB::Template->new( ... );
         $template->render( ... );
         $sink->append( $template,
                        name    => $name,
                        credit_account => $description,
                        to      => [ qw( one@example.com two@example.com ],
                        cc      => [ qw( manager@example.com ],
                        body    => 'The explanation on why you receive this mail',
                        subject => 'The mail subject...',
             );
      }

      return $sink->render; # return a PSGI response
   }

=head1 DESCRIPTION

This sink collects rendered templates and sends them to the indicated
printer. The C<render> method returns a page indicating the job submission
statusses.

=cut


use warnings;
use strict;

use HTTP::Status qw(HTTP_OK HTTP_SEE_OTHER);
use Workflow::Factory qw(FACTORY);


use LedgerSMB::Template::UI;

use Moose;
use namespace::autoclean;
extends 'LedgerSMB::Template::Sink';

=head1 ATTRIBUTES

=head2 from

=cut

has from => (is => 'ro', required => 1);


=head1 METHODS

=head2 append( $template, to => \@to, cc => \@cc, bcc => \@bcc, subject => $subject, body => $body, filename => $fn )

Implements the super class's append

=cut

sub append {
    my ($self, $template, %args) = @_;

    my $wf  = FACTORY()->create_workflow('Email');
    my $ctx = $wf->context;
    $ctx->param( 'from'    => $self->from );
    $ctx->param( 'to'      => join(', ', $args{to}->@*) );
    $ctx->param( 'cc'      => join(', ', $args{cc}->@*) );
    $ctx->param( 'bcc'     => join(', ', $args{bcc}->@*) );
    $ctx->param( 'body'    => $args{body} );
    $ctx->param( 'subject' => $args{subject} );

    my $content = $template->{output};
    utf8::encode($content) if utf8::is_utf8($content);   ## no critic
    $ctx->param( 'attachment' =>
                 {
                     content     => $content,
                     mime_type   => $template->{mimetype},
                     file_name   => $args{filename},
                 });
    $wf->execute_action( 'attach' );

    return $wf;
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2022 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


__PACKAGE__->meta->make_immutable;

1;
