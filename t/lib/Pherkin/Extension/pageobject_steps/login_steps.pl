#!perl


use strict;
use warnings;

use PageObject::App::Login;

use Test::More;
use Test::BDD::Cucumber::StepFile;

Given qr/a logged in admin/, sub {
    PageObject::App::Login->open(stash => S);
    S->{page}->login(
        user => S->{"the admin"},
        password => S->{"the admin password"},
        company => S->{"the company"});
    S->{page}->verify;
};



1;
