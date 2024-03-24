package PageObject::App::Search::Employee;

use strict;
use warnings;

use Carp;
use PageObject::App::Search;

use Moose;
use namespace::autoclean;
extends 'PageObject::App::Search';

__PACKAGE__->self_register(
              'search-employee',
              './/form[@id="search-employee"]',
              tag_name => 'form',
              attributes => {
                  id => 'search-employee',
              });


my $page_heading = 'Employee Search';

sub _verify {
    my ($self) = @_;

    $self->find(".//*[\@class='listtop'
                      and text()='$page_heading']");

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;
