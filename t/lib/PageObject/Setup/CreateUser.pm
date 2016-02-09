package PageObject::Setup::CreateUser;

use strict;
use warnings;

use Carp;
use Moose;
use PageObject;
extends 'PageObject';


use PageObject::Setup::OperationConfirmation;


my @fields = ("Username", "Password", "Yes", "No", "Salutation",
              "First Name", "Last name", "Employee Number",
              "Date of Birth", "Tax ID/SSN", "Country", "Assign Permissions");

my %field_types = (
    "Salutation"         => "PageObject::WebElement::DropDown",
    "Assign Permissions" => "PageObject::WebElement::DropDown",
    "Country"            => "PageObject::WebElement::DropDown",
#    "Date of Birth"      =>
    );

sub field_types {
    return \%field_types;
}

sub verify {
    my ($self) = @_;
    my $driver = $self->driver;

    $driver->find_element_by_label($_) for @fields;

    return $self;
}

sub create_user {
    my $self = shift;
    my %param = @_;

    foreach my $field (@fields) {
        next unless exists $param{$field};
        my $elm = $self->find_element_by_label($field);
        if ($elm->isa('PageObject::WebElement::DropDown')) {
            $elm->find_option($param{$field})->click;
        }
        else {
            $elm->send_keys($param{$field});
        }
    }
    $self->find_button("Create User")->click;

    return
        $self->driver->page(
            PageObject::Setup::OperationConfirmation->new(%$self));
}


__PACKAGE__->meta->make_immutable;

1;
