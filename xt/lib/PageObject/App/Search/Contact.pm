package PageObject::App::Search::Contact;

use strict;
use warnings;

use Carp;
use PageObject::App::Search;

use Moose;
use namespace::autoclean;
extends 'PageObject::App::Search';

__PACKAGE__->self_register(
              'search-contact',
              './/form[@id="search-contact"]',
              tag_name => 'form',
              attributes => {
                  id => 'search-contact',
              });


my $page_heading = 'Contact Search';

sub _verify {
    my ($self) = @_;

    $self->find(".//*[\@class='listtop'
                      and text()='$page_heading']");

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;
