package PageObject::App::AP::Invoice;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
use namespace::autoclean;
extends 'PageObject';

__PACKAGE__->self_register(
              'ap-invoice',
              './/div[@id="AP-invoice"]',
              tag_name => 'div',
              attributes => {
                  id => 'AP-invoice',
              });

sub _verify {
    my ($self) = @_;

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;
