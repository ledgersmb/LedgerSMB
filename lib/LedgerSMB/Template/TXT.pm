
=head1 NAME

LedgerSMB::Template::TXT - Template support module for LedgerSMB

=head1 METHODS

=over

=item get_extension
Private method to get extension.  Do not call directly.

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

package LedgerSMB::Template::TXT;

use strict;
use warnings;

use Template;
use Template::Parser;
use LedgerSMB::Template::TTI18N;
use DateTime;

# The following are for EDI only
my $dt = DateTime->now;
my $date = sprintf('%04d%02d%02d', $dt->year, $dt->month, $dt->day);
my $time = sprintf('%02d%02d', $dt->hour, $dt->min);

my $binmode = ':utf8';
my $extension = 'txt';

sub get_extension {
    my ($parent) = shift;
    if ($parent->{format_args}->{extension}){
        return $parent->{format_args}->{extension};
    } else {
        return $extension;
    }
}

sub get_template {
    my ($name, $parent) = @_;
    return "${name}.". get_extension($parent);
}

sub preprocess {
    my $rawvars = shift;
    return LedgerSMB::Template::_preprocess($rawvars);
}

sub process {
    my $parent = shift;
    my $cleanvars = shift;
        $cleanvars->{EDI_CURRENT_DATE} = $date;
        $cleanvars->{EDI_CURRENT_TIME} = $time;

    $parent->{binmode} = $binmode;

    my $output = '';
    if ($parent->{outputfile}) {
        if (ref $parent->{outputfile}){
            $output = $parent->{outputfile};
        } else {
            $output = "$parent->{outputfile}.". get_extension($parent);
            $parent->{outputfile} = $output;
        }
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
                \$parent->{output},
                {binmode => $binmode})
    ){
        my $err = $template->error();
        die "Template error: $err" if $err;
    }
    if ($output){
        open my $fh, '>', $output
            or die "Failed to open output file $output : $!";
        print $fh $parent->{output};
        close $fh;
    }
    return $parent->{mimetype} = 'text/plain';
}

sub postprocess {
    my ($parent) = shift;
    if (!$parent->{rendered}){
        return $parent->{template} . '.' . get_extension($parent);
    }
    $parent->{rendered} = "$parent->{outputfile}.". get_extension($parent) if $parent->{outputfile};
    return $parent->{rendered};
}

1;
