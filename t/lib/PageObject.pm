package PageObject;

use strict;
use warnings;

use Carp;
use Module::Runtime qw(use_module);

use Moose;
use Weasel::FindExpanders::HTML;
use Carp::Always;

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


sub verify { croak "Abstract method 'PageObject::verify' called"; }



__PACKAGE__->meta->make_immutable;

1;
