package PageObject::App::Search::GL;

use strict;
use warnings;

use Carp;
use PageObject::App::Search;

use Moose;
use namespace::autoclean;
extends 'PageObject::App::Search';

__PACKAGE__->self_register(
              'search-gl',
              './/form[@id="search-gl"]',
              tag_name => 'form',
              attributes => {
                  id => 'search-gl',
              });

sub _verify {
    my ($self) = @_;

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;
