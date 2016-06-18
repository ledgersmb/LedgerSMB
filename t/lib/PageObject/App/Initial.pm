package PageObject::App::Initial;

use strict;
use warnings;

use Carp;
use PageObject;


use Moose;
extends 'PageObject';



sub _verify {
    my ($self) = @_;
    my $driver = $self->stash->{ext_wsl}->page;

    $driver->find("//div[\@id='maindiv']");
    return $self;
};



__PACKAGE__->meta->make_immutable;

1;
