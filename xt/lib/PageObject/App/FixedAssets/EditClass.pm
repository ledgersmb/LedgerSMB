package PageObject::App::FixedAssets::EditClass;

use strict;
use warnings;

use PageObject;


use Moose;
use namespace::autoclean;
extends 'PageObject';


__PACKAGE__->self_register(
              'app-fixedassets-edit-class',
              './/div[@id="assetclass-edit"]',
              tag_name => 'div',
              attributes => {
                  id => 'assetclass-edit',
              });


sub _verify {
    my ($self) = @_;

    return $self;
};



__PACKAGE__->meta->make_immutable;

1;
