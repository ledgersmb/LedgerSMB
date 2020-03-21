package PageObject::App::Cash::PaymentSearchReport;

use strict;
use warnings;

use Carp;
use PageObject;


use Moose;
use namespace::autoclean;
extends 'PageObject';
with 'PageObject::App::Roles::Dynatable';

__PACKAGE__->self_register(
              'search-report-dynatable',
              './/form[@id="search-report-dynatable"]',
              tag_name => 'form',
              attributes => {
                  id => 'search-report-dynatable',
              });


sub _verify {
    my ($self) = @_;

    return $self;
}


__PACKAGE__->meta->make_immutable;

1;
