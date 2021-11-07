package LedgerSMB::Company::Configuration::SIC;

=head1 NAME

LedgerSMB::Company::Configuration::SIC - SIC configuration

=head1 SYNOPSIS

   use LedgerSMB::Database;
   use LedgerSMB::Company;

   my $dbh = LedgerSMB::Database->new( connect_data => { ... })
       ->connect;
   my $c   = LedgerSMB::Company->new(dbh => $dbh)->configuration
       ->industry_codes;
   my $sic = $c->create(code => '001',
                        description => 'Cultivos agricolas');

   $sic->save;

=head1 DESCRIPTION


=cut


use warnings;
use strict;

use Moose;
use namespace::autoclean;
with 'LedgerSMB::PGObject::Role';

=head1 ATTRIBUTES

=head2 code (required)

SIC code. Read-only.

=cut

has code => (is => 'ro', required => 1);

=head2 sictype

Single character. A value of 'H' indicates an SIC heading.

=cut

has sictype => (is => 'rw');

=head2 description

One-line description of the SIC code. Read-write.

=cut

has description => (is => 'rw');

=head1 CONSTRUCTOR ARGUMENTS

In addition to the attributes from the previous section, the following
named arguments can (or even must) be provided to the C<new> constructor.

=head2 dbh (required)

The database access handle. This is provided upon instantiation by the
C<LedgerSMB::Company::Configuration::SICs> collection.

=head1 METHODS

=head2 delete

Deletes the SIC code. Note that this function cannot succesfully complete
when the code is being referenced in customers, vendors or other configuration
items.

=cut

sub delete {
    my $self = shift;

    $self->call_dbmethod(funcname => 'config_sic__delete');
}

=head2 save

Saves a created or changed SIC code into the company configuration.

=cut

sub save {
    my $self = shift;

    $self->call_dbmethod(funcname => 'config_sic__save');

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
