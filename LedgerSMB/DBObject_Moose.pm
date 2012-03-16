

=head1 NAME

LedgerSMB::DBObject - LedgerSMB class for building objects from db relations

=head1 SYOPSIS

This module creates object instances based on LedgerSMB's in-database ORM.  

=head1 METHODS

=over

=item new ($class, base => $LedgerSMB::hash)

This is the base constructor for all child classes.  It must be used with base
argument because this is necessary for database connectivity and the like.

Of course the base object can be any object that inherits LedgerSMB, so you can
use any subclass of that.  The per-session dbh is passed between the objects 
this way as is any information that is needed.

=item exec_method 

($self, procname => $function_name, [args => \@args, schema => $schema,
continue_on_error=>$continue_on_error])

Provides the basic mapping of parameters to the SQL stored procedure function 
arguments.

If \@args is not defined, args are mapped from the object's properties, 
stripping them of their in_ prefix.  If schema is provided, that is used 
instead of PostgreSQL's search path.  If continue_on_error is provided and true,
the operation will not raise an exception in the event of a database error, and 
it will be up to the application to handle any exceptions.

=item __validate__ is called on every new() invocation.  It is blank in this 
module but can be overridden in decendant modules.

=item _db_array_scalars(@elements) creates a db array from scalars.

=item _db_array_literal(@elements) creates a multiple dimension db array from 
	preparsed db arrays or other data which does not need to be escaped.

=cut

package LedgerSMB::DBObject_Moose;
use Moose;
use Scalar::Util;
use Log::Log4perl;

has 'dbh' => (is => 'ro', isa => 'DBI::db', required => '1');
has '_roles' => (is => 'ro', isa => 'ArrayRef[Str]', required => '1');
has '_user' => (is => 'ro', isa => 'LedgerSMB::User', required => '1');
has '_locale' => (is => 'ro', isa => 'LedgerSMB::Locale', required => '1');
has '_request' => (is => 'ro', isa => 'CGI::Simple', required => '1');

sub prepare_dbhash {
    my $self = shift;
    my $target = shift;
    for my $att (qw(dbh _roles _user _locale _request)){
        if (!$target->{$att}){
           $target->{$att} = $self->{$att};
        }
    }
}


my $logger = Log::Log4perl->get_logger('LedgerSMB::DBObject');

sub __validate__ {}

=item set_ordering

Sets the ordering used by default for specific functions called by exec_method

=cut

sub set_ordering {
    my ($self, $args) = @_;
    $self->{_order_method}->{$args->{method}} = 
		$self->{dbh}->quote_identifier($args->{column});
}

sub exec_method {
    my $self   = shift @_;
    my %args  = (ref($_[0]) eq 'HASH')? %{$_[0]}: @_;
    my $funcname = $args{funcname};
    
    my $schema   = $args{schema} || $LedgerSMB::Sysconfig::db_namespace;
    
    $logger->debug("exec_method: \$funcname = $funcname");
    my @in_args;
    @in_args = @{ $args{args} } if $args{args};
    
    my @call_args;
     
    my $query = "
	SELECT proname, pronargs, proargnames FROM pg_proc 
	 WHERE proname = ? 
	       AND pronamespace = 
	       coalesce((SELECT oid FROM pg_namespace WHERE nspname = ?), 
	                pronamespace)
    ";
    my $sth   = $self->{dbh}->prepare(
		$query
    );
    $sth->execute($funcname, $schema) 
	|| $self->error($DBI::errstr . "in exec_method");
    my $ref;

    $ref = $sth->fetchrow_hashref('NAME_lc');
    
    my $pargs = $ref->{proargnames};
    my @proc_args;

    if ( !$ref->{proname} ) {    # no such function
        # If the function doesn't exist, $funcname gets zeroed?
        $self->error( "No such function:  $funcname");
#        die;
    }
    $ref->{pronargs} = 0 unless defined $ref->{pronargs};
    # If the user provided args..
    if (!defined $args{args}) {
        @proc_args = $self->_parse_array($pargs);
        if (@proc_args) {
            for my $arg (@proc_args) {
                #print STDERR "User Provided Args: $arg\n";
                if ( $arg =~ s/^in_// ) {
                     if ( defined $self->{$arg} )
                     {
                        $logger->debug("exec_method pushing $arg = $self->{$arg}");
                     }
                     else
                     {
                        $logger->debug("exec_method pushing \$arg defined $arg | \$self->{\$arg} is undefined");
                        #$self->{$arg} = undef; # Why was this being unset? --CT
                     }
                     push ( @call_args, $self->{$arg} );
                }
            }
        }
        for (@in_args) { push @call_args, $_ } ;
        $self->{call_args} = \@call_args;
        $logger->debug("exec_method: \$self = " . Data::Dumper::Dumper($self));
        for my $arg(@call_args){
            if (defined $arg && eval {$arg->can('to_db')}){
               $arg = $arg->to_db;
            }
        }
           
        return $self->call_procedure( procname => $funcname, 
                                          args => \@call_args, 
                                      order_by => $self->{_order_method}->{"$funcname"}, 
                                         schema=>$schema,
                             continue_on_error => $args{continue_on_error});
    }
    else {
        for my $arg(@in_args){
            if (eval {$arg->can('to_db')}){
               $arg = $arg->to_db;
            }
        }
           
        return $self->call_procedure( procname => $funcname, 
                                          args => \@in_args, 
                                      order_by => $self->{_order_method}->{"$funcname"}, 
                                         schema=>$schema,
                             continue_on_error => $args{continue_on_error});
    }
}


