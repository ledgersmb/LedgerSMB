#!perl


use lib 'xt/lib';
use strict;
use warnings;


use Test::More;
use Test::BDD::Cucumber::StepFile;



###############
#
# Setup steps
#
###############


When qr/I confirm database creation with these parameters:/, sub {
    my $data = C->data;
    my %data;

    $data{$_->{'parameter name'}} = $_->{value} for @$data;
    S->{ext_wsl}->page->body->create_database(%data);
};

When qr/I log into ("(.*)"|(.*)) using the super-user credentials/, sub {
    my $company = $2 || S->{$3};

    if (S->{"nonexistent company"}) {
        S->{page}->login_non_existent(
            user => $ENV{PGUSER},
            password => $ENV{PGPASSWORD},
            company => $company);
    }
    else {
        S->{page}->login(
            user => $ENV{PGUSER},
            password => $ENV{PGPASSWORD},
            company => $company);
    }
};

When qr/I create a user with these values:/, sub {
    my $data = C->data;
    my %data;

    $data{$_->{'label'}} = $_->{value} for @$data;
    S->{ext_wsl}->page->body->create_user(%data);
};

When qr/I request the users list/, sub {
    S->{ext_wsl}->page->body->list_users;
};

When qr/I request to add a user/, sub {
    S->{ext_wsl}->page->body->add_user;
};

Then qr/I should see the table of available users:/, sub {
    my @data = map { $_->{'Username'} } @{ C->data };
    my $users = S->{ext_wsl}->page->body->get_users_list;

    is_deeply($users, \@data, "Users on page correspond with expectation");
};

When qr/I copy the company to "(.*)"/, sub {
    my $target = $1;

    S->{ext_wsl}->page->body->copy_company($target);
};

When qr/I request the user overview for "(.*)"/, sub {
    my $user = $1;

    S->{ext_wsl}->page->body->edit_user($user);
};

Then qr/I should see my setup.pl credentials/, sub {
    my $page = S->{ext_wsl}->page->body;

    is($page->creds->username,
       $ENV{PGUSER},
       'Credentials show the super-user');
    is($page->creds->database,
       S->{"the company"},
       'Credentials show the database');
};

Then qr/I should see all permission checkboxes checked/, sub {
    my $page = S->{ext_wsl}->page->body;
    my $checkboxes = $page->get_perms_checkboxes(filter => 'all');
    my $checked_boxes = $page->get_perms_checkboxes(filter => 'checked');

    ok(scalar(@{ $checkboxes }) > 0,
       "there are checkboxes");
    ok(scalar(@{ $checkboxes }) == scalar(@{ $checked_boxes }),
       "all perms checkboxes checked");
};


Then qr/I should see no permission checkboxes checked/, sub {
    my $page = S->{ext_wsl}->page->body;
    my $checked_boxes = $page->get_perms_checkboxes(filter => 'checked');

    ok(0 == scalar(@{ $checked_boxes }),
       "no perms checkboxes checked");
};


Then qr/I should see only these permission checkboxes checked:/, sub {
    my $page = S->{ext_wsl}->page->body;
    my @data = map { $_->{"perms label"} } @{ C->data };
    my $checked_boxes = $page->get_perms_checkboxes(filter => 'checked');

    is(scalar(@{ $checked_boxes }), scalar(@data),
       "Expected number of perms checkboxes checked");
    ok($page->is_checked_perms_checkbox($_),
       "Expect perms checkbox with label '$_' to be checked")
        for (@data);
};



1;
