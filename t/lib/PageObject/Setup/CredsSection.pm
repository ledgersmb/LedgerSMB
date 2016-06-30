package PageObject::Setup::CredsSection;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
extends 'PageObject';

has element => (is => 'ro');

sub _verify {
    my ($self) = @_;

    ###TODO

    return $self;
};

sub username {
    my ($self) = @_;

    return $self->element->find('.//*[@id="username"]')->get_text;
}

sub database {
    my ($self) = @_;

    return $self->element->find('.//*[@id="databasename"]')->get_text;
}


__PACKAGE__->meta->make_immutable;

1;
