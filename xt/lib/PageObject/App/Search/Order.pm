package PageObject::App::Search::Order;

use strict;
use warnings;

use Carp;
use PageObject::App::Search;

use Moose;
use namespace::autoclean;
extends 'PageObject::App::Search';

__PACKAGE__->self_register(
              'search-orders',
              './/form[@id="search-orders"]',
              tag_name => 'form',
              attributes => {
                  id => 'search-orders',
              });


sub _verify {
    my ($self) = @_;

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;
