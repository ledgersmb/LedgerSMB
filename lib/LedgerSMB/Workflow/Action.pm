package LedgerSMB::Workflow::Action;

=head1 NAME

LedgerSMB::Workflow::Action - Base 'Action' class

=head1 SYNOPSIS

  # action configuration
  <actions>
    <action name="send" class="LedgerSMB::Workflow::Action"
            order="12"
            short-help="Causes the input to be sent to the customer"
            text="Send" />
  </actions>


=head1 DESCRIPTION

This module implements the base for every action class in LedgerSMB
by adding a few fields in order to separate the concerns of UI presentation
of an action (C<text> attribute) and its internal identification (C<name>).

This class does not implement a C<execute> method itself.

=head1 ATTRIBUTES

=head2 order

This is a numeric value which determines the position of the UI
element in relation to other action-UI elements. Actions are sorted
in ascending numerical order.

=head2 short_help

This is a short explanation of the action which the UI should present
in a tooltip or popup (such as the C<title> attribute on HTML elements).

This attribute is mapped from the C<short-help> attribute in the workflow
specification.

=head2 text

This is the text that a UI element (e.g. a button) should present
on an element that triggers this action in the workflow.

=head2 doing

Notification to be shown in the UI while the action is being performed
in the backend.

=head2 done

Notification to be shown in the UI after the action successfully completes
in the backend.

=cut


use strict;
use warnings;
use parent qw( Workflow::Action );

use DateTime;
use Log::Any qw($log);


my @PROPS = qw( order short_help text doing done ui );
__PACKAGE__->mk_accessors(@PROPS);

=head1 METHODS

=cut

=head2 init($wf, $params)

Implements the C<Workflow::Action> protocol.

=cut

sub init {
    my ($self, $wf, $params) = @_;
    $self->SUPER::init($wf, $params);

    $self->order( $params->{order} )
        if exists $params->{order};
    $self->short_help( $params->{'short-help'} )
        if exists $params->{'short-help'};
    $self->doing( $params->{doing} )
        if exists $params->{doing};
    $self->done( $params->{done} )
        if exists $params->{done};
    $self->ui( $params->{ui} // 'regular' );

    ### This is a workaround for the fact that 'text' calls are
    # reserved by our maketext translation extractor
    $self->{text} = $params->{text}
        if exists $params->{text};
}

1;

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2022 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

