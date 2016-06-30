package PageObject::App::Closing;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
extends 'PageObject';


sub _verify {
    my ($self) = @_;

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;
