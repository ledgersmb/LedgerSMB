package PageObject::App::AR::CreditInvoice;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
extends 'PageObject';

my $page_heading = 'Add Credit Invoice';

sub verify {
    my ($self) = @_;

    $self->driver
        ->find_element("//*[\@id='maindiv']
                           [.//*[\@class='listtop'
                                 and text()='$page_heading']]");

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;