=item run_custom_queries

Backward-compatible with 1.2 custom query system for moving forward.

=cut

sub run_custom_queries {
    my ( $self, $tablename, $query_type, $linenum ) = @_;
    my $dbh = $self->{dbh};
    if ( $query_type !~ /^(select|insert|update)$/i ) {

        # Commenting out this next bit until we figure out how the locale object
        # will operate.  Chris
        #$self->error($locale->text(
        #	"Passed incorrect query type to run_custom_queries."
        #));
    }
    my @rc;
    my %temphash;
    my @templist;
    my $did_insert;
    my @elements;
    my $query;
    my $ins_values;

    if ($linenum) {
        $linenum = "_$linenum";
    }

    $query_type = uc($query_type);
    for ( @{ $self->{custom_db_fields}{$tablename} } ) {
        @elements = split( /:/, $_ );
        push @{ $temphash{ $elements[0] } }, $elements[1];
    }
    for ( keys %temphash ) {
        my @data;
        $query = "$query_type ";
        if ( $query_type eq 'UPDATE' ) {
            $query = "DELETE FROM $_ WHERE row_id = ?";
            my $sth = $dbh->prepare($query);
            $sth->execute( $self->{ "id" . "$linenum" } )
              || $self->dberror($query);
        }
        elsif ( $query_type eq 'INSERT' ) {
            $query .= " INTO $_ (";
        }
        my $first = 1;
        for ( @{ $temphash{$_} } ) {
            $query .= "$_";
            if ( $query_type eq 'UPDATE' ) {
                $query .= '= ?';
            }
            $ins_values .= "?, ";
            $query      .= ", ";
            $first = 0;
            if ( $query_type eq 'UPDATE' or $query_type eq 'INSERT' ) {
                push @data, $self->{"$_$linenum"};
            }
        }
        if ( $query_type ne 'INSERT' ) {
            $query =~ s/, $//;
        }
        if ( $query_type eq 'SELECT' ) {
            $query .= " FROM $_";
        }
        if ( $query_type eq 'SELECT' or $query_type eq 'UPDATE' ) {
            $query .= " WHERE row_id = ?";
        }
        if ( $query_type eq 'INSERT' ) {
            $query .= " row_id) VALUES ($ins_values ?)";
        }
        if ( $query_type eq 'SELECT' ) {
            push @rc, [$query];
        }
        else {
            unshift( @data, $query );
            push @rc, [@data];
        }
    }
    if ( $query_type eq 'INSERT' ) {
        for (@rc) {
            $query = shift( @{$_} );
            my $sth = $dbh->prepare($query)
              || $self->db_error($query);
            $sth->execute( @{$_}, $self->{id} )
              || $self->dberror($query);
            $sth->finish;
            $did_insert = 1;
        }
    }
    elsif ( $query_type eq 'UPDATE' ) {
        @rc = $self->run_custom_queries( $tablename, 'INSERT', $linenum );
    }
    elsif ( $query_type eq 'SELECT' ) {
        for (@rc) {
            $query = shift @{$_};
            my $sth = $self->{dbh}->prepare($query);
            $sth->execute( $self->{id} );
            my $ref = $sth->fetchrow_hashref('NAME_lc');
            $self->merge( $ref, keys(%$ref) );
        }
    }
    return @rc;
}

sub _parse_array {
    my ($self, $value) = @_;
    return @$value if ref $value eq 'ARRAY';
    return if !defined $value;
    # No longer needed since we require DBD::Pg 2.x 
}

sub _db_array_scalars {
    my $self = shift @_;
    my @args = @_;
    return \@args; 
    # No longer needed since we require DBD::Pg 2.x
}

sub _db_array_literal {
    my $self = shift @_;
    my @args = @_;
    return \@args;
    # No longer needed since we require DBD::Pg 2.x
}

