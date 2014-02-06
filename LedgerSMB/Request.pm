=head1 NAME

LedgerSMB::Request - Basic request handling routines for LedgerSMB

=head1 SYNPOSIS

   $request->requires('myattribute1', 'myattribute2');

Error:  Attribute 'myattribute2' is not provided.

   $request->requires_series(1, 12, 'myattribute1', 'myattribute2');

=cut

package LedgerSMB::Request;
use LedgerSMB::App_State;
use Carp;

=head1 DESCRIPTION

This package provides methods (as an interface package, as of 1.4) for both new
and old code to use for declarative handling of required inputs, dates, and 
amounts.

In future versions, this may take on more of the role found in LedgerSMB.pm 
today, but hopefully with a lot less cruft.  It isn't clear we will use
CGI::Simple or rely on a specific interface and so some portability in request
handling will be required.  That's where this module comes in.

=head1 METHODS

=head2 requires(@attribute_names)

Raises an exception if any member of the argument list corresponds to a non-key
in the current hash or an empty string.  '0' does pass however.

=cut

sub requires {
    my $self = shift @_;
    for (@_){
        Carp::croak(LedgerSMB::App_State->Locale->text("Required attribute not provided: [_1]", $_))
              unless $self->{$_} or $self->{$_} eq '0';
    }
}

=head2 requries_series($start, $stop, @attnames)

Generates and checks a series of attributes in the form of ${attname}_$count
from $start to $stop, for each in @attnames

=cut

sub requires_series {
    my $self = shift @_;
    my $start = shift @_;
    my $end  = shift @_;
    for my $att (@_){
        $self->requires("${att}_$_") for ($start .. $stop);
    }
}

=head1 COPYRIGHT

Copyright (C) 2014 The LedgerSMB Core Team.

This file may be re-used under the terms of the GNU General Public License
version 2 or at your option any later version.  Please see the LICENSE.txt for
details.

=cut

1;
