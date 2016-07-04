package PageObject::App::AR::Invoice;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
extends 'PageObject';

__PACKAGE__->self_register(
              'ar-invoice',
              './/div[@id="AR-invoice"]',
              tag_name => 'div',
              attributes => {
                  id => 'AR-invoice',
              });



sub _verify {
    my ($self) = @_;

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
