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

use JSON;
use strict;
use warnings;

local $JSON::UTF8 = 1;

sub from_input{
    my $request = shift @_;
    return decode_json($request->{payload});
}

sub to_output{
    my $request = shift @_; 
    my $output = shift @_;
    return encode_json($output, { pretty => 1, indent => 2 };
}

1;
