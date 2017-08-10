
=head1 NAME

LedgerSMB::Template::HTML - Template support module for LedgerSMB

=head1 METHODS

=over

=cut

package LedgerSMB::Template::HTML;

use strict;
use warnings;

use Template;
use HTML::Entities;
use HTML::Escape;
use LedgerSMB::Sysconfig;
use LedgerSMB::App_State;

my $binmode = ':utf8';
my $extension = 'html';

=item escape($string)

Escapes a scalar string and returns the sanitized version.

=cut

sub escape {
    my $vars = shift @_;
    return undef unless defined $vars;
    #$vars = encode_entities($vars);
    $vars = escape_html($vars);
    return $vars;
}

=item unescape($string)

Apply the reverse transformation of C<escape> to <$string>.

=cut

sub unescape {
    return decode_entities(shift @_);
}

=item setup($parent, $cleanvars, $output)

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
