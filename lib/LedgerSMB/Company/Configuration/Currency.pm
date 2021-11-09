package LedgerSMB::Company::Configuration::Currency;

=head1 NAME

LedgerSMB::Company::Configuration::Currency - Currency configuration

=head1 SYNOPSIS

   use LedgerSMB::Database;
   use LedgerSMB::Company;

   my $dbh  = LedgerSMB::Database->new( connect_data => { ... })
       ->connect;
   my $c    = LedgerSMB::Company->new(dbh => $dbh)->configuration->currencies;
   my $curr = $c->create(code => 'EUR',
                        description => 'Euro');

   $curr->save;

=head1 DESCRIPTION

Configuration of currencies.

=cut


use warnings;
use strict;

use Log::Any qw($log);

use Moose;
use namespace::autoclean;
with 'LedgerSMB::PGObject::Role';

=head1 ATTRIBUTES

=head2 code (required)

3-character currency denomination code. Preferably the official code as
published in L<ISO 4217|https://www.currency-iso.org/en/home.html>.

Read-only.

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
C<LedgerSMB::Company::Configuration::Currencies> collection.

=head1 METHODS

=head2 delete

Deletes the currency. Note that this function cannot succesfully complete
when the currency is being referenced in transactions or other configuration
items.

=cut

sub delete {
    my $self = shift;

    $self->call_dbmethod(funcname => 'config_currency__delete');
}

=head2 save

Saves a created or changed currency into the company configuration.

=cut

sub save {
    my $self = shift;

    $log->infof('Saving currency %s (%s)', $self->code, $self->description);
    $self->call_dbmethod(funcname => 'config_currency__save');

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
