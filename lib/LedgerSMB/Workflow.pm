
use v5.38;
use experimental qw(signatures);

package LedgerSMB::Workflow;

=head1 NAME

LedgerSMB::Workflow - Workflow class extended for use in LedgerSMB

=head1 SYNOPSIS

  # workflow configuration
  <workflow
     class="LedgerSMB::Worfklow"
     type="AR/AP">
   <description>Description of the workflow
   </description>
   <state name="INITIAL">
     ...
   </state>
   ...
  </workflow>


=head1 DESCRIPTION

This module enhances the regular C<Workflow> class with a C<handle> attribute
which caches the value of the attribute with the same name in the persister
associated with the workflow.

The purpose is to provide actions access to this handle.

=head1 PROPERTIES

=head2 handle (read-only)

Provides the C<DBI> handle of the associated company database.

=cut


use parent qw( Workflow );

use Carp qw(croak);
use DateTime;
use Log::Any qw($log);

my @PROPS = qw( app );
__PACKAGE__->mk_accessors(@PROPS);


=head1 METHODS

=head2 init(@params)

Implements the C<Workflow> protocol.

=cut

sub init($self, @params) {
    $self->SUPER::init(@params);

    # No need to initialize 'app': it is set by LedgerSMB::Workflow::Factory
}


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2024 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

