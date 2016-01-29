package PageObject::Setup::CreateConfirm;

use strict;
use warnings;

use Carp;
use Moose;
use PageObject;
extends 'PageObject';

use PageObject::Setup::CreateUser;
use PageObject::WebElement::DropDown;

my %field_types = (
    "Country Code" => "PageObject::WebElement::DropDown",
    );

sub field_types {
    return \%field_types;
}

sub verify {
    my ($self) = @_;
    my $driver = $self->driver;

    my @elements;
    push @elements, @{$driver->find_elements_containing_text($_)}
       for ("Database Management Console",
            "Database does not exist",
            "Create Database");
    croak "Not on the company creation confirmation page" . scalar(@elements)
        if scalar(@elements) != 3;

    return $self;
};

sub create_database {
    my $self = shift @_;
    my %param = @_;
    my $driver = $self->driver;

    $driver->find_button("Yes")->click;
    $driver->try_wait_for_page;

    # assert we're on the "select country" page now
    $driver->find_button($_) for ("Next", "Skip");

    my $elm = $self->find_element_by_label("Country Code");
    my $opt = $elm->find_option($param{"Country code"});
    $opt->click;

    $self->find_button("Next")->click;


    # assert we're on the "select CoA" page now
    $driver->find_button($_) for ("Next", "Skip");
    PageObject::WebElement::DropDown->find_dropdown($driver,
                                                    "Chart of accounts")
        ->find_option($param{"Chart of accounts"})->click;
    $driver->find_button("Next")->click;
    $driver->try_wait_for_page;

    # assert we're on the "Load Templates" page now
    $driver->find_elements_containing_text("Select Templates to Load");
    $driver->find_button($_) for ("Load Templates");
    PageObject::WebElement::DropDown->find_dropdown($driver, "Templates")
        ->find_option($param{"Templates"})->click;
    $driver->find_button("Load Templates")->click;
    $driver->try_wait_for_page;

    return $driver->page(PageObject::Setup::CreateUser->new(%$self));
}


__PACKAGE__->meta->make_immutable;

1;
