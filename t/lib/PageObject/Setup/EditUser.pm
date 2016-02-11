package PageObject::Setup::EditUser;

use strict;
use warnings;

use Carp;
use Moose;
use PageObject;
extends 'PageObject';


sub verify {
    my ($self) = @_;
    my $driver = $self->driver;

    $driver->find_element_by_label($_)
        for ("Password",
             # mention some role names; we want to verify they're there
             "account all",
             "employees manage",
        );

    $driver->find_button($_)
        for ("Reset Password", "Save Groups");

    return $self;
}


my %roles_checkbox_filter = (
    'all' => '',
    'checked' => "and \@checked='checked'",
    'unchecked' => "and \@checked=''"
    );

sub get_perms_checkboxes {
    my $self = shift @_;
    my $driver = $self->driver;
    my %params = @_;

    $params{filter} ||= 'all';
    my $filter = $roles_checkbox_filter{$params{filter}};

    my @checkboxes =
        $driver->find_child_elements(
            $driver->find_element("//table[\@id='user-roles']"),
            ".//input[\@type='checkbox' $filter]");

    return \@checkboxes;
}

sub is_checked_perms_checkbox {
    my ($self, $label) = @_;
    my $driver = $self->driver;
    my $box = $driver->find_element_by_label($label);

    # assume the returned element is of type checkbox
    return ($box->get_attribute('checked') eq 'true');
}



__PACKAGE__->meta->make_immutable;

1;
