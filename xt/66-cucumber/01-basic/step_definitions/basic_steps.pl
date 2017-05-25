#!perl


use lib 'xt/lib';
use strict;
use warnings;

use Test::More;
use Test::BDD::Cucumber::StepFile;

use Selenium::Remote::Driver;

Given qr/a user named "(.*)" with a password "(.*)"/, sub {
    # note: the LedgerSMB extension has a *very* similar pattern!
    C->stash->{feature}->{user} = $1;
    C->stash->{feature}->{passwd} = $2;
};

Given qr/a database super-user/, sub {
    C->stash->{feature}->{"the super-user name"} = $ENV{PGUSER};
    C->stash->{feature}->{"the super-user password"} = $ENV{PGPASSWORD};
};

# Given qr/a nonexistent company named/, sub {
#     C->stash->{feature}->{"the company name"} = "nonexistent";
#     S->{scenario}->{"nonexistent"} = 1;
# };


1;
