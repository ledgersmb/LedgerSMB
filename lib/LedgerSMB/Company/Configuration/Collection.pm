package LedgerSMB::Company::Configuration::Collection;

=head1 NAME

LedgerSMB::Company::Configuration::Collection - Role to manage a collection

=head1 SYNOPSIS


   use Moose;
   use namespace::autoclean;
   with 'LedgerSMB::Company::Configuration::Collection';

   # Implement required functions

   sub _resultset {
      return 'a_table_or_query';
   }

   sub _class {
      return 'LedgerSMB::Company::Configuration::a_class';
   }

   ...;

   1;


=head1 DESCRIPTION

Implements the infrastructure required to manage a collection of objects
in the company database (such as querying).

=cut


use warnings;
use strict;

use Log::Any qw($log);
use PGObject::Type::Registry;

use Moose::Role;
use namespace::autoclean;

=head1 REQUIRED METHODS

The following methods must be implemented by the using class:

=head2 _resultset

Returns the name of a table or a query that can be used in its place,
e.g. 'gifi'. For a more complex example see the COANodes collection.

=head2 _class

Returns the name of the Perl class which mirrors the database object state,
e.g. C<LedgerSMB::Company::Configuration::GIFI>.

=cut

requires '_resultset';
requires '_class';

=head1 INTERNAL METHODS

=head2 _map_field($fieldname)

In case a field in the Perl mirror class has a different name than the backing
field in the database, the Perl code will use the name of the Perl mirror
instead of the database.

This function maps the name of the Perl mirror to the database when generating
the C<get()> query.

=cut

sub _map_field {
    my ($self, $field) = @_;
    return $field;
}

=head2 _instantiate($row, @args)

Is called for each returned row in the C<get()> query result to map the
database object into their Perl mirrors, returning one instance per call.

The default implementation uses C<@args> to instantiate an object of
type C<$self->_class()> and ignores C<$row>. For more involved instantiation
strategies see the COANodes collection for an example.

=cut

sub _instantiate {
    my ($self, $row, @args) = @_;
    my $class = $self->_class;
    return $class->new(@args);
}

=head1 METHODS

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
