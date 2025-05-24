package PageObject::Setup::Admin;

use strict;
use warnings;

use Carp;
use Carp::Always;
use PageObject;
use Test::More;

use Moose;
use namespace::autoclean;
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

    return $self->session->page->wait_for_body(replaces => $btn);
}

sub add_user {
    my ($self) = @_;
    my $btn = $self->find('*button', text => "Add User");
    $btn->click;

    return $self->session->page->wait_for_body(replaces => $btn);
}

sub copy_company {
    my ($self, $target) = @_;

    $self->find('*labeled', text => "Copy to New Name")
        ->send_keys($target);
    my $btn = $self->find('*button', text => "Copy");
    $btn->click;

    return $self->session->page->wait_for_body(replaces => $btn);
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

    $page->find('.//*[@data-lsmb-done]');
    # Confirm database creation
    my $btn = $page->find('*button', text => "Yes");
    $btn->click;
    ok('Yes-button clicked on initial confirmation');

    $page->session->wait_for(
        sub {
            my @nodes = $page->find_all('.//*[@id="setup-select-coa-country" and @data-lsmb-done]');
            return @nodes > 0;
        },
        retry_timeout => 120);
    $page->find('*labeled', text => "Country")
        ->find_option($param{"Country"})
        ->click;
    $btn = $page->find('*button', text => "Next");
    $btn->click;
    ok('Next-button clicked after country selection');

    $page->session->wait_for(
        sub {
            my @nodes = $page->find_all('.//*[@id="setup-select-coa-details" and @data-lsmb-done]');
            return @nodes > 0;
        },
        retry_timeout => 120);
    $page->find('*labeled', text => "Chart of accounts")
        ->find_option($param{"Chart of accounts"})
        ->click;
    $page->find('*button', text => "Next")->click;
    ok('Next-button clicked after CoA selection');

    # assert we're on the "Load Templates" page now
    $page->find('.//*[@id="setup-template-info" and @data-lsmb-done]');
    $page->find('*contains', text => "Select Templates to Load");
    $page->find('*button', text => $_) for ("Load Templates");

    $page->find('*labeled', text => 'Templates')
        ->find_option($param{"Templates"})
        ->click;

    $btn = $page->find('*button', text => "Load Templates");
    $btn->click;
    ok('Load Templates-button clicked after templates selection');

    $self->session->page->wait_for_body(
        replaces => $btn,
        retry_timeout => 120 # 2 minutes = 120secs
        );
    return $self->session->page->body;
}


__PACKAGE__->meta->make_immutable;

1;
