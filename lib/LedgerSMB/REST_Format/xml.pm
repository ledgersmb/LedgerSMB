=head1 NAME

LedgerSMB::REST_Format::xml - XML file support for LedgerSMB RESTful web
services.

=head1 SYNOPSYS


my $hash = LedgerSMB::REST_Format::xml::from_input($request);
my $xml = LedgerSMB::REST_Format::xml::to_output($request, $output);

=head1 COPYRIGHT

Copyright (C) 2012 The LedgerSMB Core Team.

This file may be used under the terms of the GNU General Public License
version 2 or at your option any later version.  Please see the included
LICENSE.TXT file.

=cut

package LedgerSMB::REST_Format::xml;
use XML::Simple;
use strict;
use warnings;

=head1 METHODS

=over

=item LedgerSMB::REST_Format::json::from_input($request)

Parses and returns the $request->{payload} attribute as a Perl object

=cut

sub from_input{
    my $request = shift @_;
    return XMLin($request->{payload}, ForceArray=>1);
}

=item LedgerSMB::REST_Format::json::to_output($request, $output)

Serializes the Perl object (hash) $output with the XML root name taken
from $request->{class_name}.

=cut

sub to_output{
    my $request = shift @_;
    my $output = shift @_;
    return XMLout($output, RootName => $request->{class_name},
           ContentKey => 'text');
}

=back

=cut;

1;
