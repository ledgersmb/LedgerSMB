package PageObject::App::FixedAssets::SearchClass;

use strict;
use warnings;

use PageObject;


use Moose;
use namespace::autoclean;
extends 'PageObject';


__PACKAGE__->self_register(
              'app-fixedassets-search-class',
              './/div[@id="assetclass-search"]',
              tag_name => 'div',
              attributes => {
                  id => 'assetclass-search',
              });


sub _verify {
    my ($self) = @_;

    return $self;
};



__PACKAGE__->meta->make_immutable;

1;
