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


When qr/^I (select|deselect) every checkbox in "(.*)"$/, sub {
    my $wanted_state = ($1 eq 'select');
    my $section = $2;
    my $page = S->{ext_wsl}->page->body->maindiv->content;
    my %section_ids = (
        'Options' => 'acc-options-line',
        'Include in drop-down menus' => 'dropdowns',
    );

    my @checkboxes = $page->find_all(
        qq{.//div[\@id="$section_ids{$section}"]//input[\@type="checkbox"]}
    ) or die "failed to find checkboxes";

    foreach my $checkbox (@checkboxes) {
        my $checked = $checkbox->get_attribute('checked');
        my $checked_status = $checked && $checked eq 'true';
        if ($checked_status xor $wanted_state) {
            $checkbox->click();
        }
    }
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


Then qr/^I expect to see (\d+) selected checkboxes in "(.*)"$/, sub {
    my $wanted_count = $1;
    my $section = $2;
    my %section_ids = (
        'Options' => 'acc-options-line',
        'Include in drop-down menus' => 'dropdowns',
    );

    my $page = S->{ext_wsl}->page->body->maindiv->content;
    my @checkboxes = $page->find_all(
        qq{.//div[\@id="$section_ids{$section}"]//input[\@type="checkbox" and \@checked="checked"]}
    );

    is(scalar @checkboxes, $wanted_count, "found $wanted_count selected checkboxes");
};

1;
