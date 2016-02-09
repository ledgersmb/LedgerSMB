package PageObject;

use strict;
use warnings;

use Carp;
use Module::Runtime qw(use_module);

use Moose;


has driver => (is => 'ro', required => 1);

sub field_types { return {}; }

sub url { croak "Abstract method 'PageObject::url' called"; }

sub open {
    my $self = shift @_;
    $self = $self->new(@_)
        unless ref $self;
    $self->driver->get($ENV{LSMB_BASE_URL} . $self->url);
    $self->driver->page($self);
    return $self;
}


sub verify { croak "Abstract method 'PageObject::verify' called"; }

before 'verify' => sub {
    my ($self) = @_;

    $self->driver->try_wait_for_page;
};


sub find_button {
    my ($self, $text) = @_;

    return PageObject::WebElement->new(
        driver => $self->driver,
        element => $self->driver->find_button($text));
}

sub find_element_by_label {
    my ($self, $label) = @_;
    my $types = $self->field_types;
    my $type = $types->{$label} || 'PageObject::WebElement';

    use_module($type);
    return $type->new(driver => $self->driver,
                      element => $self->driver->find_element_by_label($label));
}

__PACKAGE__->meta->make_immutable;

1;