sub call_procedure {
    my $self     = shift @_;
    my %args     = @_;
    my $procname = $args{procname};
    my $schema   = $args{schema};
    my @call_args;
    @call_args = @{ $args{args} } if defined $args{args};
    my $order_by = $args{order_by};
    my $query_rc;
    my $argstr   = "";
    my @results;

    if (!defined $procname){
        $self->error('Undefined function in call_procedure.');
    }
    $procname = $self->{dbh}->quote_identifier($procname);
    # Add the test for whether the schema is something useful.
    $logger->trace("\$procname=$procname");
    
    $schema = $schema || $LedgerSMB::Sysconfig::db_namespace;
    
    $schema = $self->{dbh}->quote_identifier($schema);
    
    for ( 1 .. scalar @call_args ) {
        $argstr .= "?, ";
    }
    $argstr =~ s/\, $//;
    my $query = "SELECT * FROM $schema.$procname()";
    if ($order_by){
        $query .= " ORDER BY $order_by";
    }
    $query =~ s/\(\)/($argstr)/;
    my $sth = $self->{dbh}->prepare($query);
    my $place = 1;
    # API Change here to support byteas:  
    # If the argument is a hashref, allow it to define it's SQL type
    # for example PG_BYTEA, and use that to bind.  The API supports the old
    # syntax (array of scalars and arrayrefs) but extends this so that hashrefs
    # now have special meaning. I expect this to be somewhat recursive in the
    # future if hashrefs to complex types are added, but we will have to put 
    # that off for another day. --CT
    foreach my $carg (@call_args){
        if (ref($carg) eq 'HASH'){
            $sth->bind_param($place, $carg->{value}, 
                       { pg_type => $carg->{type} });
        } else {
            $sth->bind_param($place, $carg);
        }
        ++$place;
    }
    $query_rc = $sth->execute();
    if (!$query_rc){
          if ($args{continue_on_error} and  #  only for plpgsql exceptions
                          ($self->{dbh}->state =~ /^P/)){
                $@ = $self->{dbh}->errstr;
          } else {
                $self->dberror($self->{dbh}->errstr . ": " . $query);
          }
    }
   
    my @types = @{$sth->{TYPE}};
    my @names = @{$sth->{NAME_lc}};
    while ( my $ref = $sth->fetchrow_hashref('NAME_lc') ) {
	for (0 .. $#names){
            #   numeric            float4/real
            if ($types[$_] == 3 or $types[$_] == 2) {
                $ref->{$names[$_]} = Math::BigFloat->new($ref->{$names[$_]});
            }
            #    DATE 
            elsif ($types[$_] == 91){
                $ref->{$names[$_]} = LedgerSMB::PGDate->from_db($ref->{$names[$_]}, 'date');
            }
            # TIMESTAMP
            elsif ($types[$_] == 11){
                $ref->{$names[$_]} = LedgerSMB::PGDate->from_db($ref->{$names[$_]}, 'datetime');
            }
        }
        push @results, $ref;
    }
    return @results;
}

# Keeping this here due to common requirements
sub is_allowed_role {
    my ($self, $args) = @_;
    my @roles = @{$args->{allowed_roles}};
    for my $role (@roles){
        $self->{_role_prefix} = "lsmb_$self->{company}__" unless defined $self->{_role_prefix};
        my @roleset = grep m/^$self->{_role_prefix}$role$/, @{$self->{_roles}};
        if (scalar @roleset){
            return 1;
        }
    }
    return 0; 
}

# To be replaced with a generic interface to an Error class
sub error {

    my ( $self, $msg ) = @_;

    if ( $ENV{GATEWAY_INTERFACE} ) {

        $self->{msg}    = $msg;
        $self->{format} = "html";

        delete $self->{pre};

        
        print qq|Content-Type: text/html; charset=utf-8\n\n|;
        print "<head></head>";
        $self->{msg} =~ s/\n/<br \/>\n/;
        print
          qq|<body><h2 class="error">Error!</h2> <p><b>$self->{msg}</b></body>|;

        exit;

    }
    else {

        if ( $ENV{error_function} ) {
            &{ $ENV{error_function} }($msg);
        }
        die "Error: $msg\n";
    }
}
# Database routines used throughout
sub dberror{
   my $self = shift @_;
   my $state_error = {};
   if ($self->{_locale}){
       my $state_error = {
            '42883' => $self->{_locale}->text('Internal Database Error'),
            '42501' => $self->{_locale}->text('Access Denied'),
            '42401' => $self->{_locale}->text('Access Denied'),
            '22008' => $self->{_locale}->text('Invalid date/time entered'),
            '22012' => $self->{_locale}->text('Division by 0 error'),
            '22004' => $self->{_locale}->text('Required input not provided'),
            '23502' => $self->{_locale}->text('Required input not provided'),
            '23505' => $self->{_locale}->text('Conflict with Existing Data'),
            'P0001' => $self->{_locale}->text('Error from Function:') . "\n" .
                    $self->{dbh}->errstr,
       };
   }
   $logger->error("Logging SQL State ".$self->{dbh}->state.", error ".
           $self->{dbh}->err . ", string " .$self->{dbh}->errstr);
   if (defined $state_error->{$self->{dbh}->state}){
       $self->error($state_error->{$self->{dbh}->state}
           . "\n" . 
          $self->{_locale}->text('More information has been reported in the error logs'));
       $self->{dbh}->rollback;
       exit;
   }
   $self->error($self->{dbh}->state . ":" . $self->{dbh}->errstr);
}

__PACKAGE__->meta->make_immutable;

1;

=back

=head1 Copyright (C) 2007, The LedgerSMB core team.

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut
