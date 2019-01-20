package PageObject::App::AR::PurchaseHistorySearch;

use strict;
use warnings;

use Carp;
use PageObject;
use Moose;
use namespace::autoclean;
extends 'PageObject';

__PACKAGE__->self_register(
    'transactionapproval-batches',
    './/div[@id="purchase_history_search"]',
    tag_name => 'div',
    attributes => {
        id => 'purchase_history_search',
    }
);


sub _verify {
    my ($self) = @_;

    return $self;
}


__PACKAGE__->meta->make_immutable;
1;
