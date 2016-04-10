package PageObject::App::Orders::Sales;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
extends 'PageObject';

my $page_heading = 'Add Sales Order';

sub verify {
    my ($self) = @_;

    $self->driver
        ->find_element("//*[\@id='maindiv']
                           [.//*[\@class='listtop']
                                [.//*[text()='$page_heading']]]");

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;
