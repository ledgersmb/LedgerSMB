
=head1 NAME

LedgerSMB  The Base class for many LedgerSMB objects, including DBObject.

=head1 SYNOPSIS

This module creates a basic request handler with utility functions available
in database objects (LedgerSMB::DBObject)

=head1 METHODS

=over

=item new ()

This method creates a new base request instance. It also validates the 
session/user credentials, as appropriate for the run mode.  Finally, it sets up 
the database connections for the user.

=item date_to_number (user => $LedgerSMB::User, date => $string);

This function takes the date in the format provided and returns a numeric 
string in YYMMDD format.  This may be moved to User in the future.

=item debug (file => $path);

This dumps the current object to the file if that is defined and otherwise to 
standard output.

=item escape (string => $string);

This function returns the current string escaped using %hexhex notation.

=item unescape (string => $string);

This function returns the $string encoded using %hexhex using ordinary notation.

=item format_amount (user => $LedgerSMB::User::hash, amount => $string, precision => $integer, neg_format => (-|DRCR));

The function takes a monetary amount and formats it according to the user 
preferences, the negative format (- or DR/CR).  Note that it may move to
LedgerSMB::User at some point in the future.

=item parse_amount (user => $LedgerSMB::User::hash, amount => $variable);

If $amount is a Bigfloat, it is returned as is.  If it is a string, it is 
parsed according to the user preferences stored in the LedgerSMB::User object.

=item is_blank (name => $string)

This function returns true if $self->{$string} only consists of whitespace
characters or is an empty string.

=item is_run_mode ('(cli|cgi|mod_perl)')

This function returns 1 if the run mode is what is specified.  Otherwise
returns 0.

=item is_allowed_role(allowed_roles => @role_names)

This function returns 1 if the user's roles include any of the roles in
@role_names.  Currently it returns 1 when this is not found as well but when 
role permissions are introduced, this will change to 0.

=item num_text_rows (string => $string, cols => $number, max => $number);

This function determines the likely number of rows needed to hold text in a 
textbox.  It returns either that number or max, which ever is lower.

=item merge ($hashref, keys => @list, index => $number);

This command merges the $hashref into the current object.  If keys are 
specified, only those keys are used.  Otherwise all keys are merged.

If an index is specified, the merged keys are given a form of 
"$key" . "_$index", otherwise the key is used on both sides.

=item redirect (msg => $string)

This function redirects to the script and argument set determined by 
$self->{callback}, and if this is not set, goes to an info screen and prints
$msg.

