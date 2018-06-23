
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

use HTTP::Status qw( HTTP_OK HTTP_INTERNAL_SERVER_ERROR HTTP_SEE_OTHER
 HTTP_UNAUTHORIZED );

=head1 METHODS

This module declares no methods.

=head1 FUNCTIONS

=head2 internal_server_error($msg, $title, $company, $dbversion)

Returns a standard error representation for HTTP status 500

=cut


sub internal_server_error {
    my ($msg, $title, $company, $dbversion) = @_;

    $title //= 'Error!';
    $msg =~ s/\n/<br>/g;
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


=head2 unauthorized()

Returns a standard error representation for HTTP status 401

=cut

sub unauthorized {
    return [ HTTP_UNAUTHORIZED,
             [ 'Content-Type' => 'text/plain; charset=utf-8',
               'WWW-Authenticate' => 'Basic realm=LedgerSMB' ],
             [ 'Please enter your credentials' ]
        ];
}

=head2 session_timed_out()

Returns a standard error representation for 'LedgerSMB session timed out'

=cut

sub session_timed_out {
    return [ HTTP_SEE_OTHER,
             [ 'Location' => 'login.pl?action=logout&reason=timeout' ],
             [] ];
}


=head2 incompatible_database($expected, $actual)

Returns a standard error representation for 'LedgerSMB database version
incompatible'

=cut

sub incompatible_database {
    my ($expected, $actual) = @_;

    return
        [ 521, ## no critic
          [ 'Content-Type' => 'text/html; charset=utf-8' ],
          [ 'Database is not the expected version.  ' .
            "Was $actual, expected $expected.  " .
            'Please re-run <a href="setup.pl">setup.pl</a> to correct.' ] ];
}


=head2 template_to_psgi($template, %args)

Returns a PSGI return value triplet (status, headers and body).

Note that the only guarantee here is that the triplet can
be used as a PSGI return value which means that the body
is *not* restricted to being an array of strings.

When C<extra_headers> is specified in the C<%args> hash, these are
included in the headers part of returned triplet.

=cut


sub template_to_psgi {
    my $self = shift @_;
    my %args = ( @_ );

    my $charset = '';
    $charset = '; charset=utf-8'
        if $self->{mimetype} =~ m!^text/!;

    # $self->{mimetype} set by format
    my $headers = [
        'Content-Type' => "$self->{mimetype}$charset",
        (@{$args{extra_headers} // []})
        ];

    # Use the same Content-Disposition criteria as _http_output()
    my $name = $self->{output_options}{filename};
    if ($name) {
        $name =~ s#^.*/##;
        push @$headers,
            ( 'Content-Disposition' =>
              qq{attachment; filename="$name"} );
    }

    my $body = $self->{output};
    utf8::encode($body)
        if utf8::is_utf8($body);

    return [ HTTP_OK, $headers, [ $body ] ];
}


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2017 The LedgerSMB Core Team

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
