=head1 NAME 
LedgerSMB::SODA

=cut

# TODO Type parsing still needs to be implemented.
# Also should add signal handlers to clear cache. --CT


package LedgerSMB::SODA;
use Moose;

use LedgerSMB::Auth;
use LedgerSMB::Sysconfig;
use LedgerSMB::Locale;

our $VERSION = "1.0";

=head1 SYNOPSIS

This provides better database integration than LedgerSMB::DBObject, which has
been left in place for backwards compatibility.  LedgerSMB::SODA provides
services for loosely tying the application to the database through interface
discovery and other services.

In LedgerSMB 1.4 new code, all database access should go through here.

=head1 PROPERTIES

=over

=cut

# also add inline constraint to ensure autocommit is off
has 'dbh' => (isa => 'DBI', is => 'rw', required => 1);

=item dbh
This is the database handle through which all access to the database goes.

=cut

has 'dbroles' => (isa => 'ArrayRef[Str]', is=> 'rw', required => 0);

=item dbroles
List of database roles for the current logged in user.  This can be specified
in the constructor or discovered later with LedgerSMB::SODA->get_roles

=cut

has 'db' => (isa => 'Str', is=> 'ro', required => 1);

=item db
Name of the current database

=cut

has 'username' => (isa => 'Str', is=>'ro', required => 1);

=item username
Name of the current logged in user.

=cut

=back

=head1 CONSTRUCTOR SYNTAX

=over

=item Full syntax

LedgerSMB::SODA->new({ db => $string, username => $string, cred => $string });

Here username is the database user to connect as and cred is the credential
string to be used for the connection.  This syntax would be preferred for thick
clients interacting with a LedgerSMB database because it allows one to grab
user-specified credentials and pass them through to this syntax.

=item Minimal syntax
LedgerSMB::New({ db => $string })

Here, with no args other than db, we grab the appropriate credentials via 
LedgerSMB::Auth

Out of the box, LedgerSMB only supports HTTP basic credentials. Kerberos could
be supported with minimal effort.

=back

=cut

around BUILDARGS => sub {
    my $self = shift @_;
    my $orig = shift @_;
    my %args  = (ref($_[0]) eq 'HASH')? %{$_[0]}: @_;
    if ($args{username}){
       # TODO  Add DBI Connection
       my $dbh = DBI->connect("dbi:Pg:dbname=$args{db}", $args{username}, 
                            $args{cred}, 
                            { AutoCommit => 0 }
       );
       return $orig({ db => $args{db}, 
                     dbh => $dbh, 
                username => $args{username} });
    } else {
       my ($username, $cred) = LedgerSMB::Auth->get_credentials();
       return &BUILDARGS({ db => $args{db}, 
                    username => $username, 
                        cred => $cred });
    }
};

sub BUILD {
    my $self = shift @_;
    $self->_get_roles();
    $self->dbh->pg_learn_custom_types;
    return $self;
};

=head1 METHODS

=over

=cut

# Private method _get_roles().  Used in constructor only.  Sets dbroles
# to the set of database roles the user has permission to.

sub _get_roles {
    my $self = @_;
    my $dbh = $self->dbh;
    my $sth = $dbh->prepare("
            SELECT rolname FROM pg_roles i
             WHERE pg_has_role(?, rolname, 'USAGE')
          ORDER BY rolname"
    );
    $sth->execute($self->username);
    my $roles_arrayref = [];
    while (my $ref = $sth->fetchrow_hashref('NAME_lc')){
       push @{$roles_arrayref}, $ref->{rolname};
    }
    $self->dbroles($roles_arrayref);
}

=item is_allowed_role(string $rolename)
Returns true if the role (minus the role prefix, which defaults to
"lsmb_${db}__" where $db is the return value of $self->db) is granted to the 
user, false otherwise.

=cut

