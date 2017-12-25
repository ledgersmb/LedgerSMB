
package LedgerSMB::PSGI::Util;

=head1 NAME

LedgerSMB::PSGI::Util - LedgerSMB PSGI Utility functions

=head1 SYNOPSIS

  return
     LedgerSMB::PSGI::Util::internal_server_error('error','Title',
                                 'company', $request->{dbversion});

=head1 DESCRIPTION

LedgerSMB::Middleware::DynamicLoadWorkflow makes sure the new-style
workflow scripts have successfully been loaded before being dispatched to.

This module implements the C<Plack::Middleware> protocol.

=cut

use strict;
use warnings;

use HTTP::Status qw( HTTP_INTERNAL_SERVER_ERROR );

=head1 FUNCTIONS

=head2 internal_server_error($msg, $title, $company, $dbversion)

Returns a standard error representation for HTTP status 500

=cut


sub internal_server_error {
    my ($msg, $title, $company, $dbversion) = @_;

    $title //= 'Error!';
    my @body_lines = ( '<html><body>',
                       q{<h2 class="error">Error!</h2>},
                       "<p><b>$msg</b></p>" );
    push @body_lines, "<p>dbversion: $dbversion, company: $company</p>"
        if $company || $dbversion;

    push @body_lines, '</body></html>';

    return [ HTTP_INTERNAL_SERVER_ERROR,
             [ 'Content-Type' => 'text/html; charset=UTF-8' ],
             \@body_lines ];
}

=head1 COPYRIGHT

Copyright (C) 2017 The LedgerSMB Core Team

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
