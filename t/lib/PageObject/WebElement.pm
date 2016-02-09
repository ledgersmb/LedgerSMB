package PageObject::WebElement;

use strict;
use warnings;

use Carp;
use PageObject;
use Module::Runtime qw(use_module);

use Moose;
extends 'PageObject';

has element => (is => 'ro', required => 1,
                isa => 'Selenium::Remote::WebElement');


sub click {
    my ($self) = @_;
    $self->element->click;
    $self->driver->try_wait_for_page;
    return $self;
}

sub get_attribute { return shift->element->get_attribute(@_); }

sub has_css_class {
    my ($self, $class) = @_;
    my $class_attr = $self->element->get_attribute('class');
    my $rv =
        grep { $_ eq $class }
        split /[\s\t\n]+/, $class_attr;

    return $rv;
}


sub send_keys {
    my ($self, $keys) = @_;
    $self->element->send_keys($keys);
    return $self;
}

sub wrap_element {
    my ($self, $class, $raw_element) = @_;

    use_module($class);
    return $class->new(driver => $self->driver, element => $raw_element);
}

sub wrap_elements {
    my ($self, $class, $raw_elements) = @_;

    my @elements =
        map { $self->wrap_element($class, $_) } @$raw_elements;
    return \@elements;
}

__PACKAGE__->meta->make_immutable();

1;
