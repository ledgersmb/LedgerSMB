package PageObject::Setup::UsersList;

use strict;
use warnings;

use Carp;
use Moose;
use PageObject;
extends 'PageObject';

use PageObject::Setup::EditUser;

sub _verify {
    my ($self) = @_;
    my $page = $self->stash->{ext_wsl}->page;

    #@@@TODO: There's an assertion missing here
    $page->find('*contains', text => $_)
        for ("Available Users", "Username");

    return $self;
};

sub get_users_list {
    my ($self) = @_;
    my $page = $self->stash->{ext_wsl}->page;

    my $user_links = $page->find('.//table[@id="user_list"]')
        ->find_all('.//a');

    my @users = map { $_->get_text } @{ $user_links };

    return \@users;
}

sub edit_user {
    my ($self, $user) = @_;
    my $page = $self->stash->{ext_wsl}->page;

    my $user_link = $page->find("//a[text()='$user']");
    $user_link->click;

    return ($self->stash->{page} =
            PageObject::Setup::EditUser->new(%$self))
        ->verify($user_link);
}


__PACKAGE__->meta->make_immutable;

1;
