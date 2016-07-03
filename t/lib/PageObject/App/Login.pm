package PageObject::App::Login;

use strict;
use warnings;

use Carp;
use PageObject;


use Moose;
extends 'PageObject';


sub url { return '/login.pl'; }

__PACKAGE__->self_register(
              'app-login',
              './/body[@id="app-login"]',
              tag_name => 'body',
              attributes => {
                  id => 'app-login',
              });



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
        my $element =
            $self->stash->{ext_wsl}->page->find('*labeled',
                                                text => $_->{label});
        $element->click;
        $element->clear;
        $element->send_keys($_->{value});
    } for ({ label => "User Name",
             value => $user },
           { label => "Password",
             value => $password },
           { label => "Company",
             value => $company });
    $self->stash->{ext_wsl}->page->find('*button', text => "Login")->click;
    return $self->stash->{page} = PageObject::App->new(%$self);
}



__PACKAGE__->meta->make_immutable;

1;
