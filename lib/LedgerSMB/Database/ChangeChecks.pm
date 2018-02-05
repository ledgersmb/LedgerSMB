
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

LedgerSMB::Database::PreChecks - Pre-migration checks for schema changes

=head1 DESCRIPTION

This module provides the DSL commands necessary to build the checks being
executed before schema change scripts are being run.

=head1 SYNOPSIS

  package SomePackage;

  use LedgerSMB::Database::PreChecks;

  check "The first check",
     query => qq|SELECT * FROM a_table|,
     description => qq|... extensive description for the user ... |,
     on_failure => sub {
         my ($dbh, $rows) = @_;

         grid $rows,
           name => 'grid',
           id => 'id',
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
           table => 'a_table',
           edit_columns => [ ... one or more columns ...];
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

    return @checks;
}



our $check;


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
    return 0 unless (@rows);

    ###TODO if we have input data, we need to run 'on_submit'; otherwise, we
    # need to run 'on_failure'
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

=item run_with_formatters($block, $formatters)

Runs C<$block> in a context with C<$formatters> set up.

The function returns the value(s) returned by C<$block>.

=cut


sub run_with_formatters(&$) { ## no critic
    my ($block, $formatters) = @_;

    no warnings 'redefine'; ## no critic
    local (*_describe, *_confirm, *_grid, *provided) =
        @{$formatters}{qw(describe confirm grid provided)};

    return $block->();
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

=item table

...

=item assert_sql

...

=item grids

...

=item on_failure

Required. A coderef pointing to a function of 2 arguments, taking the
database handle as the first argument and a coderef returning the successive
rows of the query as arrayrefs (or undef when there are no further results).

The on_failure coderef makes use of the user interface defining
elements of the pre-check DSL: grid, confirm, choice, dropdowns_sql.

=item on_submit

Required. A coderef pointing to a function of 2 arguments, taking the
database handle as the first argument and hashref the values of the
'id' column as the keys. The values are hashrefs with the column names
of the editable columns as the keys and the selected values as the hash
values.

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

    push @checks, \@args;
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
    return _describe(@_);
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
    return _confirm(@_);
}

=item grid $rows, [ key => $value ]

Used to render a grid with the rows as indicated in the C<$rows> hashref.

The following keys are available:

=over

=item name

Names the grid in order to be able to extract the (changed) values
from the returned data.

=item prim_key

When a string value, names the column containing the primary key of the
target table. In case of an arrayref, lists the complex primary key.

Needed here as it allows the UI to be able to request
the primary key from the returned data later.

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
    # assert that the values in the rows hashes include values for all fields of the
    # primary key!
    return _grid(@_);
}

=item dropdowns_sql($dbh, $query)

Expects a query with two columns; the first being the values expected
in the column to which the dropdown is applied. The second being the
descriptions to be shown instead of the true values.

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

=item provided [ $name ]

Used to access UI responses from elements named in the C<on_failure> phase.

=cut

sub provided {
    # placeholder; bound to a real function by run_with_formatters()
    die q{'provided' can't be called outside run_with_formatters scope};
}


=item save_grid $dbh, $failed_rows [, name => $name, ... ]

Iterates over C<$failed_rows>, finding input for those rows as provided in
the UI and applying the fixed data to the database using C<$dbh>.

UI data is requested using the C<provided> routine.

=cut

sub save_grid {
    my ($dbh, $failed_rows, %args) = @_;

    my $name = $args{name};
    # assert that a name is provided
    # assert that a grid by that name has been defined

    # don't take any risk:
    # the sources providing the table name *are* dynamically loaded..
    my $table = $dbh->quote_identifier($check->{table}->{name});
    my $pk = $check->{table}->{primary_key};
    $pk = (ref $pk) ? $pk : [ $pk ];

    my @fields = @{$check->{grids}->{$name}};
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

Formatters implement the UI of the checks. This way, the UI can be anything from
a web request/response based implementation to a terminal/ncurses solution.

Formatters implement callbacks that will be called from the checks while processing
any of the events. During the C<on_failure> event, this usually will mean output
generation, while the C<on_submit> event will want to query the UI for input provided.

The following output hooks have to be provided, all quite high level, leaving the
implementation with lots of room to render the output.

=over

=item confirm

=item describe

=item grid

=back

Next to the output formatters, these input-requesting routines are to be supplied:

=over

=item provided [ $name ]

Called to retrieve input provided to the UI. When called with a C<$name> argument,
the value(s) of a specific element rendered in the C<on_failure> phase must be
returned. These are the expected return value types per named rendered output:

=over

=item grid

C<grid> inputs are returned using an arrayref holding hashrefs holding all the
fields originally supplied to the grid.

Note: This requirement is in place to make sure the grid returns the primary key
without making explicit protocol requirements for the naming of the primary key field.

=item confirm

Returns the value associated with the selected/pressed/clicked description.

=back

When called without parameters, returns a boolean value indicating whether any
inputs are available for processing at all. In other words, during the C<on_failure>
phase, this callback is supposed to return a falsy value, while in the C<on_submit>
phase, a true-ish value must be returned.

=back

=head1 COPYRIGHT


=cut

1;
