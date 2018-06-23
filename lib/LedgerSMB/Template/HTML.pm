
package LedgerSMB::Template::HTML;

=head1 NAME

LedgerSMB::Template::HTML - Template support module for LedgerSMB

=head1 DESCRIPTION

Implements C<LedgerSMB::Template>'s FORMATTER protocol for HTML output.

=head1 METHODS

=over

=cut

use strict;
use warnings;

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
    return undef;
}

=item mimetype()

Returns the rendered template's mimetype.

=cut

sub mimetype {
    my $config = shift;
    return 'text/' . $extension;
}

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2007-2018 The LedgerSMB Core Team

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
