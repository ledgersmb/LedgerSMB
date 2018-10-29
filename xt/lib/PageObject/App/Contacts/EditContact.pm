package PageObject::App::Contacts::EditContact;

use strict;
use warnings;

use Carp;
use PageObject;
use Moose;
use namespace::autoclean;
extends 'PageObject';

__PACKAGE__->self_register(
    'edit_contact',
    './/div[@id="edit_contact"]',
    tag_name => 'div',
    attributes => {
        id => 'edit_contact',
    }
);

sub _verify {
    my ($self) = @_;
    return $self;
}


__PACKAGE__->meta->make_immutable;
1;
