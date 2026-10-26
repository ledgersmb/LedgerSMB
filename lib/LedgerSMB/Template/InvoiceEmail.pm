package LedgerSMB::Template::InvoiceEmail;

use strict;
use warnings;

=head1 NAME

LedgerSMB::Template::InvoiceEmail - Prepare invoice email using the UI renderer

=head1 DESCRIPTION

Renders the saved sales invoice using the existing legacy invoice print/email
path. The returned envelope contains configured sender, customer recipients,
message expansions and a PDF attachment. This operation does not send mail or
commit the caller's transaction.

=head1 METHODS

=head2 prepare($company, $user, $id, $language)

Returns the Email workflow context prepared by the UI's email renderer.

=cut

use JSON::MaybeXS;
use MIME::Base64 qw(decode_base64);
use Plack::Util;
use LedgerSMB::old_code qw(dispatch_no_commit);

sub prepare {
    my ($class, $company, $user, $id, $language) = @_;
    my $response = dispatch_no_commit('is.pl', 'e_mail', $user, {
        id => $id, dbh => $company->dbh, type => 'invoice', formname => 'invoice',
        format => 'pdf', language_code => $language, vc => 'customer',
        _user => $user, _wire => $company->wire, _conn => $company,
        _api_email_prepare => 1,
    });
    die 'Invoice email preparation failed' unless $response->[0] == 200;
    my $output = '';
    Plack::Util::foreach($response->[2], sub { $output .= $_[0] });
    $response->[2]->close if ref $response->[2] ne 'ARRAY';
    my $data = JSON::MaybeXS->new(utf8 => 1)->decode($output);
    for my $attachment ($data->{_attachments}->@*) {
        $attachment->{content} = decode_base64(delete $attachment->{content_base64});
    }
    $data->{immediateSend} = 0;
    return $data;
}

1;

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut
