
use v5.38;
use experimental qw(signatures);

package LedgerSMB::Template::Plugin::CSV;

=head1 NAME

LedgerSMB::Template::Plugin::CSV - Template support module for LedgerSMB

=head1 DESCRIPTION

Implements C<LedgerSMB::Template>'s FORMATTER protocol for CSV output.

=cut

use Moo;

my $binmode = ':utf8';
my $extension = 'csv';

=head1 ATTRIBUTES

=head2 formats

Holds an array of strings naming the formats supported by this plugin.

=cut

has formats => (is => 'ro', default => sub { [ 'CSV' ] });

=head2 format

Holds a string naming the actual format for which this plugin
is configured. The plugin can be used multiple times with different
formats, as long as they are in the list of formats.

=cut

has format => (is => 'ro', default => 'CSV');

=head2 numberformat

Number format to use, overriding the user's formatting preference. Normally,
this should be set to C<1000.00> to suppress the thousands separator and use
the point as the decimal separator as the practical CSV standard.

=cut

has numberformat => (is => 'ro');

=head1 METHODS

=head2 escape($string)

Escapes a scalar string and returns the sanitized version.

=cut

sub escape($self, $vars) {
    return $vars;
}

=head2 setup($parent, $vars, $output)

Implements the template's initialization protocol.

=cut

sub setup($self, $parent, $cleanvars, $output) {
    return ($output, {
        input_extension => $extension,
        binmode => $binmode,
    });
}

=head2 postprocess($parent, $output, $config)

Implements the template's post-processing protocol.

=cut

sub postprocess($self, $parent, $output, $config) {
    return undef;
}

=head2 mimetype()

Returns the rendered template's mimetype.

=cut

sub mimetype($self, $config) {
    return 'text/' . $extension;
}


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2007-2022 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
