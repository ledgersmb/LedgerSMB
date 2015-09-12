
=head1 NAME

LedgerSMB::Template::LaTeX - Template support module for LedgerSMB

=head1 SYNOPSIS

Muxed LaTeX rendering support.  Handles PDF, Postscript, and DVI output.

=head1 DETAILS

The final output format is determined by the format_option of filetype.  The
valid filetype specifiers are 'pdf', 'ps', and 'dvi'.

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
use LedgerSMB::Template::TTI18N;
use Log::Log4perl;
use LedgerSMB::Template::DB;
use TeX::Encode;

#my $binmode = ':utf8';
my $binmode = ':raw';
binmode STDOUT, $binmode;
binmode STDERR, $binmode;

my $logger = Log::Log4perl->get_logger('LedgerSMB::Template::LaTeX');

sub get_template {
    my $name = shift;
    return "${name}.tex";
}

sub preprocess {
    my $rawvars = shift;
    my $vars;
   { # pre-5.14 compatibility block
       local ($@); # pre-5.14, do not die() in this block
       if (eval {$rawvars->can('to_output')}){
           $rawvars = $rawvars->to_output;
       }
   }
    my $type = ref $rawvars;

    return $rawvars if $type =~ /^LedgerSMB::Locale/;
    return unless defined $type;
    if ($type eq 'ARRAY') {
        for (@{$rawvars}) {
            push @{$vars}, preprocess($_);
        }
    } elsif (!$type or $type eq 'SCALAR' or $type eq 'Math::BigInt::GMP'
        or $type eq 'CODE'
    ) {
        if ($type eq 'SCALAR' or $type eq 'Math::BigInt::GMP') {
            $vars = $$rawvars;
        } else {
            $vars = $rawvars;
        }
        #XXX Fix escaping
        $vars = escape($vars) unless $type eq 'CODE';
    } else {
        for ( keys %{$rawvars} ) {
            $vars->{$_} = preprocess($rawvars->{$_});
        }
    }
    return $vars;
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
    my $template;
    my $source;
    $parent->{outputfile} ||=
        "${LedgerSMB::Sysconfig::tempdir}/$parent->{template}-output-$$";

        $parent->{binmode} = $binmode;
        if ($parent->{include_path} eq 'DB'){
                $source = LedgerSMB::Template::DB->get_template(
                       $parent->{template}, undef, 'tex'
                );
    } elsif (ref $parent->{template} eq 'SCALAR') {
        $source = $parent->{template};
    } elsif (ref $parent->{template} eq 'ARRAY') {
        $source = join "\n", @{$parent->{template}};
    } else {
        $source = get_template($parent->{template});
    }
    $Template::Latex::DEBUG = 1 if $parent->{debug};
    my $format = 'ps';
    if ($parent->{format_args}{filetype} eq 'dvi') {
        $format = 'dvi';
    } elsif ($parent->{format_args}{filetype} eq 'pdf') {
        $format = 'pdf';
    }
    $template = Template::Latex->new({
        LATEX_FORMAT => $format,
        INCLUDE_PATH => [$parent->{include_path_lang}, $parent->{include_path},'templates/demo','UI/lib'],
        START_TAG => quotemeta('<?lsmb'),
        END_TAG => quotemeta('?>'),
        DELIMITER => ';',
                ENCODING => 'utf8',
        DEBUG => ($parent->{debug})? 'dirs': undef,
        DEBUG_FORMAT => '',
        }) || die Template::Latex->error();
        my $out = "$parent->{outputfile}.$format" unless ref $parent->{outputfile};
        $out ||= $parent->{outputfile};
    if (not $template->process(
        $source,
        {%$cleanvars, %$LedgerSMB::Template::TTI18N::ttfuncs,
            'escape' => \&preprocess},
        $out, {binmode => 1})) {
        die $template->error();
    }
    if (lc $format eq 'dvi') {
        $parent->{mimetype} = 'application/x-dvi';
    } elsif (lc $format eq 'pdf') {
        $parent->{mimetype} = 'application/pdf';
    } else {
        $parent->{mimetype} = 'application/postscript';
    }
    $parent->{rendered} = "$parent->{outputfile}.$format";
}

sub postprocess {
    my $parent = shift;
    return $parent->{rendered};
}

1;
