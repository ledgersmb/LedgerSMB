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


When qr/I click on the Batch with Control Number "(.*)"/, sub {
    my $page = S->{ext_wsl}->page->body->maindiv->content;
    my $control_code = $1;

    my $link = $page->batch_link(control_code => $control_code);
    ok($link->click, "clicked batch link with Control Number $control_code");
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


Then qr/I should see the title "(.*)"/, sub {
    my $page = S->{ext_wsl}->page->body->maindiv->content;
    my $title = $1;

    my $div = $page->title(title => $title);
    ok($div, "Found title '$title'");
};


1;
