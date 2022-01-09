

package LedgerSMB::Template::Sink;

=head1 NAME

LedgerSMB::Template::Sink - Consume templates for output rendering

=head1 SYNOPSIS

   use LedgerSMB::Template;
   use LedgerSMB::Template::Sink;

   sub collect {
      my $sink = LedgerSMB::Template::Sink->new();
      for my $item (@list) {
         my $template = LedgerSMB::Template->new( ... );
         $template->render( ... );
         $sink->append( $template );
      }

      return $sink->render; # return a PSGI response
   }

=head1 DESCRIPTION

This is an abstract superclass which defines the C<Sink> protocol. Instances
should be a subtype of this class; current implementations include:

=over

=item L<LedgerSMB::Template::Sink::Email>

=item L<LedgerSMB::Template::Sink::Printer>

=item L<LedgerSMB::Template::Sink::Screen>

=back

See the documentation of these implementations for more information.

=cut


use warnings;
use strict;

use HTTP::Status qw(HTTP_NOT_IMPLEMENTED);

use Moose;
use namespace::autoclean;


=head1 ATTRIBUTES

This class has no attributes.

=head1 METHODS

=head2 append( $template, %arguments )

Makes the sink consume an evaluated C<$template>. Additional arguments
may be provided using named arguments. See the specification of the
specific subclass for details on supported and required additional
arguments.

Returns a L<Workflow> instance if one has been created, or C<undef>
otherwise.

=cut

sub append { }

=head2 render()

Returns a PSGI triplet containing the cumulated state of the sink,
if it can be represented as such, or C<undef> if not. An example of such
accumulated state to be returned as PSGI triplet, is the collection of
templates into a ZIP file, where the ZIP is the return value.

=cut

sub render {
    return undef;
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2022 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


__PACKAGE__->meta->make_immutable;

1;
