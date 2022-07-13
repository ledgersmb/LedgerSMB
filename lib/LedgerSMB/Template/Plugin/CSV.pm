
package LedgerSMB::Template::Plugin::CSV;

=head1 NAME

LedgerSMB::Template::Plugin::CSV - Template support module for LedgerSMB

=head1 DESCRIPTION

Implements C<LedgerSMB::Template>'s FORMATTER protocol for CSV output.

=cut

use warnings;
use strict;

use Moo;

my $binmode = ':utf8';
my $extension = 'csv';

=head1 ATTRIBUTES

=head2 formats

=cut

has formats => (is => 'ro', default => sub { [ 'CSV' ] });

=head2 format

=cut

has format => (is => 'ro', default => 'CSV');

=head1 METHODS

=head2 setup($parent, $vars, $output)

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
