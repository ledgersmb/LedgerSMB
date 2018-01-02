package PageObject::App::Initial;

use strict;
use warnings;

use PageObject;


use Moose;
use namespace::autoclean;
extends 'PageObject';


__PACKAGE__->self_register(
              'app-main-initial',
              './/div[@id="flicker-container"]',
              tag_name => 'div',
              attributes => {
                  id => 'flicker-container',
              });


sub _verify {
    my ($self) = @_;

    return $self;
};



__PACKAGE__->meta->make_immutable;

1;
