
package LedgerSMB::Template::Plugin::HTML;

=head1 NAME

LedgerSMB::Template::Plugin::HTML - Template support module for LedgerSMB

=head1 DESCRIPTION

Implements C<LedgerSMB::Template>'s FORMATTER protocol for HTML output.

=cut

use strict;
use warnings;

use HTML::Escape;

use Moo;

my $binmode = ':utf8';
my $extension = 'html';

=head1 ATTRIBUTES

=head2 formats

Holds an array of strings naming the formats supported by this plugin.

=cut

has formats => (is => 'ro', default => sub { [ 'HTML' ] });

=head2 format

Holds a string naming the actual format for which this plugin
is configured. The plugin can be used multiple times with different
formats, as long as they are in the list of formats.

=cut

has format => (is => 'ro', default => 'HTML');

=head1 METHODS

=head2 escape($string)

Escapes a scalar string and returns the sanitized version.

=cut

sub escape {
    my $self = shift;
    my $vars = shift @_;
    return undef unless defined $vars;
    $vars = escape_html($vars);
    return $vars;
}

=head2 setup($parent, $cleanvars, $output)

Implements the template's initialization protocol.

=cut

sub setup {
    my ($self, $parent, $cleanvars, $output) = @_;

    return ($output, {
        input_extension => $extension,
        binmode => $binmode,
    });
}

=head2 postprocess($parent, $output, $config)

Implements the template's post-processing protocol.

=cut

sub postprocess {
    my ($self, $parent, $output, $config) = @_;
    return undef;
}

=head2 mimetype()

Returns the rendered template's mimetype.

=cut

sub mimetype {
    my $self = shift;
    my $config = shift;
    return 'text/' . $extension;
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2007-2022 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
