#!perl

use lib 'xt/lib';
use strict;
use warnings;

use Test::More;
use Test::BDD::Cucumber::StepFile;


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


When qr/^I click "(.*)" for the row with (.*) "(.*)"$/, sub {
    my $link_text = $1;
    my $column = $2;
    my $value = $3;
    my @rows = S->{ext_wsl}->page->body->maindiv->content->rows;

    foreach my $row(@rows) {
        if ($row->{$column} eq $value) {
            my $link = $row->{_element}->find(
                qq{.//a[.="$1"]}
            );
            ok($link, "found $link_text link for $column '$value'");
            $link->click;
            last;
        }
    }
};


Then qr/I should see the title "(.*)"/, sub {
    my $page = S->{ext_wsl}->page->body->maindiv->content;
    my $title = $1;

    my $div = $page->title(title => $title);
    ok($div, "Found title '$title'");
};


1;
