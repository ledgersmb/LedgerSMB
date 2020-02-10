package PageObject::App::Search::ReportDynatable;


use strict;
use warnings;

use Moose;
use namespace::autoclean;
extends 'PageObject';
with 'PageObject::App::Roles::Dynatable';

__PACKAGE__->self_register(
              'search-report-dynatable',
              './/form[@id="search-report-dynatable"]',
              tag_name => 'form',
              attributes => {
                  id => 'search-report-dynatable',
              });


sub _verify {
    my ($self) = @_;

    $self->stash->{ext_wsl}->page
        ->find('//form[@id="search-report-dynatable"]');

    return $self;
}


__PACKAGE__->meta->make_immutable;

1;
