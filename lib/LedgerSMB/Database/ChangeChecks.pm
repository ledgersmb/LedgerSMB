
package LedgerSMB::Database::ChangeChecks;

use strict;
use warnings;

use Exporter 'import';
use File::Spec;
use MIME::Base64;

our @EXPORT =  ## no critic
    qw| check grid confirm describe provided save_grid dropdowns_sql |;
our @EXPORT_OK = qw| run_with_formatters run_checks load_checks |;

our @checks;

=head1 NAME

LedgerSMB::Database::ChangeChecks - Data validation checks for schema changes

=head1 DESCRIPTION

This module provides the DSL necessary to build the checks being
executed before schema change scripts are being run.

Additionally, it defines an API to be used to implement user interfaces. This
API is further detailed in the L</FORMATTERS> section at the end of this
document.

Lastly, the module implements a few driver functions (described in the
L</FUNCTIONS> section of this document).

=head1 SYNOPSIS

  package SomePackage;

  use LedgerSMB::Database::ChangeChecks;

  check "The first check",
     query => qq|SELECT * FROM a_table|,
     description => qq|... extensive description for the user ... |,
     tables => {
        'table_a' => { prim_key => [ 'a', 'b' ] },
        ...
     },
     on_failure => sub {
         my ($dbh, $rows) = @_;

         grid $rows,
           name => 'grid',
           id => 'id',
           table => 'table_a',
           columns => [ 'column1', 'column2', ... ] # column subset
           edit_columns => [ ... one or more columns ..],
           dropdowns => {
             column1 => {
                 value1 => "Text 1",
                 ...,
             },
             column2 => dropdowns_sql($dbh, "SELECT value, text FROM b_table"),
           };
     },
     on_submit => sub {
         my ($dbh, $inputs) = @_;

         save_grid $inputs,
           id => 'id',
           name => 'grid',
           table => 'a_table';
     };

  check "The second check",
     query => qq|SELECT * FROM a_table|,
     description => qq|... extensive description for the user ... |,
     on_failure => sub {
         my ($dbh, $rows) = @_;

         choice { remove => 'Remove', retain => 'Retain' };
     },
     on_submit => sub { ... };


  1;

=head1 METHODS

This module declares no methods.

=head1 FUNCTIONS

Modules designed to run checks and/or bind a user interface
to perform user interaction for failing checks, may want to use
these functions.

These functions need to be explicitly imported into a using module
(as they are marked C<@EXPORT_OK>, but not C<@EXPORT>).

=head2 load_checks( $path )

Loads the check definitions from the file designated by C<$path>, returning
the checks as a list. C<$path> will be either a filesystem path or a file
handle reference.

Unless the input specifies its own C<package> scope, the input will be
imported into the C<main::> package. It's highly recommended to define
a package scope in the input.

B<SECURITY WARNING>: Please note that the file indicated by C<$path> is
  being evaluated (executed). It's considered insecure to pass
  relative paths to this function.

=cut

sub load_checks {
    my ($path) = @_;

    local @checks = ();

    # for security reasons only load files from absolute path locations
    $path = File::Spec->rel2abs($path)
        unless ref $path;
    {
        package main; ## no critic
        # Run in the main package in order not to polute the check runner
        # package; pre-check files are supposed to declare their own package
        # name if they don't want to run in 'main'.

        local ($!, $@) = (undef, undef);

        if (ref $path) { # $path should be a file handle
            local $/ = undef;
            my $content = <$path>;
            unless ( eval $content ) {
                if ( $@ ) {
                    die "Schema-upgrade pre-check failed: $@";
                }
            }
        }
        elsif ( -e $path ) {
            unless ( do $path ) {
                if ($! or $@) {
                    die "Schema-upgrade pre-check failed: $@";
                }
            }
        }
        else {
            die "Schema-upgrade pre-check failed: '$path' doesn't exist"
        }

    }

    my %checks_count;
    $checks_count{$_}++ for ( map { $_->{title} } @checks );
    unless (ref $path) {
        $_->{path} = $path for @checks;
    }

    die 'Multiple checks with the same name not supported'
        if grep { $checks_count{$_} > 1 } keys %checks_count;

    return @checks;
}



our $check;

