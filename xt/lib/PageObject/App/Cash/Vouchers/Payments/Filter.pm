package PageObject::App::Cash::Vouchers::Payments::Filter;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
use namespace::autoclean;
extends 'PageObject';

__PACKAGE__->self_register(
              'cash-vouchers-payments-filter',
              './/div[@id="payments-filter"]',
              tag_name => 'div',
              attributes => {
                  id => 'payments-filter',
              });


# title ()
#
# Returns the page title div with content matching the specified
# `title` parameter
# Normally contains text "Filtering Payments"

sub title {
    my $self = shift;
    my %params = @_;
    my $title = $self->find(sprintf(
        './div[@class="listtop" and normalize-space(.)="%s"]',
        $params{title},
    ));
    return $title
}


sub _verify {
    my ($self) = @_;

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;
