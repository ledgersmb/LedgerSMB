package PageObject::App::Parts::Adjust;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
use namespace::autoclean;
extends 'PageObject';

__PACKAGE__->self_register(
              'part-adjust',
              './/form[@id="part-adjust"]',
              tag_name => 'form',
              attributes => {
                  id => 'part-adjust',
              });

sub _verify {
    my ($self) = @_;

    return $self;
}

sub rowcount {
    my $self = shift;

    return $self->find('.//input[@id="rowcount"]')->get_attribute('value');
}

sub add_row {
    my $self = shift;
    my %args = @_;
    my $row = $self->rowcount;

    $self->find('*text', id => "partnumber-$row")->send_keys($args{Partnumber})
        if defined $args{Partnumber};
    $self->find('*text', id => "counted-$row")->send_keys($args{Counted})
        if defined $args{Counted};
    $self->update;
}

sub update {
    my $self = shift;

    $self->find('*button', text => 'Next')->click;
    $self->session->page->body->maindiv->wait_for_content;
}

sub save {
    my $self = shift;

    $self->find('*button', text => 'Save')->click;
    $self->session->page->body->maindiv->wait_for_content;
}

__PACKAGE__->meta->make_immutable;

1;