=head2 run_with_formatters($block, $formatters)

Sets up a context of L</FORMATTERS> given in C<$formatters>
and runs the C<$block> in this context, returning the block's
return value(s).

C<$formatters> is a hash reference with the names of the L</FORMATTERS>
as the hash keys (C<confirm>, C<describe>, C<grid>, C<provided>). The
values are coderefs of functions following the respective formatter protocols.
When one of the functions isn't provided, it's bound to a failure-generating
coderef.

=cut


sub run_with_formatters(&$) { ## no critic
    my ($block, $formatters) = @_;

    for my $fmt (qw|describe confirm grid provided|) {
        $formatters->{$fmt} //=
            sub { die "$fmt: not provided in current context" }
    }

    no warnings 'redefine'; ## no critic
    local (*_describe, *_confirm, *_grid, *_provided) =
        @{$formatters}{qw(describe confirm grid provided)};

    return $block->();
}


#
#
#  infrastructure to actually run the checks
#
#

sub _run_check {
    my $dbh = shift;
    local $check = shift;

    my @rows =
        $dbh->selectall_array(
            $check->{query},
            {
                Slice => {},
                RaiseError => 1,
            });
    die "Failed to execute query of check '$check->{title}': " . $dbh->errstr
        if defined $dbh->errstr;
    return 0 unless (@rows);

    if (provided()) {
        my @grids;
        run_with_formatters {
            # collect configuration of 'grid' keywords
            $check->{on_failure}->($dbh, []);
        } {
            confirm => sub {},
            describe => sub {},
            grid => sub {
                shift; # discard the check
                shift; # discard the failing rows ref
                push @grids, { @_ };
            },
            provided => sub {},
        };

        $check->{grids} = { map { $_->{name} => $_ } @grids };
        $check->{on_submit}->($dbh, \@rows);

        @rows =
            $dbh->selectall_array(
                $check->{query},
                {
                    Slice => {},
                    RaiseError => 1,
                });
        return 0 unless (@rows);
    }

    $check->{on_failure}->($dbh, \@rows);
    return 1;
}

=head2 run_checks( $dbh, checks => [ .. ] )

Runs checks previously loaded using C<load_checks> contained in the
array reference of the C<checks> argument.

Checks are being run against the database identified by C<$dbh>,
which must be opened by database superuser or the database owner (i.e.
a LedgerSMB database admin).

Returns true when checks have successfully completed, false if one of the
checks has failed. For the failing check, the C<on_failure> event has been
called on return.

The caller is expected to repeat the C<run_checks> call with a C<provided>
formatter bound to a function which provides replacement values to update
the table content with, in case of an unsuccessful return.

=cut

sub run_checks {
    my ($dbh, %args) = @_;
    my $checks = $args{checks};

    foreach my $c (@$checks) {
        my $rc = _run_check($dbh, $c);

        return 0 if $rc;
    }

    return 1;
}


=head1 DSL keywords for check definition

The keyword(s) in this section will be automatically imported into
the active namespace when this module is C<use>d. It's therefore highly
recommended to declare a specific namespace in each file using this
module.

Checks defined in an input file are distinguished by their declared
title. It's therefore not possible to declare multiple checks with
the same title in a single file.

=head2 check( $title, ... )

Defines a query to be run as part of schema upgrades. Each check requires
a title and a number of keyword arguments. The title is used to present
the check to the user; it's meant as a short description.

Further keyword arguments are:

=over

=item description

I<Required>. Contains a longer description of what the check means to achieve
and explains which options the user is being presented with and what the
user is supposed to do to resolve the situation.

The string is interpreted as
L<Markdown|https://daringfireball.net/projects/markdown/>.

=item tables

I<Required> when a check involves either the C<grid> or C<save_grid>
DSL keywords.

Contains a hash reference with table names as the keys and hashes of
table attributes as the values. These attributes prevent duplication
of arguments across the C<grid> and C<save_grid> keywords.

   tables => {
       'some-table' => {
          prim_key   =>  [ 'a', 'b', 'c' ],
       },
       'some-other-table' => {
          prim_key   =>  [ 'd', 'e', 'f' ],
       }
   }


=item query

