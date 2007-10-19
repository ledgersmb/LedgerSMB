

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

=item exec_method ($self, procname => $function_name, args => \@args)

Provides the basic mapping of parameters to the SQL stored procedure function 
arguments.

=back

=head1 Copyright (C) 2007, The LedgerSMB core team.

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

package LedgerSMB::DBObject;
use Scalar::Util;
use base qw(LedgerSMB);
use strict;
use warnings;

our $AUTOLOAD;

sub AUTOLOAD {
    my ($self) = shift;
    my $type = Scalar::Util::blessed $self;
    $type =~ m/::(.*?)$/;
    $type = lc $1;
    $self->exec_method( funcname => "$type" . "_" . $AUTOLOAD, args => \@_);
}

sub DESTROY {} 

sub new {
    my $class = shift @_;
    my %args  = (ref($_[0]) eq 'HASH')? %{$_[0]}: @_;
    my $base  = $args{base};
    my $mode  = $args{copy};
    my $self  = bless {}, $class;
    my @mergelist;
    if ( defined $args{merge} ){
        @mergelist = @{ $args{merge} };
    } elsif (defined $mode && ( $mode eq 'list')) {
        $self->error('Mergelist not set');
    }
    else {
        @mergelist = [];
    }
    if ( !$base->isa('LedgerSMB') ) {
        $self->error("Constructor called without LedgerSMB object arg");
    }

    my $attr;
    if (lc($mode) eq 'base'){
        $self->merge($base, 'dbh', '_roles');
    }
    elsif (lc($mode) eq 'list'){
        $self->merge($base, @mergelist);
    }
    else {
        $self->merge($base);
    }
    $self;
}

sub set_ordering {
    my $self = shift  @_;
    my %args = @_;

    if (not defined $self->{_order_method}){
        $self->{_order_method} = {};
    }   

    $self->{_order_method}->{$args{method}} = $args{column};
}

sub exec_method {
    my $self   = shift @_;
    my %args     = @_;
    my $funcname = $args{funcname};
    my @in_args;
    @in_args = @{ $args{args}} if $args{args};
    my @call_args;
     
    my $query = "SELECT proname, pronargs, proargnames FROM pg_proc WHERE proname = ?";
    my $sth   = $self->{dbh}->prepare($query);
    $sth->execute($funcname) || $self->error($DBI::errstr . "in exec_method");
    my $ref;

    $ref = $sth->fetchrow_hashref('NAME_lc');
    
    my $args = $ref->{proargnames};
    my @proc_args;
    $ref->{pronargs} = 0 unless defined $ref->{pronargs};
    if ($ref->{pronargs}){
        $args =~ s/\{(.*)\}/$1/;
        @proc_args = split /,/, $args if $args;
    }
    
    if ( !$ref->{proname} ) {    # no such function
     
        $self->error( "No such function:  $funcname");
#        die;
    }
    
    my $m_name = $ref->{proname};

    if ($args) {
        for my $arg (@proc_args) {
            if ( $arg =~ s/^in_// ) {
                 push @call_args, $self->{$arg};
            }
        }
    }

    for (@in_args) { push @call_args, $_ } ;
    $self->{call_args} = \@call_args;
    $self->debug({file => '/tmp/dbobject'});
    return $self->call_procedure( procname => $funcname, args => \@call_args );
}

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
    my $next;
    my $separator;
    my @return_array;

    while ($value ne '{}') {
        my $next = "";
        my $separator = "";
        if ($value =~ /^\{"/){
            while ($next eq "" or ($next =~ /\\".$/)){
                $value =~ s/^\{("[^"]*".)/\{/;
                $next .= $1;
                $next =~ /(.)$/;
                $separator = $1;
            }
            $next =~ s/"(.*)"$separator$/$1/;

        } elsif ($value =~ /^{({+})/){
            my $open_braces = $1;
            my $close_braces = $open_braces;
            $close_braces =~ s/{/}/g;
            $value =~ /^{($open_braces.*$close_braces)/;
            $next = $1;
            $value =~ s/^{$next/{/;
            $next = $self->parse_array($next);
            
        } else {
            $value =~ s/^\{([^,]*)(,|\})/\{/;
            $next = $1;
            $separator = $2;
        }
        $value .= '}' if $separator eq '}';
        $next =~ s/\\\\/\\/g;
        $next =~ s/\\"/"/g;
        push @return_array, $next;
    }
    return @return_array;
}

1;
