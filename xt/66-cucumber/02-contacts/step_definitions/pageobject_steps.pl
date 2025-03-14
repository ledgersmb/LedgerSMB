#!perl

use lib 'xt/lib';
use strict;
use warnings;

use Test::More;
use Test::BDD::Cucumber::StepFile;
use PageObject::App::Contacts::EditContact;

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
        'Contact Information' => 'contact-list',
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
    $page->find(
        ".//*[\@role='button' ".
        "and not(ancestor::*[contains(\@class, 'dijitHidden')])]".
        "/*[text()='$button_text']"
    )->click;
};


# Overriding this action to cope with multiple fields having the same label
# being loaded on the page, but hidden in an invisible tab pane. We want to
# use the field that is visible and ignore those that are hidden.
Then qr/^I expect the "(.*)" field to contain "(.*)"$/, sub {
    my $field_name = $1;
    my $value = $2;
    my $page = S->{ext_wsl}->page->body->maindiv->content;

    my $label = $page->find(
        ".//label[text()='$field_name' ".
        "and not(ancestor::*[contains(\@class, 'dijitHidden')])]"
    );
    ok($label, "found label element with label '$field_name'");

    my $field_id = $label->get_attribute('for');
    my $field = $page->find(
        ".//input[\@id='$field_id']"
    );

    ok($field, "found input element with label '$field_name'");
    is($field->value, $value, "element with label '$field_name' contains '$value'");
};


When qr/^I enter "(.+)" into the "(.+)" field$/, sub {
    my $text = $1;
    my $field_name = $2;
    my $page = S->{ext_wsl}->page->body->maindiv->content;

    my $label = $page->find(
        ".//label[text()='$field_name' ".
        "and not(ancestor::*[contains(\@class, 'dijitHidden')])]"
    );
    ok($label, "found label element with label '$label'");

    my $field_id = $label->get_attribute('for');
    my $field = $page->find(
        ".//input[\@id='$field_id']"
    );

    $field->clear;
    $field->send_keys($text);
};


1;
