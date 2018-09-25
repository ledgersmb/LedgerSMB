#!perl

use lib 'xt/lib';
use strict;
use warnings;

use Test::More;
use Test::BDD::Cucumber::StepFile;


When qr/I select "(Approved|Unapproved)"$/, sub {
    my $label_text = $1;
    my $page = S->{ext_wsl}->page->body->maindiv;
    my $radio_button = $page->find(
         qq{//tr[td/label[.="$label_text"]]/td/div/input[\@type="radio"]}
    );
    $radio_button->click;
};

1;
