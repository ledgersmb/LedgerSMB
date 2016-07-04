package PageObject::App::Main;

use strict;
use warnings;

use PageObject;
use Try::Tiny;

use Moose;
extends 'PageObject';


__PACKAGE__->self_register(
              'app-main',
              './/div[@id="maindiv"]',
              tag_name => 'div',
              attributes => {
                  id => 'maindiv',
              });


has content => (is => 'rw',
                isa => 'PageObject',
                builder => '_build_content',
                predicate => 'has_content',
                clearer => 'clear_content',
                lazy => 1);


sub _build_content {
    my ($self) = @_;

    return $self->find('./*'); # find any immediate child
}

# Note: copy of PageObject::Root::wait_for_body()
sub wait_for_content {
    my ($self) = @_;
    my $old_content;
    $old_content = $self->content if $self->has_content;
    $self->clear_content;

    $self->session->wait_for(
        sub {
            if ($old_content) {
                my $gone = 1;
                try {
                    $old_content->tag_name;
                    # When successfully accessing the tag
                    #  it's not out of scope yet...
                    $gone = 0;
                };
                return $gone;
            }
            else {
                return $self->session->page->find('#maindiv.done-parsing',
                                                  scheme => 'css')
                    ? 1 : 0;
            }
        });
    return $self->content;
}


sub _verify {
    my ($self) = @_;

    $self->content->verify;
    return $self;
};



__PACKAGE__->meta->make_immutable;

1;
