package PageObject::App::Search::Reconciliation;

use strict;
use warnings;

use PageObject::App::Search;

use Moose;
use namespace::autoclean;
extends 'PageObject::App::Search';

__PACKAGE__->self_register(
    'search-reconciliation',
    './/div[@id="reconciliation_report_search"]',
    tag_name => 'div',
    attributes => {
        id => 'reconciliation_report_search',
    }
);


sub _verify {
    my ($self) = @_;

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;
