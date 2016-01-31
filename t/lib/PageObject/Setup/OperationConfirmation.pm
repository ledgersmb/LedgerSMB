package PageObject::Setup::OperationConfirmation;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
extends 'PageObject';


sub verify {
    my ($self) = @_;
    my $driver = $self->driver;

    my $elements =
        $driver->find_elements_containing_text('LedgerSMB may now be used');

    croak "Not on the operation confirmation page" .scalar(@$elements)
        if scalar(@$elements) != 1;

    return $self;
}


__PACKAGE__->meta->make_immutable;

1;
