package PageObject::App::Cash::PaymentSearch;

use strict;
use warnings;

use Carp;
use PageObject;

use PageObject::App::Cash::PaymentSearchReport;

use Moose;
use namespace::autoclean;
extends 'PageObject';

__PACKAGE__->self_register(
              'payment_search_form',
              './/form[@id="payment_search_form"]',
              tag_name => 'form',
              attributes => {
                  id => 'payment_search_form',
              });


sub _verify {
    my ($self) = @_;

    return $self;
}


__PACKAGE__->meta->make_immutable;

1;
