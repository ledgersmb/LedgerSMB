#!perl


use lib 'xt/lib';
use strict;
use warnings;

use LedgerSMB::App_State;
use LedgerSMB::Database;
use LedgerSMB::Entity::Person::Employee;
use LedgerSMB::Entity::User;
use LedgerSMB::PGDate;


use Module::Runtime qw(use_module);
use PageObject::App::Login;

use Test::More;
use Test::BDD::Cucumber::StepFile;


When qr/I open the sales invoice entry screen/, sub {
    my @path = split /[\n\s\t]*>[\n\s\t]*/, 'AR > Sales Invoice';

    S->{ext_wsl}->page->body->menu->click_menu(\@path);
    S->{ext_wsl}->page->body->verify;
};

When qr/I open the AR transaction entry screen/, sub {
    my @path = split /[\n\s\t]*>[\n\s\t]*/, 'AR > Sales Invoice';

    S->{ext_wsl}->page->body->menu->click_menu(\@path);
    S->{ext_wsl}->page->body->verify;
};

When qr/I select customer "(.*)"/, sub {
    my $customer = $1;

    my $page = S->{ext_wsl}->page->body->maindiv->content;
    $page->select_customer($customer);

};



1;
