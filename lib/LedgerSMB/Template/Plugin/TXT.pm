
package LedgerSMB::Template::Plugin::TXT;

=head1 NAME

LedgerSMB::Template::Plugin::TXT - Template support module for LedgerSMB

=head1 DESCRIPTION

Implements C<LedgerSMB::Template>'s FORMATTER protocol for TXT output.

=cut

use strict;
use warnings;

use DateTime;


use Moo;

=head1 ATTRIBUTES

=head2 formats

Holds an array of strings naming the formats supported by this plugin.

=cut

has formats => (is => 'ro', default => sub { [ 'TXT' ] });

=head2 format

Holds a string naming the actual format for which this plugin
is configured. The plugin can be used multiple times with different
formats, as long as they are in the list of formats.

=cut

has format => (is => 'ro', default => 'TXT');

# The following are for EDI only
my $dt = DateTime->now;
my $date = sprintf('%04d%02d%02d', $dt->year, $dt->month, $dt->day);
my $time = sprintf('%02d%02d', $dt->hour, $dt->min);

my $binmode = ':utf8';
my $extension = 'txt';

sub _get_extension {
    my ($parent) = shift;
    if ($parent->{format_options}->{extension}){
        return $parent->{format_options}->{extension};
    } else {
        return $extension;
    }
}

=head1 METHODS

=head2 setup($parent, $cleanvars, $output)

Implements the template's initialization protocol.

=cut

sub setup {
    my ($self, $parent, $cleanvars, $output) = @_;

    $cleanvars->{EDI_CURRENT_DATE} = $date;
    $cleanvars->{EDI_CURRENT_TIME} = $time;

    return ($output, {
        input_extension => _get_extension($parent),
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
    return 'text/plain';
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2007-2022 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
