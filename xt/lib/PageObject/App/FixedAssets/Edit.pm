package PageObject::App::FixedAssets::Edit;

use strict;
use warnings;

use PageObject;


use Moose;
use namespace::autoclean;
extends 'PageObject';


__PACKAGE__->self_register(
              'app-fixedassets-edit',
              './/div[@id="asset-edit"]',
              tag_name => 'div',
              attributes => {
                  id => 'asset-edit',
              });


sub _verify {
    my ($self) = @_;

    return $self;
};



__PACKAGE__->meta->make_immutable;

1;
