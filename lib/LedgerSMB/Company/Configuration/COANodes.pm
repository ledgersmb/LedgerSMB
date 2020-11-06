package LedgerSMB::Company::Configuration::COANodes;

=head1 NAME

LedgerSMB::Company::Configuration::COANodes - Collection of CoA nodes

=head1 SYNOPSIS

   use LedgerSMB::Database;
   use LedgerSMB::Company;

   my $dbh = LedgerSMB::Database->new( connect_data => { ... })
       ->connect;
   my $c   = LedgerSMB::Company->new(dbh => $dbh)->configuration->coa_nodes;

   # look up a heading or account
   my $node   = $c->get(by => (accno => 'H-1500'));

   # create a new node (account)
   my $new    = $c->create(type        => 'account',
                           accno       => '1501',
                           description => 'Account 1501',
                           heading_id  => $node->id);

=head1 DESCRIPTION

Collection of Chart of Accounts nodes (accounts and headings) providing
access to existing nodes as well as providing an API to create (instantiate)
new ones.

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
    return q{
        SELECT 'A-'||id as id,
               accno, description, category, gifi_accno,
               'H-'||heading as heading_id, contra,
               tax, obsolete, false as is_heading
        FROM account
        UNION ALL
        SELECT 'H-'||id as id,
               accno, description, category, null,
               'H-'||parent_id, null,
               null, null, true
        FROM account_heading
};
}

sub _class {
    # unused, because we override 'instantiate'
    return '';
}

sub _instantiate {
    my ($self, $row, @args) = @_;
    if ($row->{is_heading}) {
        return LedgerSMB::Company::Configuration::Heading->new(@args);
    }
    else {
        return LedgerSMB::Company::Configuration::Account->new(@args);
    }
}

my %fieldmap = ( code => 'accno' );
sub _map_field {
    my ($self, $fieldname) = @_;
    return $fieldmap{$fieldname} // $fieldname;
}





use LedgerSMB::Company::Configuration::Account;
use LedgerSMB::Company::Configuration::Heading;

=head1 ATTRIBUTES

=cut

has _dbh => (is => 'ro', init_arg => 'dbh', reader => 'dbh', required => 1);


=head1 CONSTRUCTOR ARGUMENTS

In addition to the attributes from the previous section, the following
named arguments can (or even must) be provided to the C<new> constructor.

=head2 dbh (required)

The database access handle. This is provided upon instantiation by the
C<LedgerSMB::Company::Configuration::COANodes> collection.

=head1 METHODS

=head2 create( type => $type, @args )

Instantiates a new CoA node of type C<type>, associated with the database
that the collection is associated with.

C<type> can be either C<account> or C<heading>.

C<@args> are passed to the constructor of the indicated type,
C<LedgerSMB::Company::Configuration::Account> for type C<account> and
C<LedgerSMB::Company::Configuration::Heading> for type C<heading>.

=cut

sub create {
    my $self = shift;
    my %args = @_;

    my $v;
    if ($args{type} eq 'account') {
        $v = LedgerSMB::Company::Configuration::Account->new(
            _dbh => $self->dbh,
            @_
            );
    }
    elsif ($args{type} eq 'heading') {
        $v = LedgerSMB::Company::Configuration::Heading->new(
            _dbh => $self->dbh,
            @_
            );
    }
    else {
        die 'Unexpected account type';
    }

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
