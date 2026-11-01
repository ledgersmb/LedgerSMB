#!/usr/bin/perl

use strict;
use warnings;

use Test2::V0;
use Test2::Mock;
use LedgerSMB::Routes::ERP::API::Invoices;
use LedgerSMB::PGNumber;
use JSON::PP ();

my @results = (
    [{ type => 'customer', curr => 'USD', entity_credit_account => 1 }],
    [{ id => 1, parts_id => 1, qty => 1, sellprice => 100,
       amount_tc => 100, discount => 0, description => 'Service' }],
    [],
    [{ accno => '1200', description => 'Receivables' }],
    [{ id => 1, entity_id => 1, entity_class => 2, meta_number => 'CUSTOMER' }],
    [{ name => 'Customer', control_code => 'CUSTOMER' }],
    [[0]],
    [{ workflow_id => 1 }],
);
my $statements = mock 'InvoiceResponseStatement' => (add => [
    execute => sub { return 1 },
    fetchrow_hashref => sub { return shift $_[0]->{rows}->@* },
    fetchrow_arrayref => sub { return shift $_[0]->{rows}->@* },
    err => sub { return 0 },
]);
my $database = mock 'InvoiceResponseDatabase' => (add => [
    prepare => sub { return bless { rows => shift @results }, 'InvoiceResponseStatement' },
]);
my $company_methods = mock 'InvoiceResponseCompany' => (add => [
    workflows => sub { return $_[0] },
    fetch => sub { return $_[0] },
    state => sub { return 'SAVED' },
    get_current_actions => sub { return () },
]);
my $part = mock 'LedgerSMB::Part' => (override => [
    new => sub { return bless {}, 'LedgerSMB::Part' },
    get_by_id => sub {
    return { partnumber => 'SERVICE', unit => 'hr', description => 'Service',
             weight => LedgerSMB::PGNumber->new('1.25'),
             onhand => LedgerSMB::PGNumber->new(0) };
}]);
my $response = LedgerSMB::Routes::ERP::API::Invoices::_get_invoices_by_id(
    { 'lsmb.db' => bless({}, 'InvoiceResponseDatabase') }, undef,
    bless({}, 'InvoiceResponseCompany'), undef, { id => '1' });
my $line = $response->[2]->{lines}->[0];
is $line->{part}->{weight}, '1.25', 'Weight is represented as a string';
is ref($line->{part}->{weight}), '', 'Weight is not a numeric object';
is $line->{part}->{onhand}, '0', 'On-hand quantity is represented as a string';
is ref($line->{part}->{onhand}), '', 'On-hand quantity is not a numeric object';
ok JSON::PP::is_bool($line->{price_fixated}), 'Price fixation is a JSON boolean';
my (undef, $errors) = LedgerSMB::Router::router('erp/api')->api_validator->validate_response(
    method => 'GET', openapi_path => '/invoices/{id}', status => 200,
    parameters => { path => { id => '1' }, header => { 'Content-Type' => 'application/json' },
                    query => {}, body => [1, 'application/json', $response->[2]] });
is $errors, [], 'Real getter response passes OpenAPI validation before serialization';
done_testing;
