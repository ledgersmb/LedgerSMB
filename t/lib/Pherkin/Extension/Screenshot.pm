=head1 NAME

Pherkin::Extension::Screenshot

=head1 SYNOPSIS

LedgerSMB super-user connection to the PostgreSQL cluster and test
company management routines

=cut

package Pherkin::Extension::Screenshot;

use strict;
use warnings;

use Test::BDD::Cucumber::Extension;


use Moose;
extends 'Test::BDD::Cucumber::Extension';

has output_path => (is => 'ro', isa => 'Maybe[Str]');


my $img_num = 0;

sub pre_step {
    my ($self, $feature, $ctx) = @_;

    $img_num++;
    $self->save_screenshot($ctx->stash, 'pre');
}

sub post_step {
    my ($self, $feature, $ctx) = @_;

    $self->save_screenshot($ctx->stash, 'post');
}



sub save_screenshot {
    my ($self, $stash, $phase) = @_;
    my $drv = $stash->{feature}->{driver};

    $drv->capture_screenshot($self->output_path . "/img-$img_num-$phase.png")
        if ($drv);
}


1;
