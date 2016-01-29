package PageObject::Setup::Main;

use strict;
use warnings;

use Carp;
use Moose;
use PageObject;
extends 'PageObject';

has driver => (is => 'ro', required => 1);


sub verify {
    my ($self) = @_;
    my $driver = $self->driver;

    $driver->find_element_by_label($_)
        for ("Super-user login", "Password", "Database");
    return $self;
};


__PACKAGE__->meta->make_immutable;

1;
