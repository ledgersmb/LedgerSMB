package PageObject::Setup::Admin;

use strict;
use warnings;

use Carp;
use PageObject;

use Moose;
extends 'PageObject';

__PACKAGE__->self_register(
              'setup-admin',
              './/body[@id="setup-confirm-operation"]',
              tag_name => 'body',
              attributes => {
                  id => 'setup-confirm-operation',
              });

has creds => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my ($self) = @_;

        return $self->find('*setup-credentials-section');
    });

sub _verify {
    my ($self) = @_;

    $self->find('*contains', text => $_)
        for ("Database Management Console",
             "Confirm Operation");

    if ($self->find('.//div[@id="operation"]')->get_text ne 'Create Database?') {
        $self->find('*button', text => $_)
            for ("Add User", "List Users", "Load Templates", "Yes",
                 "Backup DB", "Backup Roles");
    }
    return $self;
};

sub list_users {
    my ($self) = @_;
    my $btn = $self->find('*button', text => "List Users");
    $btn->click;

    return $self->session->page->wait_for_body;
}

sub add_user {
    my ($self) = @_;
    my $btn = $self->find('*button', text => "Add User");
    $btn->click;

    return $self->session->page->wait_for_body;
}

sub copy_company {
    my ($self, $target) = @_;

    $self->find('*labeled', text => "Copy to New Name")
        ->send_keys($target);
    my $btn = $self->find('*button', text => "Copy");
    $btn->click;

    return $self->session->page->wait_for_body;
}

sub create_database {
    my $self = shift @_;
    my %param = @_;
    my $page = $self->session->page;

    my @elements;
    push @elements, @{$page->find_all('*contains', text => $_)}
       for ("Database does not exist",
            "Create Database",
            "Database Management Console",
           );
    croak "Not on the company creation confirmation page " . scalar(@elements)
        if scalar(@elements) != 3;

    # Confirm database creation
    $page->find('*button', text => "Yes")->click;

    $page->find('#setup-select-coa.done-parsing', scheme => 'css');
    $page->find('*labeled', text => "Country Code")
        ->find_option($param{"Country code"})
        ->click;
    $page->find('*button', text => "Next")->click;

    $page->find('*labeled', text => "Chart of accounts");
    $page->find('#setup-select-coa.done-parsing', scheme => 'css');
    $page->find('*labeled', text => "Chart of accounts")
        ->find_option($param{"Chart of accounts"})
        ->click;
    $page->find('*button', text => "Next")->click;

    # assert we're on the "Load Templates" page now
    $page->find('#setup-template-info.done-parsing', scheme => 'css');
    $page->find('*contains', text => "Select Templates to Load");
    $page->find('*button', text => $_) for ("Load Templates");

    $page->find('*labeled', text => 'Templates')
        ->find_option($param{"Templates"})
        ->click;

    my $btn = $page->find('*button', text => "Load Templates");
    $btn->click;

     $self->session->page->wait_for_body;
    return $self->session->page->body;
}


__PACKAGE__->meta->make_immutable;

1;
