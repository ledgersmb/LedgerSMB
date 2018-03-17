package PageObject::Root;

use strict;
use warnings;

use Moose;
use namespace::autoclean;
extends 'Weasel::Element::Document';

use Try::Tiny;

has body => (is => 'rw',
             isa => 'PageObject',
             required => 0,
             clearer => 'clear_body',
             predicate => 'has_body',
             builder => '_build_body',
             lazy => 1);

sub _build_body {
    my ($self) = @_;

    return $self->find('body.done-parsing', scheme => 'css');
}

sub wait_for_body {
    my ($self) = @_;
    my $old_body;
    $old_body = $self->body if $self->has_body;
    $self->clear_body;

    $self->session->wait_for(
        sub {
            if ($old_body) {
                my $gone = 1;
                try {
                    my $tagname = $old_body->tag_name;
                    # When successfully accessing the tag
                    #  it's not out of scope yet...
                    $gone = 0 if defined $tagname;
                };
                $old_body = undef if $gone;
                return 0; # Not done yet
            }
            else {
                return $self->find('body.done-parsing', scheme => 'css') ? 1 : 0;
            }
        });
    return $self->body;
}

__PACKAGE__->meta->make_immutable;
1;
