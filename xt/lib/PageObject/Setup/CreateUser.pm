package PageObject::Setup::CreateUser;

use strict;
use warnings;

use Carp;
use Moose;
use namespace::autoclean;
use PageObject;
extends 'PageObject';


__PACKAGE__->self_register(
              'setup-add-user',
              './/body[@id="setup-new-user"]',
              tag_name => 'body',
              attributes => {
                  id => 'setup-new-user',
              });


my @fields = ("Username", "Password", "Create new user", "Import existing user",
              "Salutation", "First Name", "Last name", "Employee Number",
              "Date of Birth", "Tax ID/SSN", "Country", "Assign Permissions");


sub _verify {
    my ($self) = @_;

    $self->find('*labeled', text => $_) for @fields;
    return $self;
}

sub create_user {
    my $self = shift;
    my %param = @_;

    foreach my $field (@fields) {
        next unless exists $param{$field};
        my $elm =
            $self->find('*labeled', text => $field);

        if ($elm->can('find_option')) {
            $elm->find_option($param{$field})->click;
        }
        else {
            $elm->send_keys($param{$field});
        }
    }
    my $btn = $self->find('*button', text => "Create User");
    $btn->click;

    $self->session->page->wait_for_body;
    return $self->session->page->body;
}


__PACKAGE__->meta->make_immutable;

1;
