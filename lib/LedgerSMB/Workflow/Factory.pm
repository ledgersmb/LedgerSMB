
use v5.38;
use experimental 'try';

package LedgerSMB::Workflow::Factory;

use parent 'Workflow::Factory';

use DateTime;
use Scalar::Util qw( blessed );
use Workflow::Context;
use Workflow::Exception qw( workflow_error );

=head1 NAME

LedgerSMB::Workflow::Factory - LedgerSMB factory for the instantiation of workflows

=head1 SYNOPSYS

  use LedgerSMB::Workflow::Factory;

  my $singleton = LedgerSMB::Workflow::Factory->instance();

=head1 DESCRIPTION



=head1 PROPERTIES

=head2 wire

Contains the L<Beam::Wire> dependency injection configuration instance, to
be passed onto LedgerSMB::Workflow instances.

=cut

my $DEFAULT_INITIAL_STATE = 'INITIAL';

=head1 METHODS

=head2 Public methods

=head3 init

  $factory->init();

=cut

sub init($self, @args) {
    $self->SUPER::init(@args);

    # compensate for the fact that the class isn't in the configuration,
    # but "patched in" below
    $self->_load_class( 'LedgerSMB::Workflow' );
}

=head3 create_workflow

  my $wf = $factory->create_workflow( $app, $wf_type, [$context], [$wf_class] );

Returns a new workflow instance of class C<LedgerSMB::Workflow> from the
indicated C<$wf_type> (indicated by the C<type> in the workflow configuration).

Sets the C<app> field of the workflow to the value of the C<$app>
argument.

See L<Workflow::Factory/create_workflow> for more.

=cut

sub create_workflow {
    my ( $self, $app, $wf_type, $context, $wf_class ) = @_;
    my $wf_config = $self->_get_workflow_config($wf_type);

    unless ($wf_config) {
        workflow_error "No workflow of type '$wf_type' available";
    }

    $wf_class = $wf_config->{class} || 'Workflow' unless ($wf_class);
    my $wf
        = $wf_class->new( undef,
        $wf_config->{initial_state} || $DEFAULT_INITIAL_STATE,
        $wf_config, $self->{_workflow_state}{$wf_type}, $self );

    if ($context and not blessed $context) {
        $context = Workflow::Context->new( %{ $context } );
    }
    elsif (not $context) {
        $context = Workflow::Context->new;
    }
    $wf->context( $context );

    $wf->{last_update} = DateTime->now( time_zone => $wf->time_zone() );
    $self->log->info( 'Instantiated workflow object properly, persisting...' );
    my $persister = $self->get_persister( $wf_config->{persister} );
    my $id        = $persister->create_workflow($app, $wf);
    $wf->{id} = $id;

    # this is ours  ; the rest of the function mirrors Workflow::Factory
    $wf->{app}  = $app;

    $self->log->info("Persisted workflow with ID '$id'; creating history...");
    $wf->add_history(
        {
            $wf->get_initial_history_data(), # returns a *list*
            workflow_id => $id,
            state       => $wf->state,
            date        => DateTime->now( time_zone => 'UTC' ),
            time_zone   => $wf->time_zone(),
        });
    $persister->create_history( $wf, $wf->get_unsaved_history() );
    $self->log->info( 'Created history object ok' );
    $persister->commit_transaction( $app );

    $self->associate_observers_with_workflow($wf);
    $self->_associate_transaction_observer_with_workflow($app, $wf, $persister);
    $wf->notify_observers('create');

    my $state = $wf->_get_workflow_state();
    $wf->_maybe_autorun_state( $state );

    return $wf;
}

sub _associate_transaction_observer_with_workflow {
    my ( $self, $app, $wf, $persister ) = @_;
    $wf->add_observer(
        sub {
            my ($unused, $action) = @_; # first argument repeats $wf
            if ( $action eq 'save' ) {
                $persister->commit_transaction( $app );
            }
            elsif ( $action eq 'rollback' ) {
                $persister->rollback_transaction( $app );
            }
        });
}


=head3 fetch_workflow

  my $wf = $factory->fetch_workflow( $app, $wf_type, $wf_id, [$context], [$wf_class] );

Returns an existing workflow instance created from stored state.

Sets the C<app> field of the workflow to the value of the C<$app>
argument.

See L<Workflow::Factory/fetch_workflow> for more.

=cut

sub fetch_workflow {
    my ( $self, $app, $wf_type, $wf_id, $context, $wf_class ) = @_;
    my $wf_config = $self->_get_workflow_config($wf_type);

    unless ($wf_config) {
        workflow_error "No workflow of type '$wf_type' available";
    }
    my $persister = $self->get_persister( $wf_config->{persister} );
    my $wf_info   = $persister->fetch_workflow($app, $wf_id);
    $wf_class     = $wf_config->{class} || 'Workflow' unless ($wf_class);

    return unless ($wf_info);

    $wf_info->{last_update} ||= '';
    $self->log->debug(
        "Fetched data for workflow '$wf_id' ok: ",
        "[State: $wf_info->{state}] ",
        "[Last update: $wf_info->{last_update}]"
        );
    my $wf = $wf_class->new( $wf_id, $wf_info->{state}, $wf_config,
        $self->{_workflow_state}{$wf_type}, $self );

    # this line is ours; the rest of the function mirrors Workflow::Factory
    $wf->{app}  = $app;

    if ($wf_info->{context} && blessed( $wf_info->{context} ) ) {
        $context = $wf_info->{context};
    } else {
        $context = Workflow::Context->new(
            %{ $context },
            %{ $wf_info->{context} // {} }
            );
    }
    $wf->{context} = $context;
    $wf->{last_update} = $wf_info->{last_update};

    $self->associate_observers_with_workflow($wf);
    $self->_associate_transaction_observer_with_workflow($app, $wf, $persister);
    $wf->notify_observers('fetch');

    return $wf;
}

=head2 Private methods

=head3 _get_workflow_config

  $wf_config = $self->_get_workflow_config( $wf_type );

Patches the workflow configuration to create L<LedgerSMB::Workflow> class
workflow instances instead of the regular L<Workflow> default.

=cut

sub _get_workflow_config( $self, $wf_type ) {
    my $wf_config = $self->SUPER::_get_workflow_config( $wf_type );
    $wf_config->{class} //= 'LedgerSMB::Workflow';

    return $wf_config;
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

