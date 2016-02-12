package PageObject::App;

use strict;
use warnings;

use Carp;
use PageObject;


use Moose;
extends 'PageObject';

use PageObject::App::Main;
use PageObject::App::Menu;

has driver => (is => 'ro', required => 1);

has menu => (is => 'ro', builder => '_build_menu', lazy => 1);
has maindiv => (is => 'ro', builder => '_build_maindiv', lazy => 1);

sub _build_menu { return PageObject::App::Menu->new(%{(shift)}); }
sub _build_maindiv { return PageObject::App::Main->new(%{(shift)}); }


sub verify {
    my ($self) = @_;
    my $driver = $self->driver;

    $self->menu->verify;
    $self->maindiv->verify;

    return $self;
};



__PACKAGE__->meta->make_immutable;

1;
