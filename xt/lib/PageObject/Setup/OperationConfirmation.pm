package PageObject::Setup::OperationConfirmation;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
use namespace::autoclean;
extends 'PageObject';


__PACKAGE__->self_register(
              'setup-operation-complete',
              './/body[@id="setup-operation-complete"]',
              tag_name => 'body',
              attributes => {
                  id => 'setup-operation-complete',
              });


sub _verify {
    my ($self) = @_;

    my $element =
        $self->find('*contains', text => 'LedgerSMB may now be used');

    croak "Not on the operation confirmation page"
        if ! $element;

    return $self;
}


__PACKAGE__->meta->make_immutable;

1;
