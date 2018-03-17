package PageObject::App::Parts::AdjustSearchUnapproved;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
use namespace::autoclean;
extends 'PageObject';

__PACKAGE__->self_register(
              'part-search-unapproved',
              './/form[@id="part-search-unapproved"]',
              tag_name => 'form',
              attributes => {
                  id => 'part-search-unapproved',
              });

sub _verify {
    my ($self) = @_;

    return $self;
}

sub run_report {
    my $self = shift;
    my %args = @_;

    for my $key (keys %args) {
        $self->find('*labeled', text => $key)->send_keys($args{$key});
    }
    $self->find('*button', text => 'Run Report')->click;
    $self->session->page->body->maindiv->wait_for_content;
}



__PACKAGE__->meta->make_immutable;

1;
