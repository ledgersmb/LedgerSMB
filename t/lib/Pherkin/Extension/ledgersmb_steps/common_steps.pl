#!perl


use strict;
use warnings;

use Test::More;
use Test::BDD::Cucumber::StepFile;


my $company_seq = 0;

Given qr/a (fresh )?standard test company/, sub {
    my $fresh_required = $1;

    S->{ext_lsmb}->ensure_template;
    
    if (! S->{"the company"} || $fresh_required) {
        my $company = "standard-" . $company_seq++;
        S->{ext_lsmb}->create_from_template($company);
    }
};

Given qr/(a non-existent|an existing) company named "(.*)"/, sub {
    my $company = $2;
    S->{"the company"} = $company;
    S->{"non-existent"} = ($1 eq 'a non-existent');

    S->{ext_lsmb}->ensure_nonexisting_company($company)
        if S->{'non-existent'};
};

Given qr/a non-existent user named "(.*)"/, sub {
    my $role = $1;
    S->{"the user"} = $role;

    S->{ext_lsmb}->ensure_nonexisting_user($role);
};


1;
