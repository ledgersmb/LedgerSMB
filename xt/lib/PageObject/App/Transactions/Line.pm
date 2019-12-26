package PageObject::App::Transactions::Line;

use strict;
use warnings;

use Carp;
use PageObject;


use Moose;
use namespace::autoclean;
extends 'PageObject';

use PageObject::App;

__PACKAGE__->self_register(
              'transaction-line',
              './/tr[contains(@class,"transaction-line")]',
              tag_name => 'tr',
              attributes => {
                  'class' => 'transaction-line',
              });

sub _verify {
    my ($self) = @_;

    ###TODO

    return $self;
};



__PACKAGE__->meta->make_immutable;

1;
