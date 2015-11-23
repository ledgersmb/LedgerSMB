=head1 NAME

LedgerSMB::REST_Format::json - JSON support for LedgerSMB RESTful web services.

=head1 SYNOPSYS


my $hash = LedgerSMB::REST_Format::json::from_input($request);
my $json = LedgerSMB::REST_Format::json::to_output($request);

=head1 COPYRIGHT

Copyright (C) 2012 The LedgerSMB Core Team.

This file may be used under the terms of the GNU General Public License
version 2 or at your option any later version.  Please see the included
LICENSE.TXT file.

=cut

package LedgerSMB::REST_Format::json;

use JSON;
use LedgerSMB::Template::TXT; # sanitization
use strict;
use warnings;

my $json = JSON->new();
$json->pretty(1);
$json->indent(1);
$json->utf8(1);
$json->convert_blessed(1);

sub from_input{
    my $request = shift @_;
    return $json->decode($request->{payload});
}

sub to_output{
    my $request = shift @_;
    my $output = shift @_;
    return $json->encode(LedgerSMB::Template::TXT::preprocess($output));
}

1;
