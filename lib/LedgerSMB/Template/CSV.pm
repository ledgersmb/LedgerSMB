
=head1 NAME

LedgerSMB::Template::CSV - Template support module for LedgerSMB

=head1 METHODS

=over

=item get_template ($name)

Returns the appropriate template filename for this format.

=item preprocess ($vars)

Returns $vars.

=item process ($parent, $cleanvars)

Processes the template for text.

=item postprocess ($parent)

Returns the output filename.

=back

=head1 Copyright (C) 2007, The LedgerSMB core team.

This work contains copyrighted information from a number of sources all used
with permission.

It is released under the GNU General Public License Version 2 or, at your
option, any later version.  See COPYRIGHT file for details.  For a full list
including contact information of contributors, maintainers, and copyright
holders, see the CONTRIBUTORS file.
=cut

package LedgerSMB::Template::CSV;

use warnings;
use strict;

use Template;
use Template::Parser;
use LedgerSMB::Template::TTI18N;

my $binmode = ':utf8';
my $extension = 'csv';

sub get_template {
    my $name = shift;
    return "${name}.$extension";
}

sub preprocess {
    my $rawvars = shift;
    return LedgerSMB::Template::_preprocess($rawvars);
}

sub process {
    my $parent = shift;
    my $cleanvars = shift;

    $parent->{binmode} = $binmode;

    my $output = '';
    if ($parent->{outputfile}) {
        if (ref $parent->{outputfile}){
            $output = $parent->{outputfile};
        } else {
            $output = "$parent->{outputfile}.$extension";
        }
    } else {
        $output = \$parent->{output};
    }
    my $arghash = $parent->get_template_args($extension,$binmode);
    my $template = Template->new($arghash) || die Template->error();
    unless ($template->process(
                $parent->get_template_source(\&get_template),
                {
                    %$cleanvars,
                    %$LedgerSMB::Template::TTI18N::ttfuncs,
                    'escape' => \&preprocess
                },
                $output,
                {binmode => $binmode})
    ){
        my $err = $template->error();
        die "Template error: $err" if $err;
    }
    return $parent->{mimetype} = 'text/' . $extension;
}

sub postprocess {
    my $parent = shift;
    $parent->{rendered} = "$parent->{outputfile}.$extension" if $parent->{outputfile};
    if (!$parent->{rendered}){
        return "$parent->{template}.$extension";
    }
    return $parent->{rendered};
}

1;
