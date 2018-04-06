
=head1 NAME

LedgerSMB::Template::CSV - Template support module for LedgerSMB

=head1 METHODS

=over

=cut

package LedgerSMB::Template::CSV;

use warnings;
use strict;

my $binmode = ':utf8';
my $extension = 'csv';

=item escape($var)

Implements the template's escaping protocol. Returns C<$var>.

=cut

sub escape {
    return shift;
}

=item setup($parent, $vars, $output)

Implements the template's initialization protocol.

=cut

sub setup {
    my ($parent, $cleanvars, $output) = @_;

    return ($output, {
        input_extension => $extension,
        binmode => $binmode,
    });
}

=item postprocess($parent, $output, $config)

Implements the template's post-processing protocol.

=cut

sub postprocess {
    my ($parent, $output, $config) = @_;
    $parent->{mimetype} = 'text/' . $extension;
    return undef;
}

=back

=head1 Copyright (C) 2007-2017, The LedgerSMB core team.

It is released under the GNU General Public License Version 2 or, at your
option, any later version.  See COPYRIGHT file for details.  For a full list
including contact information of contributors, maintainers, and copyright
holders, see the CONTRIBUTORS file.

=cut


1;
