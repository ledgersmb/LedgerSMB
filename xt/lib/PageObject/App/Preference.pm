package PageObject::App::Preference;

use strict;
use warnings;

use PageObject;


use Moose;
use namespace::autoclean;
extends 'PageObject';


__PACKAGE__->self_register(
              'app-preference',
              './/div[@id="preferences"]',
              tag_name => 'div',
              attributes => {
                  id => 'preferences',
              });


sub _verify {
    my ($self) = @_;

    $self->find('*labeled', text => $_)
        for ("Date Format", "Number Format", "Language". "Stylesheet");
    return $self;
};



__PACKAGE__->meta->make_immutable;

1;
