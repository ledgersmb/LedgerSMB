package PageObject::App::Orders::Purchase;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
extends 'PageObject';

my $page_heading = 'Add Purchase Order';

sub _verify {
    my ($self) = @_;

    $self->stash->{ext_wsl}->page
        ->find("//*[\@id='maindiv']
                   [.//*[\@class='listtop']
                   [.//*[text()='$page_heading']]]");

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;
