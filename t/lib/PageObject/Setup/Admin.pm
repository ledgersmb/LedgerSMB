package PageObject::Setup::Admin;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
extends 'PageObject';

use PageObject::Setup::CreateUser;
use PageObject::Setup::CredsSection;
use PageObject::Setup::UsersList;


has creds => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my ($self) = @_;

        return PageObject::Setup::CredsSection->new(
            %$self,
            element => $self->stash->{ext_wsl}->page
            ->find('.//*[@id="credentials"]')
            );
    });

sub _verify {
    my ($self) = @_;
    my $stash = $self->stash;

    $stash->{ext_wsl}->page->find('*contains', text => $_)
        for ("Database Management Console",
             "Confirm Operation",
             "Rebuild/Upgrade?");

    $stash->{ext_wsl}->page->find('*button', text => $_)
        for ("Add User", "List Users", "Load Templates", "Yes",
             "Backup DB", "Backup Roles");
    return $self;
};

sub list_users {
    my ($self) = @_;
    my $stash = $self->stash;
    my $btn = $stash->{ext_wsl}->page
        ->find('*button', text => "List Users");

    $btn->click;
    return $stash->{page} =
        PageObject::Setup::UsersList->new(%$self)
        ->verify($btn);
}

sub add_user {
    my ($self) = @_;
    my $stash = $self->stash;
    my $btn = $stash->{ext_wsl}->page
        ->find('*button', text => "Add User");

    $btn->click;
    return $stash->{page} =
        PageObject::Setup::CreateUser->new(%$self)
        ->verify($btn);
}

sub copy_company {
    my ($self, $target) = @_;
    my $stash = $self->stash;

    $stash->{ext_wsl}->page->find('*labeled', text => "Copy to New Name")
        ->send_keys($target);

    my $btn = $stash->{ext_wsl}->page
        ->find('*button', text => "Copy");
    $btn->click;

    return $stash->{page} =
        PageObject::Setup::OperationConfirmation->new(%$self)
        ->verify($btn);
}

__PACKAGE__->meta->make_immutable;

1;
