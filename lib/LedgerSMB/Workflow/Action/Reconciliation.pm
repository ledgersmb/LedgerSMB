package LedgerSMB::Workflow::Action::Reconciliation;

use v5.36;
use warnings;
no warnings "experimental::for_list"; ## no critic -- accepted in 5.40

use parent qw( LedgerSMB::Workflow::Action );

use builtin qw(indexed);
use List::Util qw(sum0);

=head1 NAME

LedgerSMB::Workflow::Action::Reconciliation - Collection of actions for reconciliations

=head1 SYNOPSIS

  <action name="submit"
          class="LedgerSMB::Workflow::Action::Reconciliation"
          entrypoint="submit" />

=head1 DESCRIPTION

=head1 PROPERTIES

=head2 entrypoint

The actual operation the C< execute > routine should delegate to.

Available values:

=over 8

=item * approve

=item * delete

=item * submit

=item * reject

=back

=cut

my @PROPS = qw( entrypoint );
__PACKAGE__->mk_accessors( @PROPS );

=head1 METHODS

=head2 init

Called during initialization to set up the instance properties.

=cut

sub init($self, $wf, $params) {
    $self->SUPER::init($wf, $params);

    $self->entrypoint( $params->{entrypoint} );
}

=head2 execute

Used by the workflow engine to dispatch work to the action instance.

=cut

sub execute($self, $wf) {
    if ($self->entrypoint eq 'approve') {
        $self->_approve( $wf );
    }
    elsif ($self->entrypoint eq 'delete') {
        $self->_delete( $wf );
    }
    elsif ($self->entrypoint eq 'submit') {
        $self->_submit( $wf );
    }
    elsif ($self->entrypoint eq 'reject') {
        $self->_reject( $wf );
    }
}

sub _approve($self, $wf) {
    $wf->context->param( 'approved', 1 );
}

sub _delete($self, $wf) {
    $wf->context->param( 'deleted', 1 );
}

sub _submit($self, $wf) {
    $wf->context->param( 'submitted', 1 );
}

sub _reject($self, $wf) {
    $wf->context->param( 'rejected', 1 );
}



1;

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2024 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

