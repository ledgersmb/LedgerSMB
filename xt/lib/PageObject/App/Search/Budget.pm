package PageObject::App::Search::Budget;

use strict;
use warnings;

use Carp;
use PageObject::App::Search;

use Moose;
use namespace::autoclean;
extends 'PageObject::App::Search';


__PACKAGE__->self_register(
              'search-budget',
              './/form[@id="budget-search"]',
              tag_name => 'form',
              attributes => {
                  id => 'budget-search',
              });

sub _verify {
    my ($self) = @_;

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;
