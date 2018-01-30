package PageObject::App::AP::Note;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
use namespace::autoclean;
extends 'PageObject';


__PACKAGE__->self_register(
              'ap-transaction-reverse',
              './/div[@id="AP-transaction-reverse"]',
              tag_name => 'div',
              attributes => {
                  id => 'AP-transaction-reverse',
              });



sub _verify {
    my ($self) = @_;

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;
