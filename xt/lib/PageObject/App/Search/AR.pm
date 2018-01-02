package PageObject::App::Search::AR;

use strict;
use warnings;

use Carp;
use PageObject::App::Search;

use Moose;
use namespace::autoclean;
extends 'PageObject::App::Search';

__PACKAGE__->self_register(
              'search-ar-invoice',
              './/form[@id="search-ar-invoice"]',
              tag_name => 'form',
              attributes => {
                  id => 'search-ar-invoice',
              });

my $page_heading = 'Search AR Invoices';

sub _verify {
    my ($self) = @_;

    $self->find(".//*[\@class='listtop'
                      and text()='$page_heading']");

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;
