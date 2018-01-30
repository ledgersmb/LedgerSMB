package PageObject::App::AP::Transaction;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
use namespace::autoclean;
extends 'PageObject';

my $page_heading = 'Add AP Transaction';

__PACKAGE__->self_register(
              'ap-transaction',
              './/div[@id="AP-transaction"]',
              tag_name => 'div',
              attributes => {
                  id => 'AP-transaction',
              });

sub _verify {
    my ($self) = @_;

    return $self;
}

sub select_vendor {
    my ($self, $vendor) = @_;

    $self->verify;
    my $elem =
        $self->find("*labeled", text => "Vendor");

    $elem->clear;
    $elem->send_keys($vendor);

    $self->find("*button", text => "Update")->click;
    $self->session->page->body->maindiv->wait_for_content;
}



__PACKAGE__->meta->make_immutable;

1;
