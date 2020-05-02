#!perl


use strict;
use warnings;

use PageObject::App::Login;

use Test::More;
use Test::BDD::Cucumber::StepFile;


Given qr/a logged in admin/, sub {
    if (S->{ext_wsl}->state ne 'started') {
        PageObject::App::Login->open(S->{ext_wsl});
        S->{ext_wsl}->page->body->login(
            user => S->{"the admin"},
            password => S->{"the admin password"},
            company => S->{"the company"});
        S->{"the user"} = S->{"the admin"};
    }
    else {
        S->{ext_wsl}->page->body->menu->close_menus;
    }
};



1;
