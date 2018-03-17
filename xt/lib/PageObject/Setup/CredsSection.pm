package PageObject::Setup::CredsSection;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
use namespace::autoclean;
extends 'PageObject';

__PACKAGE__->self_register(
              'setup-credentials-section',
              './/table[@id="credentials"]',
              tag_name => 'table',
              attributes => {
                  id => 'credentials',
              });


sub _verify {
    my ($self) = @_;

    ###TODO

    return $self;
};

sub username {
    my ($self) = @_;

    return $self->find('.//*[@id="username"]')->get_text;
}

sub database {
    my ($self) = @_;

    return $self->find('.//*[@id="databasename"]')->get_text;
}


__PACKAGE__->meta->make_immutable;

1;
