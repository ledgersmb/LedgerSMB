package PageObject::App::Initial;

use strict;
use warnings;

use Carp;
use PageObject;


use Moose;
extends 'PageObject';



sub verify {
    my ($self) = @_;
    my $driver = $self->driver;

    $driver->find_element("//div[\@id='maindiv']");
    return $self;
};



__PACKAGE__->meta->make_immutable;

1;
