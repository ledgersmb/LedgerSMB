
package LedgerSMB::EnvVarSetter;

=head1 NAME

LedgerSMB::EnvVarSetter -

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use strict;
use warnings;

use Moo;

our $VERSION = '0.0.1';

=head1 CLASS METHODS

=head2 set( %envvars )

=cut

sub set {
    my $class = shift;
    my %args = @_;

    for my $var (keys %args) {
        $ENV{$var} = $args{$var}; ## no critic (RequireLocalizedPunctuationVars)
    }
}



1;


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2022 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

