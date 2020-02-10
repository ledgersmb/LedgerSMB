#!perl

use lib 'xt/lib';
use strict;
use warnings;

use Test::More;
use Test::BDD::Cucumber::StepFile;


When qr/^I enter "(.*)" as the description for a new rate type/, sub {
    my $data = $1;
    my $page = S->{ext_wsl}->page->body->maindiv->content;

    my $input = $page->find('//input[@id="description"]')
        or die 'failed to find description field for defining a new rate type';

    $input->clear;
    $input->send_keys($data);
};


When qr/^I enter "(.*)" as the id for a new currency/, sub {
    my $data = $1;
    my $page = S->{ext_wsl}->page->body->maindiv->content;

    my $input = $page->find('//input[@id="curr"]')
        or die 'failed to find id field for defining a new currency';

    $input->clear;
    $input->send_keys($data);
};


When qr/^I enter "(.*)" as the description for a new currency/, sub {
    my $data = $1;
    my $page = S->{ext_wsl}->page->body->maindiv->content;

    my $input = $page->find('//input[@id="description"]')
        or die 'failed to find description field for defining a new currency';

    $input->clear;
    $input->send_keys($data);
};


1;
