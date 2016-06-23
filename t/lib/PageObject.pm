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
    my ($self) = @_;

    $self->stash->{ext_wsl}->wait_for( sub {
        $self->stash->{page}->find('body.done-parsing', scheme => 'css');
                                       });
}

sub verify {
    my ($self) = @_;

    $self->wait_for_page;
    $self->_verify;
};

sub _verify { croak "Abstract method 'PageObject::verify' called"; }



__PACKAGE__->meta->make_immutable;

1;