I<Required>. Specifies the SQL query to be run to identify data non-compliant
with the intended change to be applied. This query returns those rows failing
the compliance check. When this query returns any rows, the check is
considered to have "failed", causing the C<on_failure> event to be triggered.

Note that the query may be executed multiple times during the upgrade
process. The query may therefore not modify the database in any way.

=item on_failure

I<Required>. A coderef pointing to a function of 3 argument.

   sub {
      my ($check, $dbh, $rows) = @_;

      describe;
      grid $rows,
        table => 'some-table'
        name => 'the-grid';
      confirm left => 'Left', right => 'Right';
   }

=over

=item $check

A hashref holding the check's configuration as defined in the source.

=item $dbh

The database handle against which the check query was run.

=item $rows

An arrayref holding the rows which failed the check -- i.e. those returned
by the C<query>.

=back

The on_failure coderef makes use of the user interface defining
elements of the pre-check DSL: C<grid>, C<confirm>, C<dropdowns_sql>.

The number of times the C<on_failure> function is executed is undefined and
the function is likely to be run multiple times, possibly even within a single
invocation of C<run_tests>.

=item on_submit

I<Required>. A coderef pointing to a function of 2 arguments.

   sub {
      my ($dbh, $rows) = @_;

      save_grid $dbh, $rows,
        name => 'the-grid',
        table => 'some-table';
   }

=over

=item $dbh

The database handle against which the check query was run.

=item $rows

The failing rows, retrieved from the database. These rows can be
used to validate input provided through the UI for validity. This
process has been implemented in C<save_grid>, which will only accept
modified values for internally identified failing rows -- as a measure
for security.

=back

The 'on_submit' coderef makes use of the data-modifying elements of the
pre-check DSL: C<save_grid>. Alternatively, the code can use the C<$dbh>
provided to directly modify the database contents.

=back

=cut

sub check {
    my @args = @_;
    my ($title, %args) = @args;

    die "Check '$title' doesn't define a query"
        unless $args{query};
    die "Check '$title' doesn't define a description"
        unless $args{description};
    die "Check '$title' doesn't define 'on_submit'"
        unless $args{on_submit};
    die "Check '$title' doesn't define 'on_failure'"
        unless $args{on_failure};

    $args{title} = $title;
    push @checks, \%args;
}



=head1 DSL keywords for 'on_failure' event

This event will be triggered when a query returns any rows, indicating
the schema contains data not compliant with the intended change.

The general purpose for this event is to define the UI to be presented
as required to make the data pass the compliance check.

Please note that the code in this event should not modify the database
or any context in general: the code may be run more than once and the
code may even be run with different formatters bound than expected.

=cut

#################################
#
# DSL for 'on_failure' event
#
#################################


=head2 describe [ $msg ]

Used to explain the test that has been performed and the repair
options shown as well as what the user is expected to do in order
to resolve the problem detected.

Without C<$msg>, presents the content of the C<description> as
provided through the check definition statement.

=cut

