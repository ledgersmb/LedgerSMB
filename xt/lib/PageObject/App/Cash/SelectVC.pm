package PageObject::App::Cash::SelectVC;

use strict;
use warnings;

use Carp;
use PageObject;

use PageObject::App::Cash::Entry;

use Moose;
use namespace::autoclean;
extends 'PageObject';

__PACKAGE__->self_register(
              'payments-select-vc',
              './/form[@id="payments-select-vc"]',
              tag_name => 'form',
              attributes => {
                  id => 'payments-select-vc',
              });


sub _verify {
    my ($self) = @_;

    return $self;
}

sub run {
    my ($self, %options) = @_;

    my $content = $self->session->page->body->maindiv->content;
    $self->find('*button', text => 'Continue')->click;
    $self->session->page->body->maindiv->wait_for_content(replaces => $content);
}

__PACKAGE__->meta->make_immutable;

1;
