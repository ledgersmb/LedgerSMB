#!perl

use lib 'xt/lib';
use strict;
use warnings;

use Test::More;
use Test::BDD::Cucumber::StepFile;

Then qr/^I expect the "(.+)" tab to be selected$/, sub {
    my $tab_label = $1;
    my $page = S->{ext_wsl}->page->body->maindiv->content;
    ok($page->tab_is_selected($tab_label), "$tab_label tab is selected");
};


Then qr/^I expect the Accounts table to contain (\d+) rows?$/, sub {
    my $wanted_row_count = $1;
    my @rows = S->{ext_wsl}->page->body->maindiv->content->find_all(
        './/table[@id="credit_accounts_list"]/tbody/tr'
    );
    my $row_count = scalar @rows;

    is($row_count, $wanted_row_count, "Accounts table contains $wanted_row_count rows");
};


# Overriding this action to cope with multiple buttons having the same label
# being loaded on the page, but hidden in an invisible tab pane. We want to
# press the button that is visible and ignore those that are hidden.
# An example is the 'Add Entity' screen, which has a 'Save' button on both
# 'Company' and 'Person' tabs, only one of which is visible at a time.
When qr/^I press "(.+)"$/, sub {
    my $button_text = $1;
    my $page = S->{ext_wsl}->page->body->maindiv->content;
    my $active_pane = $page->find(
        './/div[@role="tabpanel" and contains(@class,"dijitVisible")]'
    );
    $active_pane->find(
        ".//*[\@role='button']/*[text()='$button_text']"
    )->click;
};

1;
