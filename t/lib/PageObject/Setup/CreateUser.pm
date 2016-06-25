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


sub _verify {
    my ($self) = @_;
    my $page = $self->stash->{ext_wsl}->page;

    $page->find('*labeled', text => $_) for @fields;

    return $self;
}

sub create_user {
    my $self = shift;
    my %param = @_;

    foreach my $field (@fields) {
        next unless exists $param{$field};
        my $elm =
            $self->stash->{ext_wsl}->page->find('*labeled', text => $field);

        if ($elm->can('find_option')) {
            $elm->find_option($param{$field})->click;
        }
        else {
            $elm->send_keys($param{$field});
        }
    }
    my $btn = $self->find('*button', text => "Create User");
    $btn->click;

    return $self->stash->{page} =
        PageObject::Setup::OperationConfirmation->new(%$self)
        ->verify($btn);
}


__PACKAGE__->meta->make_immutable;

1;
