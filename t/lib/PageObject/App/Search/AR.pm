package PageObject::App::Search::AR;

use strict;
use warnings;

use Carp;
use PageObject::App::Search;

use Moose;
extends 'PageObject::App::Search';

my $page_heading = 'Search AR Invoices';

sub verify {
    my ($self) = @_;

    $self->driver
        ->find_element("//*[\@id='maindiv']
                           [.//*[\@class='listtop'
                                 and text()='$page_heading']]");

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;
