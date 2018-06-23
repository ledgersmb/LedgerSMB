
package LedgerSMB::Template::TXT;

=head1 NAME

LedgerSMB::Template::TXT - Template support module for LedgerSMB

=head1 DESCRIPTION

Implements C<LedgerSMB::Template>'s FORMATTER protocol for TXT output.

=head1 METHODS

=over

=cut

use strict;
use warnings;

use DateTime;

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
    return 'text/plain';
}

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2007-2018 The LedgerSMB Core Team

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
