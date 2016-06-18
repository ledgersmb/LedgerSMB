package PageObject::App::AP::Invoice;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
extends 'PageObject';

my $page_heading = 'Add Vendor Invoice';

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
