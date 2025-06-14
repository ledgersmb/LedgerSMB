#!perl


use strict;
use warnings;

use Test::More;
use Test::BDD::Cucumber::StepFile;



When qr/I search for part '(.*)'/, sub {
    my $partnumber = $1;
    S->{ext_wsl}->page->body->menu->click_menu(['Goods & Services', 'Search']);
    S->{ext_wsl}->page->body->maindiv->content->search(
        'Part Number' => $partnumber
        );
};


When qr/I create an inventory adjustment dated (.{10,10}) with these counts:/, sub {
    my $date = $1;

    S->{ext_wsl}->page->body->menu->click_menu(
        ['Goods & Services', 'Enter Inventory']
    );
    S->{ext_wsl}->page->body->maindiv->content->set_source('Adjustment Test 1');
    S->{ext_wsl}->page->body->maindiv->content->set_date($date);
    S->{ext_wsl}->page->body->maindiv->content->start_adjustment;

    S->{'the inventory adjustment source'} = 'Adjustment Test 1';
    S->{'the inventory adjustment date'} = $date;

    foreach my $row (@{C->data}) {
        S->{ext_wsl}->page->body->maindiv->content->add_row(%$row);
    }
    S->{ext_wsl}->page->body->maindiv->content->save;
};

When qr/I approve the inventory adjustment/, sub {
    S->{ext_wsl}->page->body->menu->click_menu(
        [ 'Transaction Approval', 'Inventory' ]
    );
    S->{ext_wsl}->page->body->maindiv->content->run_report(
        'Source' => S->{'the inventory adjustment source'},
        'From' => S->{'the inventory adjustment date'},
        'To' => S->{'the inventory adjustment date'}
    );
    my $link_text = S->{'the inventory adjustment source'};
    my $btn = S->{ext_wsl}->page->body->maindiv->content
        ->find(qq|.//a[text()="$link_text"]|);
    $btn->click;
    S->{ext_wsl}->page->body->maindiv->wait_for_content(replaces => $btn);
    $btn = S->{ext_wsl}->page->body->maindiv->content
        ->find('*button', text => 'Approve');
    $btn->click;
    S->{ext_wsl}->page->body->maindiv->wait_for_content(replaces => $btn);
};

1;
