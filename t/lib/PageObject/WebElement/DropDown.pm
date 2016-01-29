package PageObject::WebElement::DropDown;

use strict;
use warnings;

use Carp;
use PageObject::WebElement;

use Moose;
extends 'PageObject::WebElement';

sub find_dropdown {
    my $class = shift @_;
    my $driver = shift @_;
    my $label = shift @_;

    my $elm = $driver->find_element_by_label($label);
    my $self = PageObject::WebElement->new(driver => $driver, element => $elm);

    if ($elm->get_tag_name eq 'select'
        || $self->has_css_class('dijitSelect')) {
        return __PACKAGE__->new(driver => $driver,
                                element => $elm);
    }
    else {
        return undef;
    }
}

sub find_option {
    my ($self, $text) = @_;

    my $dd;
    if ($self->element->get_tag_name ne 'select') {
        # dojo
        my $id = $self->element->get_attribute('id');
        $self->element->click;
        $self->element->click;
        $dd = $self->driver->find_element("//*[\@dijitpopupparent='$id']");
    }
    else {
        $dd = $self->element;
    }
    my $option =
        $self->driver->find_child_element($dd,".//*[text()='$text']");

    if (! $option->is_displayed) {
        $self->element->click;
        $self->driver->execute_script(
            qq#arguments[0].scrollIntoView();#, $option);
    }

    return PageObject::WebElement->new(driver => $self->driver,
                                         element => $option);
}

__PACKAGE__->meta->make_immutable();

1;
