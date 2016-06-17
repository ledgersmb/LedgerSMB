package PageObject::App::Main;

use strict;
use warnings;

use Carp;
use PageObject;

use Selenium::Waiter qw(wait_until);

use PageObject::App::Menu;
use PageObject::App::Initial;

use Moose;
extends 'PageObject';


has menu => (is => 'ro', builder => '_build_menu', lazy => 1);
has content => (is => 'rw', builder => '_build_content', lazy => 1);

sub _build_menu { return PageObject::App::Menu->new(%{(shift)}); }
sub _build_content { return PageObject::App::Initial->new(%{(shift)}); }



sub _verify {
    my ($self) = @_;
    my $driver = $self->driver;

    $self->menu->verify;
    wait_until { my $elem = $driver->find_element('#maindiv.done-parsing','css'); return ($elem && $elem->is_displayed); };
    $self->content->verify;

    return $self;
};



__PACKAGE__->meta->make_immutable;

1;
