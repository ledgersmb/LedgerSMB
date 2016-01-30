package PageObject::Setup::EditUser;

use strict;
use warnings;

use Carp;
use Moose;
use PageObject;
extends 'PageObject';


use PageObject::Setup::OperationConfirmation;


sub verify {
    my ($self) = @_;
    my $driver = $self->driver;

    $driver->find_element_by_label($_)
        for ("Password",
             # mention some role names; we want to verify they're there
             "account all",
             "employees manage",
        );

    $driver->find_button($_)
        for ("Reset Password", "Save Groups");

    return $self;
}


__PACKAGE__->meta->make_immutable;

1;
