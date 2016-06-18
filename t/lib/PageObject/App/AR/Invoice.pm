package PageObject::App::AR::Invoice;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
extends 'PageObject';

my $page_heading = 'Add Sales Invoice';

sub _verify {
    my ($self) = @_;

    $self->stash->{ext_wsl}->page
        ->find("//*[\@id='maindiv']
                           [.//*[\@class='listtop'
                                 and text()='$page_heading']]");

    return $self;
}

sub select_customer {
    my ($self, $customer) = @_;

    $self->verify;
    my $elem = 
        $self->stash->{ext_wsl}->page->find("*labeled", text => "Customer");

    $elem->clear;
    $elem->send_keys($customer);

    $self->stash->{ext_wsl}->page->find("*button", text => "Update")->click;
}

__PACKAGE__->meta->make_immutable;

1;
