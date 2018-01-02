package PageObject::App::AR::CreditInvoice;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
use namespace::autoclean;
extends 'PageObject';

__PACKAGE__->self_register(
              'ar-invoice-reverse',
              './/div[@id="AR-invoice-reverse"]',
              tag_name => 'div',
              attributes => {
                  id => 'AR-invoice-reverse',
              });

sub _verify {
    my ($self) = @_;

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;
