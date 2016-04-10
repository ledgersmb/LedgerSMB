package PageObject::App::AP::Note;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
extends 'PageObject';

my $page_heading = 'Add Debit Note';

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
