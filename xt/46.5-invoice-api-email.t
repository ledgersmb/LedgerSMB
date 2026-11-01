#!/usr/bin/perl

use strict;
use warnings;

use Test2::V0;
use Test2::Mock;
use DBI;
use Plack::Request;
use Email::Sender::Transport::Test;
use LedgerSMB::Routes::ERP::API::Invoices;
use LedgerSMB::Workflow;
use LedgerSMB::Workflow::Loader;
use LedgerSMB::File::Email;

plan skip_all => 'Database tests not enabled' unless $ENV{LSMB_TEST_DB};

my $dbh = DBI->connect('dbi:Pg:dbname=' . $ENV{LSMB_NEW_DB}, undef, undef,
                      { AutoCommit => 0, RaiseError => 1, PrintError => 0 });
$dbh->do(q{
    CREATE TEMP TABLE transactions
        (id int, workflow_id int, approved boolean DEFAULT true,
         transdate date DEFAULT '2026-10-26', trans_type_code text DEFAULT 'ar');
    CREATE TEMP TABLE ar (trans_id int, invoice boolean DEFAULT true, language_code text);
    CREATE TEMP TABLE workflow
        (workflow_id int PRIMARY KEY, type text, state text, last_update timestamp);
    CREATE TEMP TABLE workflow_context (workflow_id int PRIMARY KEY, context text);
    CREATE TEMP SEQUENCE workflow_seq START 100;
    CREATE TEMP SEQUENCE workflow_history_seq;
    CREATE TEMP TABLE workflow_history
        (workflow_hist_id int, workflow_id int, action text, description text,
         state text, workflow_user text, history_date timestamp);
    CREATE TEMP TABLE email
        (workflow_id int PRIMARY KEY, "from" text, "to" text, cc text, bcc text,
         notify text, subject text, body text, expansions text, sent_date timestamp);
    CREATE TEMP TABLE mime_type (id int, mime_type text);
    INSERT INTO mime_type VALUES (1, 'application/pdf');
    CREATE TEMP TABLE file_email
        (id serial, ref_key int, file_name text, description text, mime_type_id int,
         content bytea);
    INSERT INTO transactions (id, workflow_id) VALUES (1,11), (2,12), (3,13), (4,14);
    INSERT INTO ar (trans_id) VALUES (1), (2), (3), (4);
    INSERT INTO workflow SELECT workflow_id, 'AR/AP', 'POSTED', now() FROM transactions;
    UPDATE workflow SET state = 'ONHOLD' WHERE workflow_id = 12;
});

my $factory = LedgerSMB::Workflow::Loader->load(directories => ['workflows']);
my $transport = Email::Sender::Transport::Test->new;
my $company;
my $methods = mock 'InvoiceEmailTestCompany' => (add => [
    dbh => sub { return $dbh },
    workflows => sub { return $_[0] },
    wire => sub { return $_[0] },
    get => sub { return { transport => $transport } },
    fetch => sub { return $factory->fetch_workflow($company, $_[1], $_[2]) },
]);
$company = bless {}, 'InvoiceEmailTestCompany';

# The full-company legacy renderer is tested separately in staging. This test
# isolates rendering and file attachment SQL, not workflow persistence or mail.
my $renders = 0;
my $render = mock 'LedgerSMB::Template::InvoiceEmail' => (override => [prepare => sub {
    $renders++;
    return {
        from => 'accounts@example.com', to => 'customer@example.com',
        subject => 'Invoice TEST', body => 'Amount <%total%>', expansions => { total => '107.00' },
        _attachments => [{ content => "%PDF-test\0\xff", mime_type => 'application/pdf',
                           file_name => 'invoice-TEST.pdf' }],
    };
}]);
my $files = mock 'LedgerSMB::File::Email' => (override => [
    get_mime_type => sub { return 1 },
    attach => sub {
        my ($file) = @_;
        my $content = $file->content;
        $content = $$content if ref $content;
        my $id = $dbh->selectrow_array(q{
            INSERT INTO file_email (ref_key, file_name, mime_type_id, content)
                 VALUES (?, ?, 1, ?) RETURNING id
        }, {}, $file->ref_key, $file->file_name, $content);
        return { id => $id };
    },
]);
my $request = Plack::Request->new({ HTTP_ACCEPT => 'application/json' });