sub is_allowed_role {
    my $self = shift @_;
    my ($rolename) = (@_);
    my $dbh = $self->dbh;
    
    my $prefix = $LedgerSMB::Sysconfig::role_prefix;
    $prefix ||= 'lsmb_' . $self->db . "__";
    my $roles = $self->dbroles;
    for my $role (@$roles){
        if ($role eq "$prefix$rolename"){
            return 1;
        }
    }
    return 0;
}

=item register_type({sql_type => $string, perl_class => $string, parse_func
=>bool})

This function registers a Perl class in association with a SQL type.

When a method is dispatched the return values are sorted through to determine
what types they are.  Registered types are then used to handle input and output
to application types.

Registered types corresponding to simple PostgreSQL types are expected to have a
constructor syntax supporting a simple {string => $string} argument list with no
further arguments.  Additionally they are expected to have either a
to_db_string() method which represents the object as a string suitable for
insertion into the database, or (as a fallback) a to_string method which
represents the the object as a simple string for general purposes.

Registered types corresponding to complex PostgreSQL types will use the standard
Moose-type constructor, passing in the hashref of the returned data (after
members have been checked for registered types).  They are also expected to
either be a hashref or have a to_hashref method that can be used to convert to a
hashref for db entry purposes.  Note that Moose classes are compliant with this
by default, but that a to_hashref method could be useful in setting some custom
properties.

If parse_func is true, then parse_input will parse the input by using a select
statement to cast the input as its sql type.  This is mostly helpful where the
parsing capabilities of the database engine are very well developed and the
number of inputs to be parsed is very low.  At present only dates are expected
to be parsed this way.

=cut

my $sql_type_cache = {};

my $registered_types = {};

sub register_type {
    my ($self) = shift @_;
    my %args  = (ref($_[0]) eq 'HASH')? %{$_[0]}: @_;
    my $eval_string = "require $args{perl_class}";
    
    $registered_types->{$args{sql_type}} = { class => $args{perl_class},
                                       parse_input => $args{parse_input}, };
}


=item parse_input(class => $string, value => $string)
This is a hook for parsing data via the database for registered types.

If the parse_input flag is set of for the registered type, we cast via the
database.  If not, we just return the value.

=cut

sub parse_input {
    my ($self) = shift @_;
    my %args  = (ref($_[0]) eq 'HASH')? %{$_[0]}: @_;
    return $args{value} unless $args{class};
    for my $k (keys %$registered_types){
        if ($registered_types->{k}->{class} eq $args{class}){
            if ($registered_types->{k}->{parse_input}){
                my $dbh = $self->dbh;
                my $cast = $dbh->quote_identifier($args{class});
                my $query = "SELECT ?::$cast";
                my $sth = $dbh->prepare($query) || $self->dberror($query);
                $sth->execute($args{value}) || $self->dberror($query);
                my ($value) = $sth->fetchrow_array;
                return $value;
            } else {
                last;
            }
        }
    }
    return $args{value};
}

=item soda_method

Minimal invocation:

 $soda->soda_method({ caller => $object, #supplies properties
                      method => $string, #name of stored procedure
 });

Maximal invocation:

 $soda->soda_method({ caller => $object,   # required
                      method => $string,   # required
                        args => $hashref,  # may be required on some stored 
                                           # procedures
                       order => $arrayref, # optional, procedures usually have
                                           # defaults
                     windows => $arrayref, # optional see below
                        aggs => $arrayref, # optional, see below
 });

The syntax of this method is a bit complicated because the needed feature set
has become quite a bit larger than that which was needed and available when
LedgerSMB::DBObject->exec_method was written.

Supported arguments are:
=over
=item caller
Caller object, whose properties are used where an argument is named prop_*.  It
is required.

=item schema
Optional.  Gives the schema name to find the function in.

=item method
Name of stored procedure called.  It is required.

=item args
Hashref for non-property argument names.  An argument which is prefixed with in_
or arg_ draws its argument from this hashref.  The in_ prefix is supported to
allow stored procedures to be shared with LedgerSMB::DBObjects (from the 1.3
codebase and addons).

=item order
List of hashrefs for order by clause.  Each hashref contains:

