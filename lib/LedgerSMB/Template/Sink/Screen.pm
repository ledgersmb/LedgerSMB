

package LedgerSMB::Template::Sink::Screen;

=head1 NAME

LedgerSMB::Template::Sink::Screen - Consume templates for rendering as response

=head1 SYNOPSIS

   use LedgerSMB::Template;
   use LedgerSMB::Template::Sink::Screen;

   sub collect {
      my $sink = LedgerSMB::Template::Sink::Screen->new();
      for my $item (@list) {
         my $template = LedgerSMB::Template->new( ... );
         $template->render( ... );
         $sink->append( $template );
      }

      return $sink->render; # return a PSGI response
   }

=head1 DESCRIPTION

This sink collects one or more rendered templates and returns them the result
as a PSGI triplet. Multiple templates are collected into a zip file before
being returned as a response. A single template is returned using the data
from the template.

=cut


use warnings;
use strict;

use Archive::Zip qw(:CONSTANTS :ERROR_CODES);
use HTTP::Status qw(HTTP_OK);

use Moose;
use namespace::autoclean;


=head1 ATTRIBUTES

=head2 archive_name

Name of the file to be returned, in case an archive with multiple templates
has been generated.

=cut

has archive_name => (is => 'ro');

=head2 template

The template associated with the data to return on C<render>. When multiple
templates have been appended, contains the value zero (0).

=cut

has template => (is => 'rw',
                 predicate => 'has_template');

=head2 zip

The zip data to be returned on C<render>, in case an accumulated result is
generated.

=cut

has zip => (is => 'rw',
            predicate => 'has_zip');

=head1 METHODS

=head2 append( $template, filename => $name )

Implements the super class's append

=cut

sub _append_to_zip {
    my ($self, $template, $filename) = @_;

    my $c = $self->zip->numberOfMembers;
    my $m = $self->zip->addString( $template->{output},
                                   sprintf('%02d-%s', $c, $filename) );
    $m->desiredCompressionMethod( COMPRESSION_DEFLATED );
}

sub append {
    my ($self, $template, %args) = @_;

    if ($self->has_template) {
        unless ($self->has_zip) {
            $self->zip(Archive::Zip->new);

            $self->_append_to_zip( $self->template->{template},
                                   $self->template->{filename} );
            $self->template(0);
        }

        $self->_append_to_zip( $template, $args{filename} );
    }
    else {
        $self->template({ template => $template, filename => $args{filename} });
    }
}

=head2 render()

Returns a PSGI triplet containing the state of the sink.

=cut

sub render {
    my ($self) = @_;

    if ($self->has_zip) {
        my $content = '';
        open my $fh, '>', \$content
            or die "Error opening file handle to memory location: $!";
        my $rc = $self->zip->writeToFileHandle($fh);
        close $fh
            or warn "Error closing memory file handle: $!";

        die "Zip file generation error: $rc" if $rc > 1;
        my $filename = $self->archive_name;
        return
            [ HTTP_OK,
              [ 'Content-Type'        => 'application/zip',
                'Content-Disposition' => qq{attachment; filename="$filename"},
              ],
              [ $content ] ];
    }
    else {
        my $filename = $self->template->{filename};
        my $mimetype = $self->template->{template}->{mimetype};
        my $body     = $self->template->{template}->{output};
        utf8::encode($body) if utf8::is_utf8($body); ## no critic
        return
            [ HTTP_OK,
              [ 'Content-Type'        => $mimetype,
                'Content-Disposition' => qq{attachment; filename="$filename"},
              ],
              [ $body ] ];
    }
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2022 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


__PACKAGE__->meta->make_immutable;

1;
