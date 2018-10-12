#!perl

use lib 'xt/lib';
use strict;
use warnings;

use Test::More;
use Test::BDD::Cucumber::StepFile;

When qr/^I click Account Number "(.*)"$/, sub {
    my $page = S->{ext_wsl}->page->body->maindiv->content;
    my $account_number = $1;

    my $link = $page->find(
        qq{.//td[contains(\@class,"accno")]/a[.="$account_number"]}
    ) or die "failed to find link for Account Number $account_number";

    ok($link->click, "clicked link for Account Number $account_number");
};


1;
