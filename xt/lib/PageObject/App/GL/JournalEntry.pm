package PageObject::App::GL::JournalEntry;

use strict;
use warnings;

use Carp;
use PageObject;
use Moose;
use namespace::autoclean;
extends 'PageObject';

__PACKAGE__->self_register(
    'journal-entry',
    './/div[@id="journal-entry"]',
    tag_name => 'div',
    attributes => {
        id => 'journal-entry',
    }
);

sub _verify {
    my ($self) = @_;

    return $self;
}


__PACKAGE__->meta->make_immutable;
1;
