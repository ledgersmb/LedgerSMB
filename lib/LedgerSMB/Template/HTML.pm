
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

=item setup($parent, $cleanvars, $output)

Implements the template's initialization protocol.

=cut

sub setup {
    my ($parent, $cleanvars, $output) = @_;
    my $dojo_theme;
    $dojo_theme = $LedgerSMB::App_State::Company_Config->{dojo_theme}
            if $LedgerSMB::App_State::Company_Config;
    $cleanvars->{dojo_theme} //= $dojo_theme;
    $cleanvars->{dojo_theme} //= $LedgerSMB::Sysconfig::dojo_theme;;
    $cleanvars->{dojo_built} ||= $LedgerSMB::Sysconfig::dojo_built;
    $cleanvars->{UNESCAPE} = sub { return decode_entities(shift @_) };

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
