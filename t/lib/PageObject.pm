package PageObject;

use strict;
use warnings;

use Carp;
use Module::Runtime qw(use_module);

use Moose;
use Weasel::FindExpanders::Dojo;
use Weasel::FindExpanders::HTML;

use Weasel::Widgets::Dojo;
use Weasel::Widgets::HTML;

has stash => (is => 'ro', required => 1);

sub field_types { return {}; }

sub url { croak "Abstract method 'PageObject::url' called"; }

sub open {
    my $self = shift @_;
    $self = $self->new(@_) unless ref $self;

    $self->stash->{ext_wsl}->get($self->url);
    $self->stash->{page} = $self;

    return $self;
}

sub find {
    my ($self, @args) = @_;

    return $self->stash->{ext_wsl}->find(
        ###TODO we want to search the page with 'ourselves' as the root of the search
        $self->stash->{ext_wsl}->page,
        @args);
}

sub wait_for_page {
    my ($self, $ref) = @_;

    $self->stash->{ext_wsl}->wait_for(
        sub {

            if ($ref) {
                # if there's a reference element,
                # wait for it to go stale (raise an exception)
                eval {
                    $ref->tag_name;
                    1;
                } or return 1;
            }
            else {
                $self->stash->{page}
                ->find('body.done-parsing', scheme => 'css');
            }
        });
}

sub verify {
    my ($self, $ref) = @_;

    $self->wait_for_page($ref);
    $self->_verify;
};

sub _verify { croak "Abstract method 'PageObject::verify' called"; }



__PACKAGE__->meta->make_immutable;

1;
