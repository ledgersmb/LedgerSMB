
package LedgerSMB::Template::Plugin::LaTeX;

=head1 NAME

LedgerSMB::Template::Plugin::LaTeX - Template support module for LedgerSMB

=head1 DESCRIPTION

LaTeX rendering support.  Handles PDF, Postscript, and DVI output.

=head1 DETAILS

The final output format is determined by the format_option of filetype.  The
valid filetype specifiers are 'pdf' and 'ps'.

=cut

use warnings;
use strict;
use charnames ':full';

use Log::Any;
use Template::Latex;
use Template::Plugin::Latex;
use TeX::Encode::charmap;
use TeX::Encode;

use Moo;


my $binmode = ':raw';
my $extension = 'tex';

my $logger = Log::Any->get_logger(category => 'LedgerSMB::Template::LaTeX');


=head1 ATTRIBUTES

=head2 formats

Holds an array of strings naming the formats supported by this plugin.

=cut

has formats => (is => 'ro', default => sub { [ 'PS', 'PDF' ] });

=head2 format

Holds a string naming the actual format for which this plugin
is configured. The plugin can be used multiple times with different
formats, as long as they are in the list of formats.

=cut

has format => (is => 'ro', required => 1);

=head2 processor

The value of this field is passed to the template in the PROCESSOR
variable, which can be used to select between C<pdflatex> and
C<xelatex> processing engines.

=cut

has processor => (is => 'ro', default => 'pdflatex');

=head1 METHODS

=head2 escape($string)

Escapes a scalar string and returns the sanitized version.

=cut

sub escape {
    my $self = shift;
    my ($vars) = shift @_;
    return '' unless defined $vars;

    $vars =~ s/-/......hyphen....../g;
    $vars =~ s/\+/......plus....../g;
    $vars =~ s/@/......amp....../g;
    $vars =~ s/!/......exclaim....../g;

    # For some reason this doesnt handle hyphens or +'s, so handling those
    # above and below -CT
    $vars = TeX::Encode::encode('latex', $vars);
    if (defined $vars){ # Newline handling
            $vars =~ s/\n/\\\\/gm;
            $vars =~ s/(\\)*$//g;
            $vars =~ s/(\\\\){2,}/\n\n/g;
    }
    $vars =~ s/\.\.\.\.\.\.hyphen\.\.\.\.\.\./-/g;
    $vars =~ s/\.\.\.\.\.\.plus\.\.\.\.\.\./+/g;
    $vars =~ s/\.\.\.\.\.\.amp\.\.\.\.\.\./@/g;
    $vars =~ s/\.\.\.\.\.\.exclaim\.\.\.\.\.\./!/g;
    return $vars;
}

=head2 setup($parent, $cleanvars, $output)

Implements the template's initialization protocol.

=cut

sub setup {
    my ($self, $parent, $cleanvars, $output) = @_;

    $Template::Latex::DEBUG = 1 if $parent->{debug};
    # The templates use the FORMAT variable to indicate to the LaTeX
    # filter which output type is desired.
    $cleanvars->{FORMAT} = lc $self->format;
    $cleanvars->{PROCESSOR} = lc $self->processor;

    return ($output, {
        binmode         => ':raw',
        input_extension => $extension,
        _format         => lc $self->format,
    });
}

=head2 initialize_template($parent, $config, $template)

Implements the template's engine instance initialization protocol.

Note that this particular module uses this event to register the
Latex plugin.

=cut

sub initialize_template {
    my ($self, $parent, $config, $template) = @_;

    my %options = ( format => $config->{_format} );
    Template::Plugin::Latex->new($template->context, \%options);

    return undef;
}

=head2 postprocess($parent, $output, $config)

Implements the template's post-processing protocol.

=cut

sub postprocess {
    my ($self, $parent, $output, $config) = @_;
    return undef;
}

=head2 mimetype()

Returns the rendered template's mimetype.

=cut

sub mimetype {
    my $self = shift;
    my $config = shift;
    my $mimetype;

    if (lc $self->format eq 'pdf') {
        $mimetype = 'application/pdf';
    } else {
        $mimetype = 'application/postscript';
    }

    return $mimetype;
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2007-2022 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
