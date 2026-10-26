#!/usr/bin/perl

use strict;
use warnings;

use Test2::V0;
use Test2::Mock;
use JSON::MaybeXS;
use MIME::Base64 qw(encode_base64);
use LedgerSMB::Template::InvoiceEmail;

my @args;
my $binary = "%PDF-test\0\xff";
my $dispatcher = mock 'LedgerSMB::Template::InvoiceEmail' => (override => [
    dispatch_no_commit => sub {
        @args = @_;
        return [200, ['Content-Type' => 'application/json'], [
            JSON::MaybeXS->new(utf8 => 1)->encode({
                from => 'sender@example.com', to => 'customer@example.com',
                subject => 'Invoice', body => "\x{e9}",
                _attachments => [{ content_base64 => encode_base64($binary, ''),
                                   mime_type => 'application/pdf', file_name => 'invoice.pdf' }],
            }),
        ]];
    },
]);
my $company_methods = mock 'RenderTestCompany' => (add => [
    dbh => sub { return 'test-dbh' }, wire => sub { return 'test-wire' },
]);
my $company = bless {}, 'RenderTestCompany';
my $user = { language => 'en' };
my $data = LedgerSMB::Template::InvoiceEmail->prepare($company, $user, 42, 'fr');
is $args[0], 'is.pl', 'Uses the existing invoice script';
is $args[1], 'e_mail', 'Uses the existing email preparation path';
is $args[2], $user, 'Passes authenticated user preferences';
is $args[3]->{id}, 42, 'Renders saved invoice by id';
is $args[3]->{language_code}, 'fr', 'Passes invoice language';
is $args[3]->{format}, 'pdf', 'Requests configured PDF formatter';
ok $args[3]->{_api_email_prepare}, 'Preparation only; does not invoke mail workflow';
is $data->{_attachments}->[0]->{content}, $binary, 'Binary PDF survives dispatch encoding';
is $data->{body}, "\x{e9}", 'Unicode body survives dispatch encoding';
is $data->{immediateSend}, 0, 'Sending deferred until attempt is durable';

my $failure = mock 'LedgerSMB::Template::InvoiceEmail' => (override => [
    dispatch_no_commit => sub { return [500, [], []] },
]);
like dies { LedgerSMB::Template::InvoiceEmail->prepare($company, $user, 42, 'fr') },
    qr/preparation failed/, 'Rendering failure is not treated as a valid attachment';

done_testing;
