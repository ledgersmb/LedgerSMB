
use v5.36;
use warnings;
use experimental 'try';

package PageObject::App::Main;

use PageObject;

use Moose;
use namespace::autoclean;
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
                reader => '_get_content',
                writer => '_set_content',
                clearer => 'clear_content',
                lazy => 1);

sub content {
    my ($self, $new_value) = @_;

    return $self->_set_content($new_value) if $new_value;

    my $gone = 1;
    try {
        my $tagname = $self->_get_content->tag_name
            if $self->has_content;
        # we're still here?
        $gone = 0 if defined $tagname;
    }
    catch ($e) { }

    $self->clear_content if $gone; # force builder


    return $self->_get_content;
}

sub _wait_for_valid_content {
    my ($self) = @_;

    $self->session->wait_for(
        sub {
            return $self->get_attribute('data-lsmb-done');
        });
}

sub _build_content {
    my ($self) = @_;

    $self->_wait_for_valid_content;

    my @found = $self->find_all('./div/*'); # find any immediate child
    die "#maindiv is expected to have exactly one child node, found " . scalar(@found) .
        '(' . join(',',map {ref $_} @found) . ')'
        unless scalar(@found) == 1;

    my $found = shift @found;
    die "the immediate child node of #maindiv isn't recognised as a PageObject but as a " . ref $found
        unless $found->isa("PageObject");

    return $found;
}

# Note: copy of PageObject::Root::wait_for_body()
sub wait_for_content {
    my ($self, %args) = @_;
    my $old_content = $args{replaces};
    $old_content //= $self->content if $self->has_content;
    $self->clear_content;

    $self->session->wait_for(
        # removed content
        sub {
            # In case of an exception, eval returns 'undef'
            $old_content = eval {
                $old_content->tag_name;
                $old_content;
            };

            return not defined $old_content;
        });
    $self->_wait_for_valid_content;

    return $self->content;
}


sub _verify {
    my ($self) = @_;

    $self->content->verify;
    return $self;
};



__PACKAGE__->meta->make_immutable;

1;
