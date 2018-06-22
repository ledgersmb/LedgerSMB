
package LedgerSMB::Template::LaTeX;

=head1 NAME

LedgerSMB::Template::LaTeX - Template support module for LedgerSMB

=head1 DESCRIPTION

LaTeX rendering support.  Handles PDF, Postscript, and DVI output.

=head1 DETAILS

The final output format is determined by the format_option of filetype.  The
valid filetype specifiers are 'pdf' and 'ps'.

=head1 METHODS

=over

=cut

use warnings;
use strict;

use Template::Plugin::Latex;
use Log::Log4perl;
use TeX::Encode::charmap;
use TeX::Encode;
use charnames ':full';

BEGIN {
    delete $TeX::Encode::charmap::ACCENTED_CHARS{
        "\N{LATIN CAPITAL LETTER A WITH RING ABOVE}"};
    delete $TeX::Encode::charmap::ACCENTED_CHARS{
        "\N{LATIN SMALL LETTER A WITH RING ABOVE}"};
    %TeX::Encode::charmap::CHAR_MAP = (
        %TeX::Encode::charmap::CHARS,
        %TeX::Encode::charmap::ACCENTED_CHARS,
        %TeX::Encode::charmap::GREEK);
    for(keys %TeX::Encode::charmap::MATH)
    {
        $TeX::Encode::charmap::CHAR_MAP{$_} ||= '$' . $TeX::Encode::charmap::MATH{$_} . '$';
    }
    for(keys %TeX::Encode::charmap::MATH_CHARS)
    {
        $TeX::Encode::charmap::CHAR_MAP{$TeX::Encode::charmap::MATH_CHARS{$_}} ||= '$' . $_ . '$';
    }
    $TeX::Encode::charmap::CHAR_MAP_RE = '[' . join('', map { quotemeta($_) } sort { length($b) <=> length($a) } keys %TeX::Encode::charmap::CHAR_MAP) . ']';
}

my $binmode = ':raw';
my $extension = 'tex';

my $logger = Log::Log4perl->get_logger('LedgerSMB::Template::LaTeX');

=item escape($string)

Escapes a scalar string and returns the sanitized version.

=cut

sub escape {
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

=item setup($parent, $cleanvars, $output)

Implements the template's initialization protocol.

=cut

sub setup {
    my ($parent, $cleanvars, $output) = @_;

    $Template::Latex::DEBUG = 1 if $parent->{debug};
    my $format = 'ps';
    if ($parent->{format_options}{filetype} eq 'pdf') {
        $format = 'pdf';
    }
    # The templates use the FORMAT variable to indicate to the LaTeX
    # filter which output type is desired.
    $cleanvars->{FORMAT} = $format;

    return ($output, {
        binmode => ':raw',
        input_extension => $extension,
        _format => $format,
    });
}

=item initialize_template($parent, $config, $template)

Implements the template's engine instance initialization protocol.

Note that this particular module uses this event to register the
Latex plugin.

=cut

sub initialize_template {
    my ($parent, $config, $template) = @_;

    my %options = ( format => $config->{_format} );
    Template::Plugin::Latex->new($template->context, \%options);

    return undef;
}

=item postprocess($parent, $output, $config)

Implements the template's post-processing protocol.

=cut

sub postprocess {
    my ($parent, $output, $config) = @_;
    return undef;
}

=item mimetype()

Returns the rendered template's mimetype.

=cut

sub mimetype {
    my $config = shift;
    my $mimetype;

    if (lc $config->{_format} eq 'pdf') {
        $mimetype = 'application/pdf';
    } else {
        $mimetype = 'application/postscript';
    }

    return $mimetype;
}

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2007-2018 The LedgerSMB Core Team

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
