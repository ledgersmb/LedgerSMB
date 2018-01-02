package PageObject::App::Parts::AdjustSetup;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
use namespace::autoclean;
extends 'PageObject';

use PageObject::App::Parts::Adjust;


__PACKAGE__->self_register(
              'part-adjust-setup',
              './/form[@id="part-adjust-setup"]',
              tag_name => 'form',
              attributes => {
                  id => 'part-adjust-setup',
              });


sub start_adjustment {
    my $self = shift;

    $self->find('*button', text => 'Continue')->click;
    $self->session->page->body->maindiv->wait_for_content;
}

sub set_date {
    my ($self, $date) = @_;

    $self->find('*text', id => 'transdate')->send_keys($date);
}

sub set_source {
    my ($self, $source) = @_;

    $self->find('*text', id => 'source')->send_keys($source);
}

sub _verify {
    my ($self) = @_;

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;
