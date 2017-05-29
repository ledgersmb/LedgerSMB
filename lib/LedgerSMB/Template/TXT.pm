
=head1 NAME

LedgerSMB::Template::TXT - Template support module for LedgerSMB

=head1 METHODS

=over

=item process()

temporary item

=cut

package LedgerSMB::Template::TXT;

use strict;
use warnings;

use Template;
use DateTime;

# The following are for EDI only
my $dt = DateTime->now;
my $date = sprintf('%04d%02d%02d', $dt->year, $dt->month, $dt->day);
my $time = sprintf('%02d%02d', $dt->hour, $dt->min);

my $binmode = ':utf8';
my $extension = 'txt';

sub _get_extension {
    my ($parent) = shift;
    if ($parent->{format_args}->{extension}){
        return $parent->{format_args}->{extension};
    } else {
        return $extension;
    }
}

=item escape($var)

Implements the templates escaping protocol. Returns C<$var>.

=cut

sub escape {
    return shift;
}

=item setup($parent, $cleanvars, $output)

Implements the template's initialization protocol.

=cut

sub setup {
    my ($parent, $cleanvars, $output) = @_;

    $cleanvars->{EDI_CURRENT_DATE} = $date;
    $cleanvars->{EDI_CURRENT_TIME} = $time;

    return ($output, {
        input_extension => _get_extension($parent),
        binmode => $binmode,
    });
}

sub process {
    my ($parent, $cleanvars, $output) = @_;

    my $arghash = $parent->get_template_args($extension,$binmode);
    my $template = Template->new($arghash) || die Template->error();
    unless ($template->process(
                $parent->get_template_source(_get_extension($parent)),
                $cleanvars,
                $output,
                {binmode => $binmode})
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
    $parent->{mimetype} = 'text/plain';
    return undef;
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
