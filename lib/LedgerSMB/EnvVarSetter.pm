
package LedgerSMB::EnvVarSetter;

=head1 NAME

LedgerSMB::EnvVarSetter - Changing environment variables

=head1 SYNOPSIS

  environment:
    $class: LedgerSMB::EnvVarSetter
    $lifecycle: eager
    $method: set
    PATH: /usr/bin:/usr/local/bin

=head1 DESCRIPTION

Sets environment variables to specified values. This module can be used
to declare environment variable values by means of dependency injection
through L<Beam::Wire>. See SYNOPSIS for an example of how to do this.

=cut

use strict;
use warnings;

use Moo;

our $VERSION = '0.0.1';

=head1 CLASS METHODS

=head2 set( %envvars )

Sets the environment variables in the hash's keys to the values specified
in the hash's values. Note that the current value - if there is one - is
plainly overwritten. There is no mechanism for appending the value specified.

=cut

sub set {
    my $class = shift;
    my %args = @_;

    for my $var (keys %args) {
        $ENV{$var} = ($args{$var} =~ s/^\+/$ENV{$var}/r); ## no critic (RequireLocalizedPunctuationVars)
    }
}



1;


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2022 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

