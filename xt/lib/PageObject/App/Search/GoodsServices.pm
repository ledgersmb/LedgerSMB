package PageObject::App::Search::GoodsServices;

use strict;
use warnings;

use Carp;
use PageObject::App::Search;

use Moose;
use namespace::autoclean;
extends 'PageObject::App::Search';

use PageObject::App::Search::ReportDynatable;

__PACKAGE__->self_register(
              'search-goods',
              './/form[@id="search-goods"]',
              tag_name => 'form',
              attributes => {
                  id => 'search-goods',
              });




my $page_heading = 'Search Goods and Services';

sub _verify {
    my ($self) = @_;

    $self->stash->{ext_wsl}->page
        ->find("//*[\@id='maindiv']
                           [.//*[\@class='listtop'
                                 and text()='$page_heading']]");

    return $self;
}




__PACKAGE__->meta->make_immutable;

1;
