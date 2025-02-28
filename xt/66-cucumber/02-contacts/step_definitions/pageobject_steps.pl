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


Then qr/^I expect the (.+) table to contain (\d+) rows?$/, sub {
    my $table_name = $1;
    my $wanted_row_count = $2;

    my %table_ids =(
        'Accounts' => 'credit_accounts_list',
        'Bank Accounts' => 'bank_account_list',
    );

    my $table_id = $table_ids{$table_name}
        or die qq{no id defined for "$table_name" table};

    my @rows = S->{ext_wsl}->page->body->maindiv->content->find_all(
        ".//table[\@id='$table_id']/tbody/tr"
    );
    my $row_count = scalar @rows;


    my $page = S->{ext_wsl}->page->body->maindiv->content;


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
    $page->active_pane->find(
        ".//*[\@role='button']/*[text()='$button_text']"
    )->click;
};


When qr/^I enter "(.+)" into the "(.+)" field$/, sub {
    my $text = $1;
    my $field_name = $2;
    my $page = S->{ext_wsl}->page->body->maindiv->content;

    my $label = $page->active_pane->find(
        ".//label[text()='$field_name']"
    );
    my $field_id = $label->get_attribute('for');
    my $field = $page->active_pane->find(
        ".//input[\@id='$field_id']"
    );
    $field->send_keys($text);
};

1;
