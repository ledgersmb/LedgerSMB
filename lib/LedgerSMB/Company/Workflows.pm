
use v5.38;

package LedgerSMB::Company::Workflows;

use Moo;
use namespace::autoclean;

=head1 NAME

LedgerSMB::Company::Workflows - Creation and retrieval of workflows

=head1 SYNOPSIS

  use LedgerSMB::Company;

  my $c = LedgerSMB::Company( dbh => $dbh, wire => $wire );
  my $w = $c->workflows;

=head1 DESCRIPTION

Manages workflows. Workflows are used to model resource life-cycle
and end-user processes.

=head1 ATTRIBUTES

=head2 app

Reference to the main application instance.

=cut

has _app => (
    is       => 'ro',
    init_arg => 'app',
    reader   => 'app',
    weak_ref => 1,
    required => 1);

=head1 METHODS

=head2 create

  my $wf = $workflows->create( $type, [$context] );

Creates a new workflow of type C<$type>, which corresponds with the type
from the workflow configuration. The C<$context> is a hash to be used
to seed the workflow context.

=cut

sub create($self, $type, $ctx = undef) {
    my $wf = $self->app->wire->get('workflows')->create_workflow( $self->app, $type, $ctx );
    $wf->{handle} = $self->app->dbh; # can't call setters... ugh

    return $wf;
}

=head2 fetch

  my $wf = $workflows->fetch( $type, $id, [$context] );

Retrieves an existing context by C<$type> and C<id>.

=cut

sub fetch($self, $type, $id, $ctx = undef) {
    my $wf = $self->app->wire->get('workflows')->fetch_workflow( $self->app, $type, $id, $ctx );
    $wf->{handle} = $self->app->dbh; # can't call setters... ugh

    return $wf;
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.
