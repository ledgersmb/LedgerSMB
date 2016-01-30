package PageObject::Setup::UsersList;

use strict;
use warnings;

use Carp;
use Moose;
use PageObject;
extends 'PageObject';


sub verify {
    my ($self) = @_;
    my $driver = $self->driver;

    #@@@TODO: There's an assertion missing here
    $driver->find_elements_containing_text($_)
        for ("Available Users", "Username");

    return $self;
};

sub get_users_list {
    my ($self) = @_;
    my $driver = $self->driver;

    my $table_elm = $driver->find_element('//table');
    my $user_links = $driver->find_child_elements($table_elm, './/a');

    my @users = map { $_->get_text } @{ $user_links };

    return \@users;
}


__PACKAGE__->meta->make_immutable;

1;
