#!perl

use lib 'xt/lib';
use strict;
use warnings;

use Test::More;
use Test::BDD::Cucumber::StepFile;


When qr/^I click Control Code "(.*)"$/, sub {
    my $page = S->{ext_wsl}->page->body->maindiv->content;
    my $link_text = $1;

    my $link = $page->find(
        qq{.//td[contains(\@class,"entity_control_code")]/a[.="$link_text"]}
    ) or die "failed to find link for Control Code $link_text";

    ok($link->click, "clicked link for Control Code $link_text");
};

1;
