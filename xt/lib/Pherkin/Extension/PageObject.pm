
=head1 NAME

Pherkin::Extension::PageObject - Pherkin extension for our PageObject testing

=head1 VERSION

0.01

=head1 SYNOPSIS



=cut

package Pherkin::Extension::PageObject;

use strict;
use warnings;

our $VERSION = '0.01';

use PageObject::Loader;
use Test::BDD::Cucumber::Extension;

use Moose;
use namespace::autoclean;
extends 'Test::BDD::Cucumber::Extension';


=head1 Test::BDD::Cucumber::Extension protocol implementation

=over

=item step_directories

=cut

sub step_directories {
    return [ 'pageobject_steps/' ];
}


=item pre_scenario

=cut

sub pre_scenario {
    my ($self, $scenario, $feature_stash, $stash) = @_;

    $self->last_stash($stash);
    $stash->{ext_page} = $self;
}


=item post_scenario {

=cut

sub post_scenario {
    my ($self, $scenario, $feature_stash, $stash) = @_;

    # break the ref-counting cycle
    $self->last_stash(undef);
}

=back

=head1 ATTRIBUTES

=over

=item last_stash

=cut

has 'last_stash' => (is => 'rw');

=item page_object

=cut

has 'page' => (is => 'rw');

=back

=cut


__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
