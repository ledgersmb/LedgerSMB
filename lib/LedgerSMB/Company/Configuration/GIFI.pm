package LedgerSMB::Company::Configuration::GIFI;

=head1 NAME

LedgerSMB::Company::Configuration::GIFI - GIFI code configuration

=head1 SYNOPSIS

   use LedgerSMB::Database;
   use LedgerSMB::Company;

   my $dbh  = LedgerSMB::Database->new( connect_data => { ... })
       ->connect;
   my $c    = LedgerSMB::Company->new(dbh => $dbh)->configuration->currencies;
   my $gifi = $c->create(code => '1000',
                         description => 'Cash & Deposits');

   $gifi->save;

=head1 DESCRIPTION

Configuration of GIFI codes.

=cut


use warnings;
use strict;

use Log::Any qw($log);

use Moose;
use namespace::autoclean;
with 'LedgerSMB::PGObject::Role';

=head1 ATTRIBUTES

=head2 code (required)

GIFI code. Unique. Read-only.

=cut

has code => (is => 'ro', required => 1);

=head2 description

One-line description of the currency. Read-write.

=cut

has description => (is => 'rw');

=head1 CONSTRUCTOR ARGUMENTS

In addition to the attributes from the previous section, the following
named arguments can (or even must) be provided to the C<new> constructor.

=head2 dbh (required)

The database access handle. This is provided upon instantiation by the
C<LedgerSMB::Company::Configuration::GIFIs> collection.

=head1 METHODS

=head2 delete

Deletes the code. Note that this function cannot succesfully complete
when the GIFI code is being referenced in accounts or other configuration
items.

=cut

sub delete {
    my $self = shift;

    $self->call_dbmethod(funcname => 'config_gifi__delete');
}

=head2 save

Saves a created or changed GIFI code into the company configuration.

=cut

sub save {
    my $self = shift;

    $log->infof('Saving GIFI %s (%s)', $self->code, $self->description);
    $self->call_dbmethod(funcname => 'config_gifi__save');

    # 'code' is the primary key of the table, so we don't need to
    # process the return value back into $self
}



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

__PACKAGE__->meta->make_immutable;

1;
