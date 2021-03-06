package LedgerSMB::Workflow::Action::RecordSpawnedWorkflow;

=head1 NAME

LedgerSMB::Workflow::Action::RecordSpawnedWorkflow - Spawns a new workflow

=head1 SYNOPSIS

  # action configuration
  <actions>
    <action name="Send"
            class="LedgerSMB::Workflow::Action::RecordSpawnedWorkflow"
            description="Description for the item in the workflow history"
            />
  </actions>


=head1 DESCRIPTION

This module implements a single action to record a spawned workflow from the
active one.

The action supports the following construction parameter

=over

=item * description

=back

This action uses the following key from the workflow context:

=over

=item * spawned_id

=item * spawned_type

=back


=head1 METHODS

=cut


use strict;
use warnings;
use parent qw( Workflow::Action );

use Log::Any qw($log);
use Workflow::Factory qw(FACTORY);

my @PROPS = qw( description );
__PACKAGE__->mk_accessors(@PROPS);

=head2 init($wf, $params)

Implements the C<Workflow::Action> protocol.

=cut

sub init {
    my ($self, $wf, $params) = @_;
    $self->SUPER::init($wf, $params);

    $self->description( $params->{description}
                        // 'Spawned new workflow' );
}

=head2 execute($wf)

Creates a new workflow of the type configured ###TODO

Implements the C<Workflow::Action> protocol.

=cut

sub execute {
    my ($self, $wf) = @_;

    my $wf_id   = $wf->context->param( 'spawned_id' );
    die q{Missing context parameter 'spawned_id'} unless $wf_id;

    my $wf_type = $wf->context->param( 'spawned_type' );
    die q{Missing context parameter 'spawned_type'} unless $wf_type;

    $wf->add_history(
        {
            action      => $self->name,
            description => ($self->description
                            . "|spawned_workflow:$wf_id,$wf_type")
        });

    return;
}

1;

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020-2021 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

