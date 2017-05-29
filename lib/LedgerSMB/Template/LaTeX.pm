
=head1 NAME

LedgerSMB::Template::LaTeX - Template support module for LedgerSMB

=head1 SYNOPSIS

Muxed LaTeX rendering support.  Handles PDF, Postscript, and DVI output.

=head1 DETAILS

The final output format is determined by the format_option of filetype.  The
valid filetype specifiers are 'pdf' and 'ps'.

=head1 METHODS

=over

=item process()

temporary item

=cut

package LedgerSMB::Template::LaTeX;

use warnings;
use strict;

use Template::Plugin::Latex;
use Log::Log4perl;
use TeX::Encode::charmap;
use TeX::Encode;

BEGIN {
    delete $TeX::Encode::charmap::ACCENTED_CHARS{chr(0x00c5)};
    delete $TeX::Encode::charmap::ACCENTED_CHARS{chr(0x00e5)};
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
    if ($parent->{format_args}{filetype} eq 'pdf') {
        $format = 'pdf';
    }
    # The templates use the FORMAT variable to indicate to the LaTeX
    # filter which output type is desired.
    $cleanvars->{FORMAT} = $format;

    return ($output, {
        binmode => 1,
        input_extension => $extension,
        _format => $format,
    });
}

sub process {
    my ($parent, $cleanvars, $output) = @_;

    my $format = 'ps';
    if ($parent->{format_args}{filetype} eq 'pdf') {
        $format = 'pdf';
    }
    my $arghash = $parent->get_template_args($extension,$binmode);
    my $template = Template->new($arghash)
        || die Template->error();

    my %options = ( FORMAT => $format );
    Template::Plugin::Latex->new($template->context, \%options);

    unless ($template->process(
                $parent->get_template_source($extension),
                %$cleanvars,
                $output,
                {binmode => 1})
    ){
        my $err = $template->error();
        die "Template error: $err" if $err;
    }
    return;
}

=item postprocess($parent, $output, $config)

Implements the template's post-processing protocol.

=cut

sub postprocess {
    my ($parent, $output, $config) = @_;

    if (lc $format eq 'pdf') {
        $parent->{mimetype} = 'application/pdf';
    } else {
        $parent->{mimetype} = 'application/postscript';
    }
    return;
}

=back

=head1 Copyright (C) 2007-2017, The LedgerSMB core team.

This work contains copyrighted information from a number of sources all used
with permission.

It is released under the GNU General Public License Version 2 or, at your
option, any later version.  See COPYRIGHT file for details.  For a full list
including contact information of contributors, maintainers, and copyright
holders, see the CONTRIBUTORS file.

=cut


1;