=over

=item column (required)

=item order (optional enum(asc, desc))

=item null_order (optional enum(first, last))

=back

Expressions for ordering are not supported due to SQL injection concerns, but
column numbers are.

=cut

# Private method _order_by generates order by clause based on the above spec.
# All identifiers are escaped and all keywords whitelisted.
sub _order_by {
    my ($self, $order_specs) = @_;
    my $clause = "ORDER BY ";
    my $first = 1;
    for my $spec ($order_specs){
        $clause .= $self->dbh->quote_identifier($spec->{column}) . " ";
        if ($spec->{order} =~ /^(ASC|DESC)$/i){
            $clause .= " $1 ";
        } else {
            warn "Invalid ordering 'order' attribute $spec->{order}" 
                 if $spec->{order};
        }
        if ($spec->{null_order} =~ /^(FIRST|LAST)$/i ){
            $clause .= " NULLS $1";
        } else {
            warn "Invalid ordering 'null_order' attribute $spec->{null_order}"
                 if $spec->{null_order};
        }
        $first = 0;
    }
}

=item windows
List of window specifications.  Each window is a hashref in the form of:

{name =>$string, partion => $string, order => $arrayref}

order follows same semantics as the argument to the main

To these are added the following pre-defined windows:

=over 

=item rows_unbounded_pre

ROWS UNBOUNDED PRECEDING

=item rows_bw_unbounded_pre_and_current
ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW

=item rows_bw_unbounded_pre_and_following
ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING

=cut

my @predef_windows = (
         { name => "rows_unbounded_pre",
           spec => "ROWS UNBOUNDED PRECEDING" },

         { name => "rows_bw_unbounded_pre_and_current",
           spec => "ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW" },

         { name => "rows_bw_unbounded_pre_and_following",
           spec => "ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING"},
);



# Private method implements window clauses per above specs above
# All identifiers are escaped, and all key words whitelisted.

sub _windows {
    my ($self, $windows);
    my @window_list = @predef_windows;
    my $clauses = "";
    my $dbh = $self->dbh;

    for my $win (@{$windows}){
        my $spec = "";

        if ($win->{partition}){
           $spec .= " PARTION BY " . $dbh->quote_identifier($win->{partition});
        }

        if (scalar @{$win->{order}}) {
           $spec .= $self->_order_by($win->{order});
        }

        push @window_list, 
          {name => $win->{name},
           spec => $spec } if $spec;
    }

    for my $win (@window_list){
        $clauses .= " $win->{name} AS ($win->{spec}) 
            ";
    }
    return $clauses;
}

=back

=item aggs 
An array of hashrefs, each of which contains four elements:

=over

=item agg $string 

Name of aggregate

=item alias $string

Column name to assign aggregate

=item window $string

Name of window

=item cols $arrayref

array ref of column names for the aggregate.

=back

Examples:

A basic list of journal entries might be done with:

$soda->soda_method({ caller => $gl_report, method => 'gl_report__run' });

However if we want to run this with a running total, we can:

        $soda->soda_method({ caller => $gl_report
                             method => 'gl_report__run',
                               aggs => [{ agg => 'sum',
                                        alias => 'running_total',
                                         cols => ['amount'],
                                       window => 'rows_unbounded_pre',
                                       }],
                          });
                             
=cut

