package LedgerSMB::Workflow::Action::SpawnWorkflow;

=head1 NAME

LedgerSMB::Workflow::Action::SpawnWorkflow - Spawns a new workflow

=head1 SYNOPSIS

  # action configuration
  <actions>
    <action name="Send"
            class="LedgerSMB::Workflow::Action::SpawnWorkflow"
            description="Description for the item in the workflow history"
            spawn_type="Email"
            />
  </actions>


=head1 DESCRIPTION

This modul implements a single action to spawn a new workflow from the
active one.

The action supports the following two

=over

=item * spawn_type

=item * context_param

=item * description

=back

This action adds the following key to the workflow context:

=over

=item * spawned_workflow

=back


=head1 METHODS

=cut


use strict;
use warnings;
use parent qw( Workflow::Action );

use Log::Any qw($log);
use Workflow::Factory qw(FACTORY);

my @PROPS = qw( spawn_type context_param description );
__PACKAGE__->mk_accessors(@PROPS);

=head2 init($wf, $params)

Implements the C<Workflow::Action> protocol.

=cut

sub init {
    my ($self, $wf, $params) = @_;
    $self->SUPER::init($wf, $params);

    $self->spawn_type( $params->{spawn_type} );
    $self->context_param( $params->{context_param} );
    $self->description( $params->{description}
                        // ('Created new workflow of type: '
                            . $params->{spawn_type}) );
}

=head2 execute($wf)

Creates a new workflow of the type configured ###TODO

Implements the C<Workflow::Action> protocol.

=cut

sub execute {
    my ($self, $wf) = @_;

    my $context;
    if ( $self->context_param ) {
        my $context_data = $wf->context->param( $self->context_param );

        $context = Workflow::Context->new();
        for my $key (keys $context_data->%*) {
            $context->param( $key => $context_data->{$key} );
        }
    }
    my $new_wf = FACTORY()->create_workflow( $self->spawn_type, $context );
    my $wf_id  = $new_wf->id;
    $wf->context->param( spawned_workflow => $new_wf );
    $wf->add_history(
        {
            action      => $self->name,
            description => ($self->description
                            . "|spawned_workflow:$wf_id,"
                            . $self->spawn_type )
        });

    return;
}

1;

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020-2021 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

