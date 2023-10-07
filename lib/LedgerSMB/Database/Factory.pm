
package LedgerSMB::Database::Factory;

=head1 NAME

LedgerSMB::Database::Factory - A source of database connections

=head1 SYNOPSIS

  db:
    $class: LedgerSMB::Database::Factory
    connect_data:
      host: localhost
      port: 5432

=head1 DESCRIPTION

This module exists to create database connections with preconfigured
C<connect_data> as it would have been passed to
L<PGObject::Util::DBAdmin/connect>. That class takes authentication data
in its C<connect_data> which isn't available at instantiation time of this
module, because it is different for each connection.

This module works around that by mixing in the authentication parameters
and instantiating the instance when the authentication data becomes
available.

=cut

use strict;
use warnings;

use Moo;

our $VERSION = '0.0.1';


use LedgerSMB::Database;

=head1 ATTRIBUTES

=head2 connect_data

Connection data provided upon instantiation of the factory. This data
will be used as the base configuration for each database instance to
be created.

For the available values for this hash, please consult the
L<PGObject::Util::DBAdmin> documentation.

=cut

has connect_data => (is => 'ro', required => 1);

=head2 schema

The name of the schema in which the LedgerSMB modules, tables and views
have been loaded. When none is provided, the default ('public') is assumed.

=cut

has schema => (is => 'ro', default => 'public');

=head2 data_dir

Indicates the path to the directory which holds the 'initial-data.xml' file
containing the reference and static data to be loaded into the base schema.

The default value is relative to the current directory, which is assumed
to be the root of the LedgerSMB source tree.

=cut

has data_dir => (is => 'ro', default => './locale');

=head2 source_dir

Indicates the path to the directory which holds the 'Pg-database.sql' file
and the associated changes, charts and gifi files.

The default value is relative to the current directory, which is assumed
to be the root of the LedgerSMB source tree.

=cut

has source_dir => (is => 'ro', default => './sql');

=head1 METHODS

=head2 instance( user => $username, password => $password, %overriden_connect_data )

Generates a C<LedgerSMB::Database> instance which can be used to create a
C<DBI> database connection from, using the C<connect> method.

Mixes the provided C<$username> and C<$password> into the connection data
provided at factory instantiation, upon instantiating the new database.

=cut

sub instance {
    my $self = shift;
    my %args = @_;

    return LedgerSMB::Database->new(
        connect_data => {
            host => 'localhost',
            port => 5432,
            $self->connect_data->%*,
            %args
        },
        schema     => $self->schema,
        data_dir   => $self->data_dir,
        source_dir => $self->source_dir);
}



1;


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2022 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

