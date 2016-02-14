package PageObject::App::Login;

use strict;
use warnings;

use Carp;
use PageObject;


use Moose;
extends 'PageObject';

use PageObject::App;


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
    do {
        my $element = $self->driver->find_element_by_label($_->{label});
        $element->click;
        $element->clear;
        $element->send_keys($_->{value});
    } for ({ label => "User Name",
             value => $user },
           { label => "Password",
             value => $password },
           { label => "Company",
             value => $company });
    $self->driver->find_button("Login")->click;
    return $self->driver->page(PageObject::App->new(%$self));
}



__PACKAGE__->meta->make_immutable;

1;
