package PageObject::App::Closing;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
extends 'PageObject';


sub _verify {
    my ($self) = @_;

    my @tabs = 
    $self->stash->{ext_wsl}->page->find("*labeled", text => $_)
        for ("Reference", "Description", "Transaction Date", "From File");

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;
