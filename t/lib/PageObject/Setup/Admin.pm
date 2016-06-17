package PageObject::Setup::Admin;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
extends 'PageObject';

use PageObject::Setup::CreateUser;
use PageObject::Setup::UsersList;


sub _verify {
    my ($self) = @_;
    my $stash = $self->stash;

    #@@@TODO: There's an assertion missing here
    $stash->{ext_wsl}->page->find('*contains', text => $_)
        for ("Database Management Console",
             "Confirm Operation",
             "Logged in as",
             "Rebuild/Upgrade?");

    $stash->{ext_wsl}->page->find('*button', text => $_)
        for ("Add User", "List Users", "Load Templates", "Yes",
             "Backup DB", "Backup Roles");
    return $self;
};

sub list_users {
    my ($self) = @_;
    my $stash = $self->stash;

    $stash->{ext_wsl}->page->find('*button', text => "List Users")->click;
    return $stash->{page} = PageObject::Setup::UsersList->new(%$self);
}

sub add_user {
    my ($self) = @_;
    my $stash = $self->stash;

    $stash->{ext_wsl}->page->find('*button', text => "Add User")->click;
    return $stash->{page} = PageObject::Setup::CreateUser->new(%$self);
}

sub copy_company {
    my ($self, $target) = @_;
    my $stash = $self->stash;

    $stash->{ext_wsl}->page->find('*labeled', text => "Copy to New Name")
        ->send_keys($target);
    $stash->{ext_wsl}->page->find('*button', text => "Copy")->click;

    return $stash->{page} =
        PageObject::Setup::OperationConfirmation->new(%$self);
}

__PACKAGE__->meta->make_immutable;

1;
