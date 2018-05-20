package PageObject::App;

use strict;
use warnings;

use PageObject;


use Moose;
use namespace::autoclean;
extends 'PageObject';


__PACKAGE__->self_register(
              'app',
              './/body[@id="app-main"]',
              tag_name => 'body',
              attributes => {
                  id => 'app-main',
              });


has menu => (is => 'ro',
             isa => 'PageObject',
             builder => '_build_menu',
             lazy => 1);

has maindiv => (is => 'ro',
                isa => 'PageObject',
                builder => '_build_maindiv',
                lazy => 1);

sub _build_menu {
    my ($self) = @_;

    my $menu = $self->find('*app-menu');
    $self->session->wait_for(
        sub {
            my $item = $self->find("//*[\@id='top_menu' and contains(\@class, 'done-parsing')]");
            my $attr = $item->get_attribute('class');
            return $attr =~ 'done-parsing';
        });
    return $menu;
}

sub _build_maindiv {
    my ($self) = @_;

    return $self->find('*app-main');
}


sub _verify {
    my ($self) = @_;

    $self->menu->verify;
    $self->maindiv->verify;

    return $self;
};

sub verify_screen {
    my ($self) = @_;

    my $content = $self->maindiv->content;
    $content->verify;

    return $content;
}

__PACKAGE__->meta->make_immutable;

1;
