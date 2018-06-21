
package LedgerSMB::Template::CSV;

=head1 NAME

LedgerSMB::Template::CSV - Template support module for LedgerSMB

=head1 DESCRIPTION

Implements C<LedgerSMB::Template>'s FORMATTER protocol for CSV output.

=head1 METHODS

=over

=cut

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
