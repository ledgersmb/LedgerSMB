
package LedgerSMB::Database::ChangeChecks;

use strict;
use warnings;

use Exporter 'import';
use File::Spec;
use MIME::Base64;

our @EXPORT =  ## no critic
    qw| check grid confirm describe save_grid dropdowns_sql |;
our @EXPORT_OK = qw| run_with_formatters run_checks load_checks |;

our @checks;

=head1 NAME

LedgerSMB::Database::ChangeChecks - Data validation checks for schema changes

=head1 DESCRIPTION

This module provides the DSL commands necessary to build the checks being
executed before schema change scripts are being run.

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
             column1 => [ { value1 => "Text 1" },
                          ... ],
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


=head1 FUNCTIONS

=over

=item load_checks( $path )


Returns a list of checks defined in the file named by C<$path>.
Alternatively, C<$path> may be a file handle reference.


SECURITY WARNING: Please note that the file indicated by C<$path> is
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

    die 'Multiple checks with the same name not supported'
        if grep { $checks_count{$_} > 1 } keys %checks_count;

    return @checks;
}



our $check;

=item run_with_formatters($block, $formatters)

Runs C<$block> in a context with C<$formatters> set up.

The function returns the value(s) returned by C<$block>.

The function binds the following formatting functions:

=over

=item confirm

=item describe

=item grid

=item provided

=back

When one of the functions isn't provided, it's bound to a failure-generating
coderef

=cut


