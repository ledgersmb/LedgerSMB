package PageObject::App::Initial;

use strict;
use warnings;

use PageObject;


use Moose;
use namespace::autoclean;
extends 'PageObject';


__PACKAGE__->self_register(
              'app-main-initial',
              './/div[@id="welcome"]',
              tag_name => 'div',
              attributes => {
                  id => 'welcome',
              });


sub _verify {
    my ($self) = @_;

    return $self;
};



__PACKAGE__->meta->make_immutable;

1;
