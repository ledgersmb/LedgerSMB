
=head1 NAME

LedgerSMB::Template::TXT - Template support module for LedgerSMB

=head1 METHODS

=over

=item get_extension
Private method to get extension.  Do not call directly.

=item process ($parent, $cleanvars)

Processes the template for text.

=item postprocess ($parent)

Returns the output filename.

=item escape ($var)

Implements the templates escaping protocol. Returns C<$var>.

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

sub escape {
    return shift;
}

sub process {
    my ($parent, $cleanvars, $output) = @_;

    $cleanvars->{EDI_CURRENT_DATE} = $date;
    $cleanvars->{EDI_CURRENT_TIME} = $time;

    my $arghash = $parent->get_template_args($extension,$binmode);
    my $template = Template->new($arghash) || die Template->error();
    unless ($template->process(
                $parent->get_template_source(get_extension($parent)),
                {
                    %$cleanvars,
                    %$LedgerSMB::Template::TTI18N::ttfuncs,
                },
                $output,
                {binmode => $binmode})
    ){
        my $err = $template->error();
        die "Template error: $err" if $err;
    }

    return;
}

sub postprocess {
    my $parent = shift;
    $parent->{mimetype} = 'text/plain';
    return;
}

1;
