
=head1 NAME

LedgerSMB::Template::LaTeX - Template support module for LedgerSMB

=head1 SYNOPSIS

Muxed LaTeX rendering support.  Handles PDF, Postscript, and DVI output.

=head1 DETAILS

The final output format is determined by the format_option of filetype.  The
valid filetype specifiers are 'pdf' and 'ps'.

=head1 METHODS

=over

=item get_template ($name)

Returns the appropriate template filename for this format.

=item preprocess ($vars)

Currently does nothing.

=item process ($parent, $cleanvars)

Processes the template for the appropriate output format.

=item postprocess ($parent)

Currently does nothing.

=item escape($string)

Escapes a scalar string and returns the sanitized version.

=back

=head1 Copyright (C) 2007, The LedgerSMB core team.

This work contains copyrighted information from a number of sources all used
with permission.

It is released under the GNU General Public License Version 2 or, at your
option, any later version.  See COPYRIGHT file for details.  For a full list
including contact information of contributors, maintainers, and copyright
holders, see the CONTRIBUTORS file.
=cut

package LedgerSMB::Template::LaTeX;

use warnings;
use strict;

use Template::Latex;
use Template::Parser;
use LedgerSMB::Template::TTI18N;
use LedgerSMB::Magic qw( UNI_aring UNI_Aring );
use Log::Log4perl;
use TeX::Encode::charmap;
use TeX::Encode;

BEGIN {
    delete $TeX::Encode::charmap::ACCENTED_CHARS{chr(UNI_Aring)};
    delete $TeX::Encode::charmap::ACCENTED_CHARS{chr(UNI_aring)};
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

sub get_template {
    my $name = shift;
    return "${name}.$extension";
}

sub preprocess {
    my $rawvars = shift;
    return LedgerSMB::Template::_preprocess($rawvars, \&escape);
}

# Breaking this off to be used separately.
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

sub process {
    my $parent = shift;
    my $cleanvars = shift;

    $parent->{outputfile} ||=
        "${LedgerSMB::Sysconfig::tempdir}/$parent->{template}-output-$$";

    my $format = 'ps';
    if ($parent->{format_args}{filetype} eq 'pdf') {
        $format = 'pdf';
    }
    my $arghash = $parent->get_template_args($extension,$binmode);
    my $output = "$parent->{outputfile}";
    $output =~ s/$extension/$format/;
    $arghash->{LATEX_FORMAT} = $format;

    $Template::Latex::DEBUG = 1 if $parent->{debug};
    my $template = Template::Latex->new($arghash) || die Template::Latex->error();
    unless ($template->process(
                $parent->get_template_source(\&get_template),
                {
                    %$cleanvars,
                    %$LedgerSMB::Template::TTI18N::ttfuncs,
                    FORMAT => $format,
                    'escape' => \&preprocess
                },
                $output,
                {binmode => 1})
    ){
        my $err = $template->error();
        die "Template error: $err" if $err;
    }
    if (lc $format eq 'pdf') {
        $parent->{mimetype} = 'application/pdf';
    } else {
        $parent->{mimetype} = 'application/postscript';
    }
    return $parent->{rendered} = "$parent->{outputfile}.$format";
}

sub postprocess {
    my $parent = shift;
    return $parent->{rendered};
}

1;
