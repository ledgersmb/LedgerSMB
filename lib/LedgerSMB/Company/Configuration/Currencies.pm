package LedgerSMB::Company::Configuration::Currencies;

=head1 NAME

LedgerSMB::Company::Configuration::Currencies - Collection of currencies

=head1 SYNOPSIS

   use LedgerSMB::Database;
   use LedgerSMB::Company;

   my $dbh = LedgerSMB::Database->new( connect_data => { ... })
       ->connect;
   my $c   = LedgerSMB::Company->new(dbh => $dbh)->configuration
       ->currencies;

   # set default currency
   $c->default('USD');

=head1 DESCRIPTION

Collection of configured currencies providing access to existing ones
as well as providing an API to create (instantiate) new ones.


=cut


use warnings;
use strict;

use Log::Any qw($log);

use PGObject::Type::Registry;

use Moose;
use namespace::autoclean;
with 'LedgerSMB::Company::Configuration::Collection';

# required methods from Collection:

sub _resultset {
    return 'currency';
}

sub _class {
    return 'LedgerSMB::Company::Configuration::Currency';
}

use LedgerSMB::Company::Configuration::Currency;

=head1 ATTRIBUTES

=cut

has _dbh => (is => 'ro', init_arg => 'dbh', reader => 'dbh', required => 1);


=head1 CONSTRUCTOR ARGUMENTS

In addition to the attributes from the previous section, the following
named arguments can (or even must) be provided to the C<new> constructor.

=head2 dbh (required)

The database access handle. This is provided upon instantiation by the
C<LedgerSMB::Company::Configuration> collection.

=head1 METHODS

=head2 create(@args)

Instantiates a new currency, associated with the database
that the collection is associated with, passing C<@args> to the
constructor.

=cut

sub create {
    my $self = shift;

    my $v = LedgerSMB::Company::Configuration::Currency->new(
        _dbh => $self->dbh,
        @_
        );

    return $v;
}

=head2 default([$code])

Returns the code for the default currency when
C<$new_value> isn't provided, or when it is, sets it to the value provided.

=cut

sub default {
    my $self = shift;
    my $newvalue = shift;

    my $oldvalue;
    if (defined $newvalue) {
        $log->infof('Setting default currency to "%s"', $newvalue);
        $self->dbh->do(
            q{INSERT INTO defaults (setting_key, value) VALUES ('curr', $1)
            ON CONFLICT (setting_key) DO UPDATE SET value = $1}, {},
            $newvalue);
    }
    return $oldvalue;
}


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

__PACKAGE__->meta->make_immutable;

1;
