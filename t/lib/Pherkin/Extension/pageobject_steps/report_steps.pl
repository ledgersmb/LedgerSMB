#!perl


use strict;
use warnings;

use Test::More;
use Test::BDD::Cucumber::StepFile;



Then qr/the Balance Sheet per (.{10}) looks like:/, sub {
    my $date = $1;

    S->{page}->menu->click_menu(['Reports', 'Balance Sheet']);
    S->{page}->maindiv->content->run(date => $date);

    my @step_data =
        map { { accno => $_->{accno},
                values => [ $_->{amount} ] } } @{C->data};
    my $actual_data = S->{page}->maindiv->content->account_balances;
    is_deeply($actual_data, \@step_data, 'Balancesheet account balances match');
};



1;
