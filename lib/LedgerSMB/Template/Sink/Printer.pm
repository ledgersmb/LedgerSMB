

package LedgerSMB::Template::Sink::Printer;

=head1 NAME

LedgerSMB::Template::Sink::Printer - Consume templates for printing

=head1 SYNOPSIS

   use LedgerSMB::Template;
   use LedgerSMB::Template::Sink::Printer;

   sub collect {
      my $sink = LedgerSMB::Template::Sink::Print->new( printer => 'Print1' );
      for my $item (@list) {
         my $template = LedgerSMB::Template->new( ... );
         $template->render( ... );
         $sink->append( $template );
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

use HTTP::Status qw(HTTP_OK);

use Moose;
use namespace::autoclean;


=head1 ATTRIBUTES

=head2 command

Command to execute and send the output to.

=cut

has command => (is => 'ro');

=head2 _results

(Internal) Collects the submission results.

=cut

has _results => (is => 'ro', default => sub { [] });


=head1 METHODS

=head2 append( $template )

Implements the super class's append

=cut

sub append {
    my ($self, $template) = @_;

    my $cmd = $self->command;
    unless (defined $cmd) {
        push $self->_results->@*, {
            msg    => 'No printer configured for ' . $self->printer,
            status => 'fail',
        };
        return;
    }
    open my $pipe, '|-', $cmd
        or die "Unable to create printer output pipe ($cmd): $!";
    print $pipe $template->{output}
        or die "Unable to print template output to $cmd: $!";
    close $pipe
        or warn "Unable to close printer pipe $cmd: $!";
    push $self->_results->@*, {
        msg   => 'Successfully submitted',
        status => 'success'
    };
}

=head2 render()

Returns a PSGI triplet containing the state of the sink.

=cut

sub render {
    my ($self) = @_;

    my $count = scalar($self->_results->@*);
    my $success = scalar(grep { $_->{status} eq 'success' } $self->_results->@*);
    my $fail = scalar(grep { $_->{status} eq 'fail' } $self->_results->@*);
    return
        [ HTTP_OK,
          [ 'Content-Type'        => 'text/html; charset=UTF-8', ],
          [ '<html><body>',
            '<h1>Done</h1>',
            "<p>Submitted $count jobs (success: $success; fail: $fail)",
            '</body></html>' ] ];
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2022 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


__PACKAGE__->meta->make_immutable;

1;
