package PageObject::App::Search::AP;

use strict;
use warnings;

use Carp;
use PageObject::App::Search;

use Moose;
use namespace::autoclean;
extends 'PageObject::App::Search';

__PACKAGE__->self_register(
              'search-ap-invoice',
              './/form[@id="search-ap-invoice"]',
              tag_name => 'form',
              attributes => {
                  id => 'search-ap-invoice',
              });

my $page_heading = 'Search AP Invoices';

sub _verify {
    my ($self) = @_;

    $self->find(".//*[\@class='listtop'
                      and text()='$page_heading']");

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;