sub soda_method {
    my ($self) = shift @_;
    my $dbh = $self->dbh;
    my %args  = (ref($_[0]) eq 'HASH')? %{$_[0]}: @_;
    my $caller = $args{caller};
    my $method = $args{method};

    my $schema   = $args{schema} || $LedgerSMB::Sysconfig::db_namespace;
    my @windows  = @predef_windows;
    #Window specs
    my $col_list = "*";

    for my $agg ($args{aggs}){
        $col_list .= ", " . $dbh->quote_identifier($agg->{agg});
        $col_list .= '(' . $self->_ids_to_string($agg->{cols}) . ')';
        $col_list .= " AS " . $dbh->quote_identifier($agg->{alias});
    } 

    my @sproc_arg_list = $self->_get_arg_list({schema => $schema, 
                                               method => $args{method} });
    my @arg_list = ();
    my $arg_clause = '';

    for my $arg (@sproc_arg_list){
        if ($arg =~ s/^(in_|arg_)//){
            push @arg_list, $args{args}->{$arg};
        } elsif ($arg =~ s/^prop_//){
            push @arg_list, $args{$caller}->{arg};
        } else {
            warn "Bad argument name $arg in soda_method, method $method";
            push @arg_list, $args{args}->{$arg};
        }
        if ($arg_clause eq ''){
            $arg_clause = '?';
        } else {
            $arg_clause .= ', ?';
        }
    }
    my $query = "
          SELECT $col_list 
            FROM $args{method}($arg_clause)
          " . $self->_windows($args{windows}) . "
          " . $self->_order_by($args{order});
    my $sth = $dbh->prepare($query) || $self->dberror(@_);

    my @return_set = ();
    push @return_set, 
         $self->_parse_return( $sth->fetchrow_hashref('NAME_lc') );
    return @return_set;
}

# Private method _ids_to_string($arrayref)
# returns a ", " separated list of quoted identifiers from the array ref.

sub _quote_identifiers{
    my ($self, $ids);
    my $quoted_string = "";
    my $dbh = $self->dbh;

    for my $id (@$ids){
        if ($quoted_string eq '') {
            $quoted_string = $dbh->quote_identifier($id);
        } else {
            $quoted_string .= ", " . $dbh->quote_identifier($id);
        }
    }
    return $quoted_string;
}

# Private method _get_arg_list({schema => $string, method => string })
# This is basically copied from DBObject::exec_method  All it does is query the
# database for the function name and builds the argument list and adjusted so
# that it returns a list of argument names.
#
# We don't need to worry about arguement types because discoverability is based
# on name at present, so functions are guaranteed to be unique by name.

sub _get_arg_list {
    my ($self, $args) = @_;
    my $funcname = $args->{method};
    my $schema   = $args->{schema};
    my $dbh = $self->dbh;
    my $query = "
        SELECT proname, pronargs, proargnames FROM pg_proc 
         WHERE proname = ? 
               AND pronamespace = 
               coalesce((SELECT oid FROM pg_namespace WHERE nspname = ?), 
                        pronamespace)
    ";
        my $sth   = $self->{dbh}->prepare($query);
    $sth->execute($funcname, $schema)
        || $self->_dberror($DBI::errstr . "in exec_method");
    my $ref;

    $ref = $sth->fetchrow_hashref('NAME_lc');
    if (!$ref) {
        $self->_dberror($query);
    }
    return @{$ref->{proargnames}};
}

=item query_custom_fields

=item commit
Commits to the database unless LSMB_TEST is set, in which case it tests whether
the database transaction is commitable, returns true if it is.  Otheriwse it 
returns false and rolls back.

=cut

sub commit {
    my ($self) = $_;
    if ($ENV{LSMB_TEST}){ # TEST mode.  Never commit to the db in test mode.
                          # In order to simulate commits, however, transactions
                          # have to be kept open long beyond their normal
                          # lifespan.  This can cause locking and even deadlock
                          # problems.  It's best to run API tests when other
                          # users are not using the database, or roll back
                          # between API tests. --CT
       my $dbh = $self->dbh;
       my ($success) = $dbh->fetchall_array('SELECT 1');
       if ($success){
            return $success;
       } else {
            $dbh->rollback;
            return $success;
      }
    } else {
       $self->dbh->commit;
    }
}

=back

=head1 ERRORS

The module runs errors through a private method _dberror which sets appropriate
messages, logs messages, and then throws an exception.  Error messages handled
here are:

=over

=item Internal Database Error
SQL State 42883.  Undefined function.  This is always a bug or an issue with the
database being out of sync with the application.

=item Access Denied
Insufficient permissions to perform the operation.  Corresponds to SQL States
42501 and 42401.

