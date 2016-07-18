#!perl


use strict;
use warnings;

use Test::More;
use Test::BDD::Cucumber::StepFile;



Then qr/the Balance Sheet per (.{10}) looks like:/, sub {
    my $date = $1;

    S->{ext_wsl}->page->body->menu->click_menu(['Reports', 'Balance Sheet']);
    S->{ext_wsl}->page->body->maindiv->content->run(date => $date);

    my @step_data =
        map { { accno => $_->{accno},
                values => [ $_->{amount} ] } } @{C->data};
    my $actual_data = S->{ext_wsl}->page->body->maindiv
        ->content->account_balances;
    is_deeply($actual_data, \@step_data, 'Balancesheet account balances match');
};



1;
