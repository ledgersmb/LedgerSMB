#!perl

use lib 'xt/lib';
use strict;
use warnings;

use Test::More;
use Test::BDD::Cucumber::StepFile;

When qr/I select '(\w+)' as the period$/, sub {
    my $label_text = $1;
    my $page = S->{ext_wsl}->page->body->maindiv;
    my $radio_button = $page->find('*labeled', text => $label_text);
    $radio_button->click;
};

1;
