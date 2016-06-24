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
    my ($self, %args) = @_;
    my $user = $args{user};
    my $password = $args{password};
    my $company = $args{company};
    my $next_page = $args{next_page} //
        "PageObject::Setup::Admin";

    $self->stash->{page}->find('*labeled',
                               text => 'Super-user login')
        ->click;
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

    return $self->stash->{page} = $next_page->new(%$self)
        ->verify($btn);
}

sub login_non_existent {
    my $self = shift @_;

    return $self->login(@_,
        next_page => "PageObject::Setup::CreateConfirm");
}


__PACKAGE__->meta->make_immutable;

1;
