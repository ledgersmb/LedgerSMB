package PageObject::Setup::Login;

use strict;
use warnings;

use Carp;
use PageObject;

use PageObject::Setup::Admin;
use PageObject::Setup::CreateConfirm;
use Selenium::Remote::WDKeys;

use Moose;
extends 'PageObject';



sub url { return '/setup.pl'; }

sub _verify {
    my ($self) = @_;
    my $stash = $self->stash;

    $stash->{ext_wsl}->page->find('*labeled', text => $_)
        for ("Password", "Database", "Super-user login");
    return $self;
};


sub login {
    my ($self, $user, $password, $company) = @_;
    $self->stash->{page}->find('*labeled', text => 'Super-user login')->click;
    do {
        my $element =
            $self->stash->{page}->find('*labeled', text => $_->{label});
        $element->click;
        $element->send_keys($_->{value});
        $element->send_keys(KEYS->{'tab'}) if defined $_->{list};
    } for ({ label => "Super-user login",
             value => $user,
             list => 1 },
           { label => "Password",
             value => $password },
           { label => "Database",
             value => $company });
    my $btn = $self->stash->{page}->find('*button',
                                         text => "Login");
    $btn->click;

    return $self->stash->{page} =
        PageObject::Setup::Admin->new(%$self)
        ->verify($btn);
}

sub login_non_existent {
    my $self = shift @_;

    $self->login(@_);
    return $self->stash->{page} =
        PageObject::Setup::CreateConfirm->new(%$self);
}


__PACKAGE__->meta->make_immutable;

1;