=item redo_rows (fields => \@list, count => $integer, [index => $string);

This function is undergoing serious redesign at the moment.  If index is 
defined, that field is used for ordering the rows.  If not, runningnumber is 
used.  Behavior is not defined when index points to a field containing 
non-numbers.

=item set (@attrs)

Copies the given key=>vars to $self. Allows for finer control of 
merging hashes into self.

=item remove_cgi_globals()

Removes all elements starting with a . because these elements conflict with the
ability to hide the entire structure for things like CSV lookups.

=back

=head1 Copyright (C) 2006, The LedgerSMB core team.

 # This work contains copyrighted information from a number of sources 
 # all used with permission.
 #
 # This file contains source code included with or based on SQL-Ledger
 # which is Copyright Dieter Simader and DWS Systems Inc. 2000-2005
 # and licensed under the GNU General Public License version 2 or, at
 # your option, any later version.  For a full list including contact
 # information of contributors, maintainers, and copyright holders, 
 # see the CONTRIBUTORS file.
 #
 # Original Copyright Notice from SQL-Ledger 2.6.17 (before the fork):
 # Copyright (C) 2000
 #
 #  Author: DWS Systems Inc.
 #     Web: http://www.sql-ledger.org
 #
 # Contributors: Thomas Bayen <bayen@gmx.de>
 #               Antti Kaihola <akaihola@siba.fi>
 #               Moritz Bunkus (tex)
 #               Jim Rawlings <jim@your-dba.com> (DB2)
 #====================================================================
=cut

use CGI::Simple;
$CGI::Simple::DISABLE_UPLOADS = 0;
use Math::BigFloat;
use LedgerSMB::Sysconfig;
use Data::Dumper;
use LedgerSMB::Auth;
use LedgerSMB::Template;
use LedgerSMB::Locale;
use LedgerSMB::User;
use strict;

$CGI::Simple::POST_MAX = -1;

package LedgerSMB;
our $VERSION = '1.2.99';

sub new {
    my $type   = shift @_;
    my $argstr = shift @_;
    my %cookie;
    my $self = {};


    $self->{version} = $VERSION;
    $self->{dbversion} = "1.2.0";
    bless $self, $type;
    my $query = ($argstr) ? new CGI::Simple($argstr) : new CGI::Simple;
    my $params = $query->Vars;
    $self->{VERSION} = $VERSION;

    $self->merge($params);
    $self->{have_latex} = $LedgerSMB::Sysconfig::latex;

    # Adding this so that empty values are stored in the db as NULL's.  If
    # stored procedures want to handle them differently, they must opt to do so.
    # -- CT
    for (keys %$self){
        if ($self->{$_} eq ''){
            $self->{$_} = undef;
        }
    }

    if ($self->is_run_mode('cgi', 'mod_perl')) {
        $ENV{HTTP_COOKIE} =~ s/;\s*/;/g;
        my @cookies = split /;/, $ENV{HTTP_COOKIE};
        foreach (@cookies) {
            my ( $name, $value ) = split /=/, $_, 2;
            $cookie{$name} = $value;
        }
    }

    $self->{action} =~ s/\W/_/g;
    $self->{action} = lc $self->{action};

    if ( $self->{path} eq "bin/lynx" ) {
        $self->{menubar} = 1;

        # Applying the path is deprecated.  Use menubar instead.  CT.
        $self->{lynx} = 1;
        $self->{path} = "bin/lynx";
    }
    else {
        $self->{path} = "bin/mozilla";

    }

    if ( ( $self->{script} =~ m#(\.\.|\\|/)# ) ) {
        $self->error("Access Denied");
    }
    if (!$self->{script}) {
        $self->{script} = 'login.pl';
    }
#    if ($self->{action} eq 'migrate_user'){
#        return $self;
#    }
    if ($self->{script} eq 'login.pl' &&
        ($self->{action} eq 'authenticate'  || $self->{action} eq '__default' 
		|| !$self->{action})){
        return $self;
    }
    if (!$self->{company} && $self->is_run_mode('cgi', 'mod_perl')){
         my $ccookie = $cookie{LedgerSMB};
         $ccookie =~ s/.*:([^:]*)$/$1/;
         $self->{company} = $ccookie;
    }

    $self->_db_init;

    if ($self->is_run_mode('cgi', 'mod_perl')) {
       #check for valid session unless this is an inital authentication
       #request -- CT
       if (!LedgerSMB::Auth::session_check( $cookie{"LedgerSMB"}, $self) ) {
            print STDERR "Session did not check";
            $self->_get_password("Session Expired");
            exit;
       }
       $self->{_user} = LedgerSMB::User->fetch_config($self);
    }
    my %date_setting = (
        'mm/dd/yy' => "SQL, US",
        'mm-dd-yy' => "POSTGRES, US",
        'dd/mm/yy' => "SQL, EUROPEAN",
        'dd-mm-yy' => "POSTGRES, EUROPEAN",
        'dd.mm.yy' => "GERMAN",
    );

    $self->{dbh}->do("set DateStyle to '" 
		.$date_setting{$self->{_user}->{dateformat}}."'");
    #my $locale   = LedgerSMB::Locale->get_handle($self->{_user}->{countrycode})
    $self->{_locale} = LedgerSMB::Locale->get_handle('en') # temporary
     or $self->error(__FILE__.':'.__LINE__.": Locale not loaded: $!\n");

    $self->{stylesheet} = $self->{_user}->{stylesheet};

    return $self;

}

#This function needs to be moved into the session handler.
sub _get_password {
    my ($self) = shift @_;
    $self->{sessionexpired} = shift @_;
    LedgerSMB::Auth::credential_prompt();
    exit;
}

sub debug {
    my $self = shift @_;
    my $args = shift @_;
    my $file;
    if (scalar keys %$args){
        $file = $args->{'file'};
    }
    my $d    = Data::Dumper->new( [$self] );
    $d->Sortkeys(1);

    if ($file) {
        open( FH, '>', "$file" ) or die $!;
        print FH $d->Dump();
        close(FH);
    }
    else {
        print "\n";
        print $d->Dump();
    }

}

sub escape {
    my $self = shift;
    my %args = @_;
    my $str  = $args{string};

    my $regex = qr/([^a-zA-Z0-9_.-])/;
    $str =~ s/$regex/sprintf("%%%02x", ord($1))/ge;
    return $str;
}

sub is_blank {
    my $self = shift @_;
    my %args = @_;
    my $name = $args{name};
    if (not defined $name){
        # TODO: Raise error 
    }
    my $rc;
    if ( $self->{$name} =~ /^\s*$/ ) {
        $rc = 1;
    }
    else {
        $rc = 0;
    }
    $rc;
}

sub is_run_mode {
    my $self = shift @_;
    my $mode = lc shift @_;
    my $rc   = 0;
    if ( $mode eq 'cgi' && $ENV{GATEWAY_INTERFACE} ) {
        $rc = 1;
    }
    elsif ( $mode eq 'cli' && !( $ENV{GATEWAY_INTERFACE} || $ENV{MOD_PERL} ) ) {
        $rc = 1;
    }
    elsif ( $mode eq 'mod_perl' && $ENV{MOD_PERL} ) {
        $rc = 1;
    }
    $rc;
}

sub num_text_rows {
    my $self    = shift @_;
    my %args    = @_;
    my $string  = $args{string};
    my $cols    = $args{cols};
    my $maxrows = $args{max};

    my $rows = 0;

    for ( split /\n/, $string ) {
        my $line = $_;
        while ( length($line) > $cols ) {
            my $fragment = substr( $line, 0, $cols + 1 );
            $fragment =~ s/^(.*)\W.*$/$1/;
            $line =~ s/$fragment//;
            if ( $line eq $fragment ) {    # No word breaks!
                $line = "";
            }
            ++$rows;
        }
        ++$rows;
    }

    if ( !defined $maxrows ) {
        $maxrows = $rows;
    }

    return ( $rows > $maxrows ) ? $maxrows : $rows;

}

sub redirect {
    my $self = shift @_;
    my %args = @_;
    my $msg  = $args{msg};

    if ( $self->{callback} || !$msg ) {

        main::redirect();
	exit;
    }
    else {

        $self->info($msg);
    }
}

# TODO:  Either we should have an amount class with formats and such attached
# Or maybe we should move this into the user class...
sub format_amount {

    # Based on SQL-Ledger's Form::format_amount
    my $self     = shift @_;
    my %args     = @_;
    my $myconfig = $args{user} || $self->{_user};
    my $amount   = $args{amount};
    my $places   = $args{precision};
    my $dash     = $args{neg_format};

    my $negative;
    if ($amount) {
        $amount = $self->parse_amount( 'user' => $myconfig, 'amount' => $amount );
        $negative = ( $amount < 0 );
        $amount =~ s/-//;
    }

    if ( $places =~ /\d+/ ) {

        #$places = 4 if $places == 2;
        $amount = $self->round_amount( $amount, $places );
    }

    # is the amount negative

    # Parse $myconfig->{numberformat}

    my ( $ts, $ds ) = ( $1, $2 );

    if ($amount) {

        if ( $myconfig->{numberformat} ) {

            my ( $whole, $dec ) = split /\./, "$amount";
            $amount = join '', reverse split //, $whole;

            if ($places) {
                $dec .= "0" x $places;
                $dec = substr( $dec, 0, $places );
            }

            if ( $myconfig->{numberformat} eq '1,000.00' ) {
                $amount =~ s/\d{3,}?/$&,/g;
                $amount =~ s/,$//;
                $amount = join '', reverse split //, $amount;
                $amount .= "\.$dec" if ( $dec ne "" );
            } 
	    elsif ( $myconfig->{numberformat} eq '1 000.00' ) {
                $amount =~ s/\d{3,}?/$& /g;
                $amount =~ s/\s$//;
                $amount = join '', reverse split //, $amount;
                $amount .= "\.$dec" if ( $dec ne "" );
            } 
	    elsif ( $myconfig->{numberformat} eq "1'000.00" ) {
                $amount =~ s/\d{3,}?/$&'/g;
                $amount =~ s/'$//;
                $amount = join '', reverse split //, $amount;
                $amount .= "\.$dec" if ( $dec ne "" );
            } 
	    elsif ( $myconfig->{numberformat} eq '1.000,00' ) {
                $amount =~ s/\d{3,}?/$&./g;
                $amount =~ s/\.$//;
                $amount = join '', reverse split //, $amount;
                $amount .= ",$dec" if ( $dec ne "" );
            } 
	    elsif ( $myconfig->{numberformat} eq '1000,00' ) {
                $amount = "$whole";
                $amount .= ",$dec" if ( $dec ne "" );
            } 
	    elsif ( $myconfig->{numberformat} eq '1000.00' ) {
                $amount = "$whole";
                $amount .= ".$dec" if ( $dec ne "" );
            }

            if ( $dash =~ /-/ ) {
                $amount = ($negative) ? "($amount)" : "$amount";
            }
            elsif ( $dash =~ /DRCR/ ) {
                $amount = ($negative) ? "$amount DR" : "$amount CR";
            }
            else {
                $amount = ($negative) ? "-$amount" : "$amount";
            }
        }

    }
    else {

        if ( $dash eq "0" && $places ) {

            if ( $myconfig->{numberformat} =~ /0,00$/ ) {
                $amount = "0" . "," . "0" x $places;
            }
            else {
                $amount = "0" . "." . "0" x $places;
            }

        }
        else {
            $amount = ( $dash ne "" ) ? "$dash" : "";
        }
    }

    $amount;
}

# This should probably go to the User object too.
sub parse_amount {
    my $self     = shift @_;
    my %args     = @_;
    my $myconfig = $args{user} || $self->{_user};
    my $amount   = $args{amount};

    if ( $amount eq '' or ! defined $amount) {
        return 0;
    }

    if ( UNIVERSAL::isa( $amount, 'Math::BigFloat' ) )
    {    # Amount may not be an object
        return $amount;
    }
    my $numberformat = $myconfig->{numberformat};

    if (   ( $numberformat eq '1.000,00' )
        || ( $numberformat eq '1000,00' ) )
    {

        $amount =~ s/\.//g;
        $amount =~ s/,/./;
    }
    elsif ( $numberformat eq '1 000.00' ) {
        $amount =~ s/\s//g;
    }
    elsif ( $numberformat eq "1'000.00" ) {
        $amount =~ s/'//g;
    }

    $amount =~ s/,//g;
    if ( $amount =~ s/\((\d*\.?\d*)\)/$1/ ) {
        $amount = $1 * -1;
    }
    elsif ( $amount =~ s/(\d*\.?\d*)\s?DR/$1/ ) {
        $amount = $1 * -1;
    }
    $amount =~ s/\s?CR//;
    $amount = new Math::BigFloat($amount);
    if ($amount->is_nan){
        $self->error("Invalid number detected during parsing");
    }
    return ( $amount * 1 );
}

sub round_amount {

    my ( $self, $amount, $places ) = @_;

    # These rounding rules follow from the previous implementation.
    # They should be changed to allow different rules for different accounts.
    if ($amount >= 0) {
        Math::BigFloat->round_mode('+inf');
    } 
    else {
        Math::BigFloat->round_mode('-inf');
    } 

    if ($places >= 0) {
        $amount = Math::BigFloat->new($amount)->ffround( -$places );
    } 
    else {
        $amount = Math::BigFloat->new($amount)->ffround( -( $places - 1 ) );
    } 
    $amount->precision(undef);

    return $amount;
}

sub call_procedure {
    my $self     = shift @_;
    my %args     = @_;
    my $procname = $args{procname};
    my @call_args;
    @call_args = @{ $args{args} } if defined $args{args};
    my $order_by = $args{order_by};
    my $argstr   = "";
    my @results;

    $procname = $self->{dbh}->quote_identifier($procname);
    for ( 1 .. scalar @call_args ) {
        $argstr .= "?, ";
    }
    $argstr =~ s/\, $//;
    my $query = "SELECT * FROM $procname()";
    if ($order_by){
        $query .= " ORDER BY $order_by";
    }
    $query =~ s/\(\)/($argstr)/;
    my $sth = $self->{dbh}->prepare($query);
    if (scalar @call_args){
        $sth->execute(@call_args) || $self->error($self->{dbh}->errstr);
    } else {
        $sth->execute() || $self->error($self->{dbh}->errstr);
    }
   
    my @types = @{$sth->{TYPE}};
    my @names = @{$sth->{NAME_lc}};
    while ( my $ref = $sth->fetchrow_hashref('NAME_lc') ) {
	for (0 .. $#names){
            #   numeric            float4/real
            if ($types[$_] == 3 or $types[$_] == 2) {
                $ref->{$names[$_]} = Math::BigFloat->new($ref->{$names[$_]});
            }
        }
        push @results, $ref;
    }
    @results;
}

# Keeping this here due to common requirements
sub is_allowed_role {
    my $self = shift @_;
    my %args = @_;
    my @roles = @{$args{allowed_roles}};
    for my $role (@roles){
        if (scalar(grep /^$role$/, $self->{_roles})){
            return 1;
        }
    }
    return 1; # TODO change to 0 when the role system is implmented
}

# This should probably be moved to User too...
sub date_to_number {

    #based on SQL-Ledger's Form::datetonum
    my $self     = shift @_;
    my %args     = @_;
    my $myconfig = $args{user};
    my $date     = $args{date};

    my ( $yy, $mm, $dd );
    if ( $date && $date =~ /\D/ ) {

        if ( $date =~ /^\d{4}-\d\d-\d\d$/ ) {
            ( $yy, $mm, $dd ) = split /\D/, $date;
        } elsif ( $myconfig->{dateformat} =~ /^yy/ ) {
            ( $yy, $mm, $dd ) = split /\D/, $date;
        } elsif ( $myconfig->{dateformat} =~ /^mm/ ) {
            ( $mm, $dd, $yy ) = split /\D/, $date;
        } elsif ( $myconfig->{dateformat} =~ /^dd/ ) {
            ( $dd, $mm, $yy ) = split /\D/, $date;
        }

        $dd *= 1;
        $mm *= 1;
        $yy += 2000 if length $yy == 2;

        $dd = substr( "0$dd", -2 );
        $mm = substr( "0$mm", -2 );

        $date = "$yy$mm$dd";
    }

    $date;
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

sub _db_init {
    my $self     = shift @_;
    my %args     = @_;
    my $creds = LedgerSMB::Auth::get_credentials();
  
    $self->{login} = $creds->{login};
    if (!$self->{company}){ 
        $self->{company} = $LedgerSMB::Sysconfig::default_db;
    }
    my $dbname = $self->{company};

    # Note that we have to request the login/password again if the db
    # connection fails since this probably means bad credentials are entered.
    # Just in case, however, I think it is a good idea to include the DBI
    # error string.  CT
    $self->{dbh} = DBI->connect(
        "dbi:Pg:dbname=$dbname", "$creds->{login}", "$creds->{password}", { AutoCommit => 0 }
    ); 
     my $dbh = $self->{dbh};


    if (($self->{script} eq 'login.pl') && ($self->{action} eq 
        'authenticate')){

        return;
    }
    elsif (!$dbh){
        $self->_get_password;
    }
    $dbh->{pg_server_prepare} = 0;
    $dbh->{pg_enable_utf8} = 1;

    # This is the general version check
    my $sth = $dbh->prepare("
            SELECT value FROM defaults 
             WHERE setting_key = 'version'");
    $sth->execute;
    my ($dbversion) = $sth->fetchrow_array;
    if ($dbversion ne $self->{dbversion}){
        $self->error("Database is not the expected version.  Was $dbversion, expected $self->{dbversion}");
    }



    my $query = "SELECT t.extends, 
			coalesce (t.table_name, 'custom_' || extends) 
			|| ':' || f.field_name as field_def
		FROM custom_table_catalog t
		JOIN custom_field_catalog f USING (table_id)";
    my $sth = $self->{dbh}->prepare($query);
    $sth->execute;
    my $ref;
    while ( $ref = $sth->fetchrow_hashref('NAME_lc') ) {
        push @{ $self->{custom_db_fields}{ $ref->{extends} } },
          $ref->{field_def};
    }
}

# Deprecated, only here for old code
sub dberror{
   my $self = shift @_;
   $self->error(@_);
}

sub redo_rows {

    my $self  = shift @_;
    my %args  = @_;
    my @flds  = @{ $args{fields} };
    my $count = $args{count};
    my $index = ( $args{index} ) ? $args{index} : 'runningnumber';

    my @rows;
    my $i;    # incriment counter use only
    for $i ( 1 .. $count ) {
        my $temphash = { _inc => $i };
        for my $fld (@flds) {
            $temphash->{$fld} = $self->{ "$fld" . "_$i" };
        }
        push @rows, $temphash;
    }
    $i = 1;
    for my $row ( sort { $a->{index} <=> $b->{index} } @rows ) {
        for my $fld (@flds) {
            $self->{ "$fld" . "_$i" } = $row->{$fld};
        }
        ++$i;
    }
}

sub merge {
    my ( $self, $src ) = @_;
    for my $arg ( $self, $src ) {
        shift;
    }
    my %args  = @_;
    my @keys;
    if (defined $args{keys}){
         @keys  = @{ $args{keys} };
    }
    my $index = $args{index};
    if ( !scalar @keys ) {
        @keys = keys %{$src};
    }
    for my $arg ( @keys ) {
        my $dst_arg;
        if ($index) {
            $dst_arg = $arg . "_$index";
        }
        else {
            $dst_arg = $arg;
        }
        $self->{$dst_arg} = $src->{$arg};
    }
}

sub type {
    
    my $self = shift @_;
    
    if (!$ENV{REQUEST_METHOD} or 
        ( !grep {$ENV{REQUEST_METHOD} eq $_} ("HEAD", "GET", "POST") ) ) {
        
        $self->error("Request method unset or set to unknown value");
    }
    
    return $ENV{REQUEST_METHOD};
}

sub DESTROY {}

sub set {
    
    my $self = shift @_;
    my %args = @_;
    
    for my $arg (keys(%args)) {
        $self->{$arg} = $args{$arg};
    }
    return 1;    

}

sub remove_cgi_globals {
    my ($self) = @_;
    for my $key (keys %$self){
        if ($key =~ /^\./){
            delete $self->{key}
        }
    }
}

sub take_top_level {
   my ($self) = @_;
   my $return_hash = {};
   for my $key (keys %$self){
       if (!ref($self->{$key}) && $key !~ /^\./){
          $return_hash->{$key} = $self->{$key}
       }
   }
   return $return_hash;
}

1;


