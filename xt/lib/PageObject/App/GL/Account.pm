package PageObject::App::GL::Account;

use strict;
use warnings;

use Carp;
use PageObject;
use Moose;
use namespace::autoclean;
extends 'PageObject';

__PACKAGE__->self_register(
    'account',
    './/div[@id="account-tabs"]',
    tag_name => 'div',
    attributes => {
        id => 'account-tabs',
    }
);

sub _verify {
    my ($self) = @_;

    return $self;
}


__PACKAGE__->meta->make_immutable;
1;
