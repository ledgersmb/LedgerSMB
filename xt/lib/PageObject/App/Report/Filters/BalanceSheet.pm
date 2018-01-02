package PageObject::App::Report::Filters::BalanceSheet;

use strict;
use warnings;

use Carp;
use PageObject;

use PageObject::App::Report::BalanceSheet;

use Moose;
use namespace::autoclean;
extends 'PageObject';

__PACKAGE__->self_register(
              'reports-balance-sheet-params',
              './/div[@id="balance-sheet-parameters"]',
              tag_name => 'div',
              attributes => {
                  id => 'balance-sheet-parameters',
              });


sub _verify {
    my ($self) = @_;

    return $self;
}

sub run {
    my ($self, %options) = @_;

    $self->find('.//input[@id="to-date"]')->send_keys($options{date});
    $self->find('*button', text => 'Continue')->click;
    $self->session->page->body->maindiv->wait_for_content;
}

__PACKAGE__->meta->make_immutable;

1;
