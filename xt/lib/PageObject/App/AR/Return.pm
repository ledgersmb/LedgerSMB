package PageObject::App::AR::Return;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
use namespace::autoclean;
extends 'PageObject';
__PACKAGE__->self_register(
              'ar-customer-return',
              './/div[@id="AR-invoice-reverse"]',
              tag_name => 'form',
              attributes => {
                  id => 'AR-invoice-reverse',
              });

my $page_heading = 'Add Customer Return';

sub _verify {
    my ($self) = @_;

    $self->find(".//*[\@class='listtop'
                      and text()='$page_heading']");

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;
