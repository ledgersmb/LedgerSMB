package PageObject::App::FixedAssets::Search;

use strict;
use warnings;

use PageObject;


use Moose;
use namespace::autoclean;
extends 'PageObject';


__PACKAGE__->self_register(
              'app-fixedassets-search',
              './/div[@id="asset-search"]',
              tag_name => 'div',
              attributes => {
                  id => 'asset-search',
              });


sub _verify {
    my ($self) = @_;

    return $self;
};



__PACKAGE__->meta->make_immutable;

1;
