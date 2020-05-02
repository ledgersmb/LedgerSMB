package PageObject::App::FixedAssets::AddClass;

use strict;
use warnings;

use PageObject;


use Moose;
use namespace::autoclean;
extends 'PageObject';


__PACKAGE__->self_register(
              'app-fixedassets-edit-class',
              './/div[@id="assets-edit"]',
              tag_name => 'div',
              attributes => {
                  id => 'assets-edit',
              });


sub _verify {
    my ($self) = @_;

    return $self;
};



__PACKAGE__->meta->make_immutable;

1;
