package PageObject::App::Search;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
extends 'PageObject';


sub _search_btn_title {
    return 'Search';
}

sub search {
    my $self = shift;
    my %args = @_;

    for my $input (keys %args) {
        $self->find('*labeled', text => $input)
            ->send_keys($args{$input});
    }
    $self->find('*button', text => $self->_search_btn_title)->click;
}

__PACKAGE__->meta->make_immutable;

1;
