package PageObject::App::AP::Invoice;

use strict;
use warnings;

use Carp;
use PageObject;
use PageObject::App::Invoices::Lines;
use PageObject::App::Invoices::Header;
use PageObject::App::Invoices::Payments;

use Moose;
use namespace::autoclean;
extends 'PageObject::App::Invoice';

__PACKAGE__->self_register(
              'ap-invoice',
              './/div[@id="AP-invoice"]',
              tag_name => 'div',
              attributes => {
                  id => 'AP-invoice',
              });

sub _verify {
    my ($self) = @_;

    return $self;
}

sub select_vendor {
    my ($self, $vendor) = @_;

    $self->verify;
    my $elem = $self->find("*labeled", text => "Vendor");

    $elem->clear;
    $elem->send_keys($vendor);

    $self->update;
}


__PACKAGE__->meta->make_immutable;

1;
