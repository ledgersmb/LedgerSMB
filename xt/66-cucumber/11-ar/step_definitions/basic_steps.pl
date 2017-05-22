#!perl


use lib 'xt/lib';
use strict;
use warnings;

use Test::More;
use Test::BDD::Cucumber::StepFile;

use Selenium::Remote::Driver;

Given qr/a user named "(.*)" with a password "(.*)"/, sub {
    C->stash->{feature}->{user} = $1;
    C->stash->{feature}->{passwd} = $2;
};

Given qr/a database super-user/, sub {
    C->stash->{feature}->{"the super-user name"} = $ENV{PGUSER};
    C->stash->{feature}->{"the super-user password"} = $ENV{PGPASSWORD};
};

Given qr/a non-existant company name/, sub {
    C->stash->{feature}->{"the company name"} = "non-existant";
    S->{scenario}->{"non-existent"} = 1;
};


1;
