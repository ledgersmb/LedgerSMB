#!perl


use strict;
use warnings;

use PageObject::App::Login;

use Test::More;
use Test::BDD::Cucumber::StepFile;

Given qr/a logged in admin/, sub {
    PageObject::App::Login->open(S->{ext_wsl});
    S->{ext_wsl}->page->body->login(
        user => S->{"the admin"},
        password => S->{"the admin password"},
        company => S->{"the company"});
};



1;
