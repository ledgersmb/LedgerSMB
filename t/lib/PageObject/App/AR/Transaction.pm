package PageObject::App::AR::Transaction;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
extends 'PageObject';

my $page_heading = 'Add AR Transaction';

sub _verify {
    my ($self) = @_;

    $self->driver
        ->find_element("//*[\@id='maindiv']
                           [.//*[\@class='listtop'
                                 and text()='$page_heading']]");

    return $self;
}

sub select_customer {
    my ($self, $customer) = @_;

    $self->verify;
    my $elem = 
        $self->driver->find_element_by_label("Customer");

    $elem->clear;
    $elem->send_keys($customer);

    $self->driver->find_button("Update")->click;
}



__PACKAGE__->meta->make_immutable;

1;
