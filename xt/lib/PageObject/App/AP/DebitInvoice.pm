package PageObject::App::AP::DebitInvoice;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
use namespace::autoclean;
extends 'PageObject';

__PACKAGE__->self_register(
              'ap-invoice-reverse',
              './/div[@id="AP-invoice-reverse"]',
              tag_name => 'div',
              attributes => {
                  id => 'AP-invoice-reverse',
              });

sub _verify {
    my ($self) = @_;

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;
