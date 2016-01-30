package PageObject::Setup::Admin;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
extends 'PageObject';

use PageObject::Setup::CreateUser;
use PageObject::Setup::UsersList;


sub verify {
    my ($self) = @_;
    my $driver = $self->driver;

    #@@@TODO: There's an assertion missing here
    $driver->find_elements_containing_text($_)
        for ("Database Management Console",
             "Confirm Operation",
             "Logged in as",
             "Rebuild/Upgrade?");

    $driver->find_button($_)
        for ("Add User", "List Users", "Load Templates", "Yes",
             "Backup DB", "Backup Roles");
    return $self;
};

sub list_users {
    my ($self) = @_;
    my $driver = $self->driver;

    $driver->find_button("List Users")->click;
    return $driver->page(PageObject::Setup::UsersList->new(%$self));
}

sub add_user {
    my ($self) = @_;
    my $driver = $self->driver;

    $driver->find_button("Add User")->click;
    return $driver->page(PageObject::Setup::CreateUser->new(%$self));
}

sub copy_company {
    my ($self, $target) = @_;
    my $driver = $self->driver;

    $driver->find_element_by_label("Copy to New Name")->send_keys($target);
    $driver->find_button("Copy")->click;

    return $driver->page(PageObject::Setup::OperationConfirmation->new(%$self));
}

__PACKAGE__->meta->make_immutable;

1;
