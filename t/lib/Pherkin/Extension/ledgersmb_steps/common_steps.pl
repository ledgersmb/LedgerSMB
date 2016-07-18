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

Given qr/(a nonexistent|an existing) company named "(.*)"/, sub {
    my $company = $2;
    S->{"the company"} = $company;
    S->{"nonexistent company"} = ($1 eq 'a nonexistent');

    S->{ext_lsmb}->ensure_nonexisting_company($company)
        if S->{'nonexistent company'};
};

Given qr/(a nonexistent|an existing) user named "(.*)"/, sub {
    my $role = $2;
    S->{"the user"} = $role;
    S->{'nonexistent user'} = ($1 eq 'a nonexistent');

    S->{ext_lsmb}->ensure_nonexisting_user($role)
        if S->{'nonexistent user'};
};

Given qr/books closed as per (.{10})/, sub {
    my $closing_date = $1;

    my $dbh = S->{ext_lsmb}->admin_dbh;
    $dbh->do("SELECT eoy_reopen_books_at(?)", {}, $closing_date)
        or die $dbh->errstr;
    $dbh->do("SELECT eoy_create_checkpoint(?)", {}, $closing_date)
        or die $dbh->errstr;
};

Then qr/I can't post a transaction on (.{10})/, sub {
    my $posting_date = $1;

    S->{ext_lsmb}->assert_closed_posting_date($posting_date);
};

Given qr/the following GL transaction posted on (.{10})/, sub {
    S->{ext_lsmb}->post_transaction($1, C->data);
};

When qr/I post the following GL transaction on (.{10})/, sub {
    S->{ext_lsmb}->post_transaction($1, C->data);
};


1;
