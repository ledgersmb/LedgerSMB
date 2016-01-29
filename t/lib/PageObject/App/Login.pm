package PageObject::App::Login;

use strict;
use warnings;

use Carp;
use PageObject;


use Moose;
extends 'PageObject';



has driver => (is => 'ro', required => 1);

sub url { return '/login.pl'; }

sub verify {
    my ($self) = @_;
    my $driver = $self->driver;

    $driver->find_element_by_label($_)
        for ("User Name", "Password", "Company");
    return $self;
};


sub login {
    my ($self, $user, $password, $company) = @_;
    $self->driver->find_element_by_label("Super-user login")->click;
    do {
        my $element = $self->driver->find_element_by_label($_->{label});
        $element->click;
        $element->send_keys($_->{value});
    } for ({ label => "Super-user login",
             value => $user },
           { label => "Password",
             value => $password },
           { label => "Database",
             value => $company });
    $self->driver->find_button("Login")->click;
    return $self->driver->page(PageObject::Setup::Main->new(%$self));
}

sub login_non_existent {
    my $self = shift @_;

    $self->login(@_);
    return $self->driver->page(PageObject::Setup::CreateConfirm->new(%$self));
}


__PACKAGE__->meta->make_immutable;

1;
