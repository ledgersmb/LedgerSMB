package LedgerSMB::Company::Configuration::SICs;

=head1 NAME

LedgerSMB::Company::Configuration::SICs - Collection of Industry Codes

=head1 SYNOPSIS

   use LedgerSMB::Database;
   use LedgerSMB::Company;

   my $dbh = LedgerSMB::Database->new( connect_data => { ... })
       ->connect;
   my $c   = LedgerSMB::Company->new(dbh => $dbh)->configuration
       ->industry_codes;

=head1 DESCRIPTION

Collection of Standardized Industry Codes providing access to existing codes
as well as providing an API to create (instantiate) new ones.

Note that these are the codes loaded into the database. The user needs to
load the coding system applicable for their jurisdiction themselves.

=cut


use warnings;
use strict;

use PGObject::Type::Registry;

use Moose;
use namespace::autoclean;
with 'LedgerSMB::Company::Configuration::Collection';

# required methods from Collection:

sub _resultset {
    return 'sic';
}

sub _class {
    return 'LedgerSMB::Company::Configuration::SIC';
}

use LedgerSMB::Company::Configuration::SIC;

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

Instantiates a new SIC code, associated with the database
that the collection is associated with, passing C<@args> to the
constructor.

=cut

sub create {
    my $self = shift;

    my $v = LedgerSMB::Company::Configuration::SIC->new(
        dbh => $self->_dbh,
        @_
        );

    return $v;
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

__PACKAGE__->meta->make_immutable;

1;