sub _describe {
    # placeholder; bound to a real function by run_with_formatters()
    die q{'describe' can't be called outside run_with_formatters scope};
}

sub describe {
    return _describe($check, @_);
}


=head2 confirm [ value1 => 'Description1', value2 => ..., ... ]

Used to render confirmation options for the user to
confirm the data entered. The intended way to render a confirmation
is to render a button.

=cut

sub _confirm {
    # placeholder; bound to a real function by run_with_formatters()
    die q{'confirm' can't be called outside run_with_formatters scope};
}

sub confirm {
    return _confirm($check, @_);
}

=head2 grid $rows, [ name => $string, table => $string, ... ]

Used to render a grid with the rows as indicated in the C<$rows> arrayref.

The following keys are available:

=over

=item name

I<Required>. Names the grid in order to be able to extract the (changed)
values from the returned data through the C<provided> dsl keyword.

=item table

I<Optional>. Names one of the tables specified through the C<tables>
keyword of the check definition.

When the name of the grid equals the name of one of the tables in the
check as provided through the C<tables> keyword, there's no need to
specify this keyword.

=item columns

I<Required>. Names the columns to be rendered (visibly) on the UI.

=item edit_columns

I<Required>. Names the columns which should be editable on the UI. This
should be a subset of C<columns>.

=item dropdowns

I<Optional>. Contains a hashref with the keys being a subset of the
columns for which a dropdown should be rendered and the values being
hashrefs mapping the values of the field to descriptions.

A column doesn't need to be editable in order for a dropdown to be applied;
the UI is supposed to show a read-only dropdown element when the column
is marked as dropdown but not as editable.

For an example see the L</SYNOPSIS> section above.

=back

=cut

sub _grid {
    # placeholder; bound to a real function by run_with_formatters()
    die q{'grid' can't be called outside run_with_formatters scope};
}

sub _assert_pk {
    my (%args) = @_;

    unless (defined $check->{tables}
            and ((defined $args{table}
                  and defined $check->{tables}->{$args{table}})
                 or (defined $args{name}
                     and defined $check->{tables}->{$args{name}}))) {
        die "Check '$check->{title}' misses table primary key in 'grid'";
    }
}

sub grid {
    my ($rows, %args) = @_;

    if ($args{edit_columns}) {
        # assert that the values in the rows hashes include values for
        # all fields of the primary key!
        #
        # and then generate the primary keys.
        _assert_pk(%args);

        my $pk = $check->{tables}->{$args{table} // $args{name}}->{prim_key};
        $pk = (ref $pk) ? $pk : [ $pk ];
        $_->{__pk} = _encode_pk($_, $pk) for (@$rows);
    }

    return _grid($check, @_);
}

=head2 dropdowns_sql($dbh, $query)

Expects a query with a two-column result; the first column being the values
expected in the column to which the dropdown is applied. The second being the
descriptions to be shown instead of the actual values in the column.

This function can be used in the "value" position of the key/value pairs
as meant in the C<dropdowns> keyword as shown in the L</SYNOPSIS> section
above.

=cut

sub dropdowns_sql {
    my ($dbh, $query) = @_;

    my $sth = $dbh->prepare($query) or die $dbh->errstr;
    $sth->execute                   or die $sth->errstr;

    return {
        map { $_->[0] => $_->[1] }
        @{$sth->fetchall_arrayref or die $sth->errstr}
    };
}


=head1 DSL keywords for 'on_submit' event

The 'on_submit' event is triggered when C<run_tests> detects a
check failure and C<provided> indicates there's corrective data
available to be applied for the check at hand.

Code in this event handler can make use of the database handle passed
and modify the database content directly. Alternatively, DSL keywords
are available to do some of the heavy-lifting and/or UI interaction.

=cut

#################################
#
# DSL for 'on_submit' event
#
#################################

=head2 provided [ $name [, key => value, ... ]

Used to access UI responses from elements named in the C<on_failure> phase.

See the documentation in the L<FORMATTERS> section.

=cut

sub _provided {
    # placeholder; bound to a real function by run_with_formatters()
    die q{'provided' can't be called outside run_with_formatters scope};
}

sub provided {
    return _provided($check, @_);
}


=head2 save_grid $dbh, $failed_rows [, name => $name, table => $table, ... ]

Iterates over C<$failed_rows>, finding input for those rows as provided in
the UI and applying the fixed data to the database using C<$dbh>. Parameters
are retrieved from the grid declaration with the same C<name> in the
C<on_failure> event. Arguments to this function can be used to override
the values in the C<grid> declaration.
The columns to be stored by this command are taken to be the C<edit_columns>
from that table.


The following keys are supported:

=over

=item name

I<Required>. The name of the grid to be saved; used as argument to
C<provided> to query the replacement data.

=item table

I<Optional>. The name of the table to save the data to. If not provided,
defaults to the value provided in the C<name> argument.

=item edit_columns

I<Optional>. Overrides the value of the columns to be saved as would
have been taken from the associated grid declaration.

=back

=cut

sub save_grid {
    my ($dbh, $failed_rows, %call_args) = @_;

    my $name = $call_args{name};
    # assert that a name is provided
    # assert that a grid by that name has been defined

    my %grid_args;
    if (defined $check->{grids}
        and defined $check->{grids}->{$name}) {
        %grid_args = %{$check->{grids}->{$name}};
    }
    _assert_pk(%grid_args);

    my %args = ( %grid_args, %call_args );
    # don't take any risk:
    # the sources providing the table name *are* dynamically loaded..
    my $table = $dbh->quote_identifier($args{table} // $name);
    my $pk = $check->{tables}->{$args{table} // $name}->{prim_key};
    $pk = (ref $pk) ? $pk : [ $pk ];

    my @fields = @{$args{edit_columns}};
    my $set_fields = join(', ',
                          map { $dbh->quote_identifier($_) . ' = ?' }
                          @fields);
    my $where = join(' and ',
                     map { $dbh->quote_identifier($_) . ' = ?' }
                     @$pk);
    my $query = qq|UPDATE $table
                      SET $set_fields
                    WHERE $where|;
    my $sth = $dbh->prepare($query) or die $dbh->errstr;

    $_->{__pk} = _encode_pk($_, $pk) for (@$failed_rows);
    my %ui_rows = map { $_->{__pk} => $_ } @{provided $name};
    for my $row (grep { exists $ui_rows{$_->{__pk}} } @$failed_rows) {
        # note that we're *explicitly* iterating over the data provided through
        # the safe channel, only to find out if the unsafe channel
        # provided replacement data for it. That way, the unsafe channel
        # can't be used to overwrite good data.

        $sth->execute((map { $ui_rows{$row->{__pk}}->{$_} } @fields),
                      (map { $row->{$_} } @$pk ))
            or die $sth->errstr;
    }
}




#############################
#
#
# Common helper functions
#
#############################

sub _encode_pk {
    my ($row, $pk_fields) = @_;

    return join(' ', map { defined $_ ? encode_base64($_, '') : '[n]' }
                map { $row->{$_} if exists $row->{$_}; } @$pk_fields);
}

sub _decode_pk {
    my ($pk_value, $pk_fields) = @_;

    return [ map { $_ eq '[n]' ? undef : decode_base64($_) }
             split(/ /, $pk_value) ];
}

=head1 FORMATTERS

Formatters implement the UI of the checks. This way, the UI can be anything
from a web request/response based implementation to a terminal/ncurses solution.

The formatters have the same arguments as their API equivalents, except that
each formatter has a reference to the C<$check> in progress prepended to the
argument list. E.g. C<grid $check, $rows, ...>.

Formatters implement callbacks that will be called from the checks while
processing any of the events. During the C<on_failure> event, this usually will
mean output generation, while the C<on_submit> event will want to query the UI
for input provided.

The following output hooks have to be provided, all quite high level, leaving
the implementation with lots of room to render the output.

=over

=item confirm

Offers the user a way to indicate (s)he is done providing input for
the given event.

=item describe

Shows the check's title and long description, informing the user
about the intent of the check and the implications of the various
resolutions offered.

The long description must be interpreted as Markdown and should
be formatted appropriately for the target UI.

=item grid

Renders a grid with the columns indicated in the arguments. For each
row, there's one magic column that needs to be reproduced in the
C<on_submit> event which isn't listed in any of the columns: the C<__pk>
column.

=back

Next to the output formatters, these input-requesting routines are to
be supplied:

=over

=item provided $check [, $name ]

Called to retrieve input provided to the UI.

When called without parameters, returns a boolean value indicating whether
any inputs are available for processing at all for the given check. In other
words, during the C<on_failure> phase, this callback is supposed to return a
falsy value, while in the C<on_submit> phase, a true-ish value must be returned.

When called with a C<$name> argument, the value(s) of a specific element
rendered in the C<on_failure> phase for the given C<$check> must be returned.
These are the expected return value types per named rendered output:

The name of the C<confirm> UI elements is "confirm".

=item grid

C<grid> inputs are returned using an arrayref of hashrefs holding at least
the magical C<__pk> column value and the values of the columns named in
C<edit_columns>.

Note that the composition of the values in the C<__pk> column is explicitly
declared internal (and thus can't be depended upon).

=item confirm

Returns the value associated with the selected/pressed/clicked description.

=back

=head1 LICENSE AND COPYRIGHT

Copyright(C) 2018 The LedgerSMB Core Team.

This file may be reused under the terms of the GNU General Public License
version 2 or at your option any later version.  Please see the included
LICENSE.TXT for more information.

=cut

1;