sub invoice_email {
    my ($method, $id) = @_;
    return LedgerSMB::Routes::ERP::API::Invoices::_invoice_email(
        { REQUEST_METHOD => $method, 'lsmb.user' => {}, 'lsmb.app' => $dbh,
          'lsmb.session' => {} },
        $request, $company, undef, { id => $id });
}

subtest 'Status reads do not render or send; only posted invoices can be emailed' => sub {
    is invoice_email('GET', '1')->[2]->{status}, 'not_requested', 'No attempt yet';
    is invoice_email('POST', '2')->[0], 409, 'Held invoice blocked';
    is invoice_email('POST', '99')->[0], 404, 'Missing invoice';
    is invoice_email('POST', 'invalid')->[0], 400, 'Invalid identifier';
    is $renders, 0, 'No rendering';
    is scalar($transport->deliveries), 0, 'No mail';
};

subtest 'Persisted Email workflow sends once and retains its attachment' => sub {
    my $response = invoice_email('POST', '1');
    is $response->[0], 200, 'Email operation succeeded';
    is $response->[2]->{status}, 'sent', 'Transport accepted message';
    my $id = $response->[2]->{email}->{id};
    is scalar($transport->deliveries), 1, 'One message';
    my ($delivery) = $transport->deliveries;
    like $delivery->{email}->as_string, qr/invoice-TEST\.pdf/, 'Invoice attachment included';
    like $delivery->{email}->as_string, qr/Amount 107\.00/, 'Workflow expanded the body';
    ok $dbh->selectrow_array('SELECT sent_date IS NOT NULL FROM email WHERE workflow_id = ?', {}, $id),
        'Send timestamp saved';
    # Simulate request middleware committing success before a client retry.
    $dbh->commit;
    is invoice_email('GET', '1')->[2]->{status}, 'sent', 'Status is checkable';
    is invoice_email('POST', '1')->[2]->{email}->{id}, $id, 'Retry returns same email workflow';
    is scalar($transport->deliveries), 1, 'Retry does not send again';
    is $renders, 1, 'Retry does not regenerate invoice';
    is $dbh->selectrow_array('SELECT count(*) FROM file_email WHERE ref_key = ?', {}, $id),
        1, 'One persisted attachment';
};

subtest 'Ambiguous transport failure is durable and never automatically retried' => sub {
    my $calls = 0;
    my $sender = mock 'Email::Sender::Simple' => (override => [send => sub {
        $calls++;
        # The failure may occur after the remote service has accepted mail.
        die 'Simulated transport interruption';
    }]);
    my $response = invoice_email('POST', '3');
    is $response->[0], 202, 'Uncertain attempt is not reported as successful';
    is $response->[2]->{status}, 'unknown', 'Delivery status is explicitly uncertain';
    is invoice_email('GET', '3')->[2]->{status}, 'unknown', 'Attempt marker survived rollback';
    my $id = $response->[2]->{email}->{id};
    is invoice_email('POST', '3')->[2]->{email}->{id}, $id, 'Retry returns original attempt';
    is $calls, 1, 'No automatic resend after failure';
    is $renders, 2, 'No second render';
};

subtest 'Missing contact information fails before a durable attempt' => sub {
    my $missing = mock 'LedgerSMB::Template::InvoiceEmail' => (override => [prepare => sub {
        return { from => 'accounts@example.com', _attachments => [] };
    }]);
    is invoice_email('POST', '4')->[0], 409, 'Missing recipient/attachment blocked';
    is invoice_email('GET', '4')->[2]->{status}, 'not_requested', 'May fix contact and try again';
};

subtest 'Registered status route validates normal and uncertain responses' => sub {
    my $app = mock 'LedgerSMB::Company' => (override => [new => sub { return $company }]);
    LedgerSMB::Router::router('erp/api')->hooks(before => sub { return });
    for my $id ('1', '3') {
        my $response = LedgerSMB::Router::router('erp/api')->dispatch({
            REQUEST_METHOD => 'GET', PATH_INFO => "/invoices/$id/email", QUERY_STRING => '',
            'lsmb.app' => $dbh,
        });
        is $response->[0], $id eq '1' ? 200 : 202, 'Status route passes OpenAPI validation';
    }
};

$dbh->rollback;
$dbh->disconnect;
done_testing;
