
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

use Carp;
use HTML::Escape;
use HTTP::Status qw( HTTP_OK HTTP_UNAUTHORIZED HTTP_INTERNAL_SERVER_ERROR
    HTTP_SEE_OTHER HTTP_BAD_REQUEST );

use parent 'Exporter';
our @EXPORT_OK = qw(
    internal_server_error unauthorized session_timed_out
    incompatible_database template_response
    );

=head1 METHODS

This module declares no methods.

=head1 FUNCTIONS

=head2 internal_server_error($msg, $title, $company, $dbversion)

Returns a standard error representation for HTTP status 500

=cut


sub internal_server_error {
    my ($msg, $title, $company, $dbversion) = map { escape_html($_ // '') } @_;

    $title //= 'Error!';
    $msg =~ s/\n/<br>/g;
    my @body_lines = ( '<html><body>',
                       q{<h2 class="error">Error!</h2>},
                       "<p><b>$msg</b></p>" );
    push @body_lines, '<p>dbversion: ' . ($dbversion // '') .
         ', company: ' . ($company // '') . '</p>'
        if $company || $dbversion;

    push @body_lines, '</body></html>';

    return [ HTTP_INTERNAL_SERVER_ERROR,
             [ 'Content-Type' => 'text/html; charset=UTF-8',
               'X-LedgerSMB-App-Content' => 'yes' ],
             \@body_lines ];
}


=head2 unauthorized()

Returns a standard error representation for HTTP status 401

=cut

sub unauthorized {
    return [ HTTP_UNAUTHORIZED,
             [ 'Content-Type' => 'text/plain; charset=utf-8',
               'X-LedgerSMB-App-Content' => 'yes' ],
             [ 'Credentials invalid or session expired' ]
        ];
}

=head2 session_timed_out()

Returns a standard error representation for 'LedgerSMB session timed out'

=cut

sub session_timed_out {
    return [ HTTP_SEE_OTHER,
             [ 'Location' => 'login.pl?__action=logout&reason=timeout' ],
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
          [ 'Content-Type' => 'text/html; charset=utf-8',
            'X-LedgerSMB-App-Content' => 'yes' ],
          [ 'Database is not the expected version.  ' .
            "Was $actual, expected $expected.  " .
            'Please re-run <a href="setup.pl">setup.pl</a> to correct.' ] ];
}


=head2 template_response( $template, %args )

Transform a template into a PSGI response, taking additional args
into account:

=over

=item disposition

When set and equal to 'attach', generates a Content-Disposition header
with the value 'attachment'.

=item headers

Additional headers to include in the response.

=back

=cut


sub template_response {
    my ($template, %args) = @_;
    my $content_type = $template->{mimetype};
    $content_type .= '; charset=UTF-8' if $content_type =~ m|^text/|;

    my @headers = (
        'Content-Type' => $content_type,
        ($args{headers} // [])->@*
        );

    if ($args{disposition} and $args{disposition} eq 'attach') {
        my $name = $template->{output_options}->{filename};
        push @headers,
            'Content-Disposition' => qq{attachment; filename="$name"};
    }

    my $body = $template->{output};
    utf8::encode($body) if utf8::is_utf8($body); ## no critic

    return [ HTTP_OK, \@headers, [ $body ] ];
}


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2017 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
