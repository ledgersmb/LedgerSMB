#!perl

use lib 'xt/lib';
use strict;
use warnings;

use Test::More;
use Test::BDD::Cucumber::StepFile;


Then qr/I should see a Batch with these values:/, sub {
    my $page = S->{ext_wsl}->page->body->maindiv->content;
    my $data = C->data;
    my $wanted = shift @{$data};

    ok(
        $page->find_batch_row($wanted),
        'found a payment row with matching values'
    );
};


Then qr/I should see a payment line with these values:/, sub {
    my $page = S->{ext_wsl}->page->body->maindiv->content;
    my $data = C->data;
    my $wanted = shift @{$data};

    ok(
        $page->find_payment_row($wanted),
        'found a payment row with matching values'
    );
};


Then qr/^I should see these Reconciliation Report headings:$/, sub {
    my $data = C->data;
    my $page = S->{ext_wsl}->page->body->maindiv->content;

    foreach my $wanted(@{$data}) {
        ok(
            $page->find_heading($wanted),
            "Found header '$wanted->{Heading}' displaying '$wanted->{Contents}'",
        );
    }
};


When qr/I click on the Batch with Batch Number "(.*)"/, sub {
    my $page = S->{ext_wsl}->page->body->maindiv->content;
    my $batch_number = $1;

    my $link = $page->batch_link(batch_number => $batch_number);
    ok($link->click, "clicked link for Batch Number $batch_number");
};


When qr/I select the payment line with these values:$/, sub {
    my $page = S->{ext_wsl}->page->body->maindiv->content;
    my $data = C->data;
    my $wanted = shift @{$data};

    my $row = $page->find_payment_row($wanted);
    my $checkbox = $row->find('./td[@class="account_number"]/div/input[@type="checkbox"]');
    my $checked = $checkbox->get_attribute('checked');

    $checked && $checked eq 'true' or $checkbox->click();
};


When qr/I select "(Some|All)" on the payment line for "(.*)"$/, sub {
    my $button_label = $1;
    my $vendor = $2;
    my $page = S->{ext_wsl}->page->body->maindiv->content;
    my $wanted = {Name => $vendor};

    my $row = $page->find_payment_row($wanted);
    my $radio_button = $row->find(qq{//input[\@type="radio" and \@title="$button_label"]});

    $radio_button->click;
};


When qr/^I enter "(.*)" into "To Pay" for the invoice from "(.*)" with these values:$/, sub {
    my $amount = $1;
    my $vendor = $2;
    my $page = S->{ext_wsl}->page->body->maindiv->content;
    my $data = C->data;
    my $wanted = shift @{$data};

    my $row = $page->find_invoice_detail_row({
        vendor => $vendor,
        wanted => $wanted,
    });

    my $input_field = $row->find(
        './td[@class="to_pay_list"]/div/div/input[contains(@name, "payment_")]'
    );

    $input_field->click;
    $input_field->clear;
    $input_field->send_keys($amount);
};


When qr/^I change the "Ending Statement Balance" to "(.*)"$/, sub {
    my $amount = $1;
    my $page = S->{ext_wsl}->page->body->maindiv->content;

    my $input = $page->find('//input[@id="their-total"]')
        or die 'failed to find input field for Ending Statement Balance';

    $input->clear;
    $input->send_keys($amount);
};


Then qr/^I expect to see the Invoice Detail table for "(.*)"$/, sub {
    my $vendor = $1;
    my $page = S->{ext_wsl}->page->body->maindiv->content;
    my $wanted = {Name => $vendor};
    my $detail_table = $page->find_invoice_detail_table($wanted);
    ok($detail_table, "found invoice detail table for vendor $vendor");
};


Then qr/^I expect to see the "Contact Total" of "(.*)" for "(.*)"$/, sub {
    my $amount = $1;
    my $vendor = $2;
    my $page = S->{ext_wsl}->page->body->maindiv->content;
    my $wanted = {Name => $vendor};
    my $detail_table = $page->find_invoice_detail_table($wanted);
    my $contact_total = $detail_table->find('./tfoot/tr/td[span[@class="currency"]]');

    is($contact_total->get_text, $amount, 'contact total amount matches');
};


Then qr/^I should see an invoice from "(.*)" with these values:$/, sub {
    my $vendor = $1;
    my $page = S->{ext_wsl}->page->body->maindiv->content;
    my $data = C->data;
    my $wanted = shift @{$data};

    my $row = $page->find_invoice_detail_row({
        vendor => $vendor,
        wanted => $wanted,
    });

    ok($row, 'found matching invoice detail row');
};


Then qr/I should see the title "(.*)"/, sub {
    my $page = S->{ext_wsl}->page->body->maindiv->content;
    my $title = $1;

    my $div = $page->title(title => $title);
    ok($div, "Found title '$title'");
};


1;
