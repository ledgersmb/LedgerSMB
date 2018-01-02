package PageObject::App::BatchImport;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
use namespace::autoclean;
extends 'PageObject';


__PACKAGE__->self_register(
              'batch-import',
              './/div[@id="batch-import"]',
              tag_name => 'div',
              attributes => {
                  id => 'batch-import',
              });
# __PACKAGE__->self_register(
#               'batch-import',
#               './/div[@id="batch-import"]',
#               tag_name => 'div',
#               attributes => {
#                   id => 'batch-import',
#               });

sub _verify {
    my ($self) = @_;

    $self->find('*labeled', text => $_)
        for ("Reference", "Description", "Transaction Date", "From File");

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;