=item Invalid date/time entered
SQL State 22008.  The date or time entered was not in a valid format.

=item Division by 0 error

=item Required input not provide
This occurs when a NOT NULL constraint is violated.  SQL states 22004 and 23502

=item Conflict with Existing Data
SQL State 23505, indivates that a unique constraint has been violated.

=item Error from Function: $errstr
P0001:  There was an unhandled exception in a function.

=cut
# Private method, should throw exception but process the out put and log errors
# before so doing.  Replaces LedgerSMB->dberror.

sub _dberror {
    my ($self) = shift @_;
    my $locale = $LedgerSMB::App_State::Locale;
    my $sqlstate = $self->dbh->sqlstate;
    #TODO Move these to registered error messages --CT
       my $state_error = {
            '42883' => $locale->text('Internal Database Error'),
            '42501' => $locale->text('Access Denied'),
# Does 42401 actually exist? --CT
            '42401' => $locale->text('Access Denied'),
            '22008' => $locale->text('Invalid date/time entered'),
            '22012' => $locale->text('Division by 0 error'),
            '22004' => $locale->text('Required input not provided'),
            '23502' => $locale->text('Required input not provided'),
            '23505' => $locale->text('Conflict with Existing Data'),
            'P0001' => $locale->text('Error from Function') . ":\n" .
                    $self->dbh->errstr,
       };
    #TODO add logging before raising exception --CT
    die "LedgerSMB::SODA $sqlstate";
};

=item stringify(string $typename, @hashrefs)

Stringify returns an arrayref of strings representing the hashes in the SQL
complex type identified.

=cut

sub stringify {
    my ($self) = shift @_;
    my $typename = shift @_;
    my @hashes = @_;
    my $dbh = $self->dbh;
    my $arglist_str = '';
    my @arglist;

    if ($sql_type_cache->{$typename}){
       my @arglist = $sql_type_cache->{$typename};
       if (!@arglist){
           delete $sql_type_cache->{$typename};
           return $self->stringify($typename, @hashes);
       }
    } else {
        my $attquery = "
            SELECT attname, attnum 
              FROM pg_attribute 
             WHERE attrelid = (SELECT oid FROM  pg_class WHERE relname = ?)
        ";
        my $attsth = $dbh->prepare($attquery);
        $attsth->execute($typename) || $self->dberror();
        while (my $attref = $attsth->fetchrow_hashref('NAME_lc')){
             push @arglist, $attref->{attname};
        }
    }

    my $retval = [];

    for my $hash (@hashes) {
        my $string  = '(';
        for my $arg (@arglist){
           $arg =~ s/"/""/; # double up double quotes -- CT
           if ($arg =~ /\\/){ # Backshash escaping not supported
               die 'LedgerSMB::SODA Backslash escaping not yet supported'
           } elsif ($arg =~ /[(),"]/){ # Double quote escaping
               $arg = '"' . $arg . '"';  
           } elsif ($arg eq '' and defined $arg){
               $arg = '""';
           }
           $string .= "$arg,";
        }
        $string =~ s/,$/\)/;
        push @$retval, $string;
    }

    return $retval;
}

=back

=head1 ENVIRONMENT VARIABLES

=over

=item LSMB_TEST

When this environment variable is set, LedgerSMB::SODA will not write to the
database.  Instead it will test to see if a transaction is committable, and if 
so, simply return true.  If not, it will rollback the current transaction and
return false.  This allows us to run all sorts of tests without permanently
writing data to the database.  Note that in some cases, however, tests may block
other uses of the application due to longer-than-normal transaction blocks.

To work around this issue, it is recommended that test cases roll back between
test cases unless they must continue.  If deadlocks result, tests may have to be
run during off-hours.

=back

=head1 SEE ALSO

=over

=back

=cut
1;

=head1 COPYRIGHT

This file is licensed under the Gnu General Public License (GPL) version 2, or 
at your option any later version.  A copy of the license should have been 
included with your software.