sub run_with_formatters(&$) { ## no critic
    my ($block, $formatters) = @_;

    $formatters->{$_} //= sub { die "$_: not provided in current context" }
        for (qw|describe confirm grid provided|);

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

=item run_checks( $dbh, checks => [ .. ] )

Runs checks previously loaded using C<load_checks> contained in the
array reference of the C<checks> argument.

Checks are being run against the database identified by handle C<$dbh>,
which must be opened by database superuser or the database owner (i.e.
a LedgerSMB database admin).

Returns true when checks have successfully completed, false if one of the
checks has failed. For the failing check, the C<on_failure> event has been
called on return.

The caller is expected to repeat the C<run_checks> call with a C<provided>
formatter bound to a function which provides replacement values to update
the table content with, in case it returns unsuccessfully.

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


=back

=head1 DSL keywords for check definition

=over

=item check( $title, ... )

Defines a query to be run as part of schema upgrades. Each check requires
a title and a number of keyword arguments. The title is used to present
the check to the user; it's meant as a short description.

Further keyword arguments are:

=over

=item description

Required. Contains a longer description of what the check means to achieve
and explains which options the user is being presented with and what the
user is supposed to do to resolve the situation.

=item tables

Required when a check involves either the C<grid> or C<save_grid> DSL keywords.

Contains a hash reference listing a series of hashes describing the tables
for which C<grid> (and possibly the associated C<save_grid>) functions will
be invoked.

   tables => {
       'some-table' => {
          pk   =>  [ 'a', 'b', 'c' ] },
       'some-other-table' => {
          pk   =>  [ 'd', 'e', 'f' ] }
   }


=item query

Has as its value a string specifying an SQL query which when executed returns
the rows violating the (part of) the change being applied.

When this query returns any rows, the check is considered to have "failed".

Note that the query may be executed multiple times during the upgrade
process. The query may therefor not modify the database in any way.

=item on_failure

Required. A coderef pointing to a function of 3 arguments:

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
elements of the pre-check DSL: C<grid>, C<confirm>, C<choice>, C<dropdowns_sql>.

The number of times the C<on_failure> function is executed is undefined and
the function is likely to be run multiple times, possibly even within a single
request.

=item on_submit

Required. A coderef pointing to a function of 3 arguments:

=over

=item $check

A hashref holding the check's configuration as defined in the source.

=item $dbh

The database handle against which the check query was run.

=back

The 'on_submit' coderef makes use of the data-modifying elements of the
pre-check DSL: save_grid.

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



=back

=head1 DSL keywords for 'on_failure' event

=over

=cut

#################################
#
# DSL for 'on_failure' event
#
#################################


=item describe [ $msg ]

Should be used to explain the test that has been performed and the repair
options shown as well as what the user is expected to do in order
to resolve the problem detected.

=cut

sub _describe {
    # placeholder; bound to a real function by run_with_formatters()
    die q{'describe' can't be called outside run_with_formatters scope};
}

sub describe {
    return _describe($check, @_);
}


=item confirm [ value1 => 'Description1', value2 => ..., ... ]

Used to render (multiple) confirmation options for the user to
confirm the data entered.

=cut

sub _confirm {
    # placeholder; bound to a real function by run_with_formatters()
    die q{'confirm' can't be called outside run_with_formatters scope};
}

sub confirm {
    return _confirm($check, @_);
}

=item grid $rows, [ key => $value ]

Used to render a grid with the rows as indicated in the C<$rows> hashref.

The following keys are available:

=over

=item name

Names the grid in order to be able to extract the (changed) values
from the returned data.

=item table

When a string value, names the column containing the primary key of the
target table. In case of an arrayref, lists the complex primary key.

Needed here as it allows the UI to be able to request
the primary key from the returned data later.

When the name of the grid equals the name of one of the tables in the
check as provided through the C<tables> keyword, there's no need to
specify this keyword as it'll be taken from the table definition.

=item columns

Names the columns to be rendered (visibly) on the UI, in the order the
UI is supposed to render them.

=item edit_columns

Names the columns which should be editable on the UI. This should be
a subset of C<columns>.

=item dropdowns

Contains an arrayref with the keys being a subset of the columns for which
a dropdown should be rendered and the values being hashrefs mapping the
values of the field to descriptions.

A column doesn't need to be editable in order for a dropdown to be applied;
the UI is supposed to show a read-only dropdown element when the column
is marked as dropdown but not as editable.

For an example see the SYNOPSIS section above.

=back

=cut

sub _grid {
    # placeholder; bound to a real function by run_with_formatters()
    die q{'grid' can't be called outside run_with_formatters scope};
}

sub grid {
    my ($rows, %args) = @_;
    # assert that the values in the rows hashes include values for
    # all fields of the primary key!
    #
    # and then generate the primary keys.
    my $pk = $check->{tables}->{$args{table} // $args{name}}->{prim_key};
    $pk = (ref $pk) ? $pk : [ $pk ];
    $_->{__pk} = _encode_pk($_, $pk) for (@$rows);

    return _grid($check, @_);
}

=item dropdowns_sql($dbh, $query)

Expects a query with two columns; the first being the values expected
in the column to which the dropdown is applied. The second being the
descriptions to be shown instead of the true values.

This function can be used in the "value" position of the key/value pairs
as meant in the C<dropdowns> keyword.

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


=back

=head1 DSL keywords for 'on_submit' event

=over

=cut

#################################
#
# DSL for 'on_submit' event
#
#################################

=item provided [ $name [, key => value, ... ]

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


=item save_grid $dbh, $failed_rows [, name => $name, table => $table, ... ]

Iterates over C<$failed_rows>, finding input for those rows as provided in
the UI and applying the fixed data to the database using C<$dbh>.

The following keys are supported:

=over

=item name

The name of the grid to be saved; used as argument to C<provided> to
query the replacement data.

=item table

The name of the table to save the data to. If not provided, defaults
to the value provided in the C<name> argument.

=back

=cut

sub save_grid {
    my ($dbh, $failed_rows, %args) = @_;

    my $name = $args{name};
    # assert that a name is provided
    # assert that a grid by that name has been defined

    # don't take any risk:
    # the sources providing the table name *are* dynamically loaded..
    my $table = $dbh->quote_identifier($args{table} // $name);
    my $pk = $check->{tables}->{$args{table} // $name}->{prim_key};
    $pk = (ref $pk) ? $pk : [ $pk ];

    my @fields = @{$check->{grids}->{$name}->{edit_columns}};
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

=back

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

=item describe

=item grid

=back

Next to the output formatters, these input-requesting routines are to
be supplied:

=over

=item provided $check [, $name ]

Called to retrieve input provided to the UI.

When called without parameters, returns a boolean value indicating whether
any inputs are available for processing at all. In other words, during the
C<on_failure> phase, this callback is supposed to return a falsy value,
while in the C<on_submit> phase, a true-ish value must be returned.

When called with a C<$name> argument, the value(s) of a specific element
rendered in the C<on_failure> phase must be returned. These are the expected
return value types per named rendered output:

=over

=item grid

C<grid> inputs are returned using an arrayref of hashrefs holding all the
fields originally supplied to the grid.

Note: This requirement is in place to make sure the grid returns the primary
key without making explicit protocol requirements for the naming of the
primary key field.

=item confirm

Returns the value associated with the selected/pressed/clicked description.

=back

=back

=head1 COPYRIGHT


=cut

1;
