package PageObject::App::Budget;

use strict;
use warnings;

use PageObject;


use Moose;
use namespace::autoclean;
extends 'PageObject';


__PACKAGE__->self_register(
              'app-budget',
              './/div[@id="budgets"]',
              tag_name => 'div',
              attributes => {
                  id => 'budgets',
              });


sub _verify {
    my ($self) = @_;

    return $self;
};



__PACKAGE__->meta->make_immutable;

1;
