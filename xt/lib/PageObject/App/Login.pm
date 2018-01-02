package PageObject::App::Login;

use strict;
use warnings;

use Carp;
use PageObject;


use Moose;
use namespace::autoclean;
extends 'PageObject';


__PACKAGE__->self_register(
              'app-login',
              './/body[@id="app-login"]',
              tag_name => 'body',
              attributes => {
                  id => 'app-login',
              });


sub url { return '/login.pl'; }

sub _verify {
    my ($self) = @_;

    $self->find('*labeled', text => $_)
        for ("User Name", "Password", "Company");
    return $self;
};


sub login {
    my ($self, %args) = @_;
    my $user = $args{user};
    my $password = $args{password};
    my $company = $args{company};
    do {
        my $element = $self->find('*labeled', text => $_->{label});
        $element->click;
        $element->clear;
        $element->send_keys($_->{value});
    } for ({ label => "User Name",
             value => $user },
           { label => "Password",
             value => $password },
           { label => "Company",
             value => $company });
    $self->find('*button', text => "Login")->click;
    return $self->session->page->wait_for_body;
}



__PACKAGE__->meta->make_immutable;

1;
