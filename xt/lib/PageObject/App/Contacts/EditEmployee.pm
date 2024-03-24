package PageObject::App::Contacts::EditEmployee;

use strict;
use warnings;

use Carp;
use PageObject;
use Moose;
use namespace::autoclean;
extends 'PageObject';

__PACKAGE__->self_register(
    'edit_employee',
    './/div[@id="edit_employee"]',
    tag_name => 'div',
    attributes => {
        id => 'edit_employee',
    }
);

sub _verify {
    my ($self) = @_;
    return $self;
}


__PACKAGE__->meta->make_immutable;
1;
