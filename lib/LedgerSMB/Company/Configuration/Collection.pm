package LedgerSMB::Company::Configuration::Collection;

=head1 NAME

LedgerSMB::Company::Configuration::Collection - Collection of CoA nodes

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

use Moose::Role;
use namespace::autoclean;


requires '_resultset';
requires '_class';

sub _map_field {
    my ($self, $field) = @_;
    return $field;
}

sub _instantiate {
    my ($self, $row, @args) = @_;
    my $class = $self->_class;
    return $class->new(@args);
}

=head2 get

Examples:

  $sic = $sics->get(by => (code => '1221'));

  @sic = $sics->get(offset => 50, limit => 25);

  @sic = $sics->get(filter => q{code < '1231'},
                    limit => 25);

  @sic = $sics->get(order => 'code', limit => 25);

=cut


sub get {
    my $self = shift;
    my @args = @_;

    my $offset = 0;
    my $limit = undef;
    my $where = 'true';
    my @qargs = ();
    while (@args) {
        my $key = shift @args;
        my $val = shift @args;

        if ($key eq 'by') {
            if (ref $val) { # expect array ref
            }
            else {
                # remap
                $val = $self->_map_field($val);
                $where .= ' AND (' . $self->dbh->quote_identifier($val)
                                 . ' = ?)';
                push @qargs, shift @args;
            }
        }
        elsif ($key eq 'limit') {
            $limit = pop @args;
        }
        elsif ($key eq 'offset') {
            $offset = pop @args;
        }
        elsif ($key eq 'filter') {
            my $filter = pop @args;
            $where .= ' AND (' . (shift @$filter) . ')';
            push @qargs, @$filter;
        }
        elsif ($key eq 'order') {
            ##TODO
        }
    }
    my $inner_query = $self->_resultset;
    my $sth = $self->dbh->prepare(
        qq{SELECT * FROM ($inner_query) x WHERE $where LIMIT ? OFFSET ?})
        or die $self->dbh->errstr;

    $sth->execute(@qargs, $limit, $offset)
        or die $sth->errstr;

    my @rows;
    my $deserializer =
        PGObject::Type::Registry->rowhash_deserializer(
            registry => 'default',
            types    => $sth->{pg_type},
            columns  => $sth->{NAME_lc},
        );
    while (my $row = $sth->fetchrow_hashref('NAME_lc')) {
        push @rows, $self->_instantiate(
            $row,
            # @args for new():
            dbh => $self->dbh,
            $deserializer->($row)->%*
            );
    }

    if (wantarray) {
        return @rows;
    }
    else {
        if (@rows < 2) {
            return shift @rows;
        }
        else {
            return \@rows;
        }
    }
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
