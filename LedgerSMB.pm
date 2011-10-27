
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

=item open_form()

This sets a $self->{form_id} to be used in later form validation (anti-XSRF 
measure).

=item check_form()

This returns true if the form_id was associated with the session, and false if 
not.  Use this if the form may be re-used (back-button actions are valid).

=item close_form()

Identical with check_form() above, but also removes the form_id from the 
session.  This should be used when back-button actions are not valid.

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

=item is_allowed_role({allowed_roles => @role_names})

This function returns 1 if the user's roles include any of the roles in
@role_names.  

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

=item get_default_value_by_key($key)

Retrieves a default value for the given key, it is just a wrapper on LedgerSMB::Setting;


=item call_procedure( procname => $procname, args => $args )

Function that allows you to call a stored procedure by name and map the appropriate argument to the function values.

Args is an arrayref.  The members of args can be scalars or arrayrefs in which 
case they are just bound to the placeholders (arrayref to Pg array conversion
occurs automatically in DBD::Pg 2.x), or they can be hashrefs of the following
syntax: {value => $data, type=> $db_type}.  The type field is any SQL type 
DBD::Pg supports (such as 'PG_BYTEA').

=item dberror()

Localizes and returns database errors and error codes within LedgerSMB

=item error()

Returns HTML errors in LedgerSMB. Needs refactored into a general Error class.

=item get_user_info()

Loads user configuration info from LedgerSMB::User

=item round_amount() 

Uses Math::Float with an amount and a set number of decimal places to round the amount and return it.

Defaults to the default decimal places setting in the LedgerSMB configuration if there is no places argument passed in.

They should be changed to allow different rules for different accounts.

=item sanitize_for_display()

Expands a hash into human-readable key => value pairs, and formats and rounds amounts, recursively expanding hashes until there are no hash members present.

=item take_top_level()

Removes blank keys and non-reference keys from a hash and returns a hash with only non-blank and referenced keys.

=item type()

Ensures that the $ENV{REQUEST_METHOD} is defined and either "HEAD", "GET", "POST".

=item finalize_request()

This function throws a CancelFurtherProcessing exception to be caught
by the outermost processing script.  This construct allows the outer
script and intermediate levels to clean up, if required.

This construct replaces 'exit;' calls randomly scattered
around the code everywhere.

=cut


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
use Error;
use LedgerSMB::Auth;
use LedgerSMB::CancelFurtherProcessing;
use LedgerSMB::Template;
use LedgerSMB::Locale;
use LedgerSMB::User;
use LedgerSMB::Setting;
use LedgerSMB::Log;
use LedgerSMB::Company_Config;
use strict;

$CGI::Simple::POST_MAX = -1;

package LedgerSMB;
our $VERSION = '1.3.2';

my $logger = Log::Log4perl->get_logger('LedgerSMB');

sub new {
    #my $type   = "" unless defined shift @_;
    #my $argstr = "" unless defined shift @_;
    my $type   = shift @_;
    my $argstr = shift @_;
    my %cookie;
    my $self = {};

    $type = "" unless defined $type;
    $argstr = "" unless defined $argstr;

    $logger->debug("Begin LedgerSMB.pm");

    $self->{version} = $VERSION;
    $self->{dbversion} = "1.3.3";
    
    bless $self, $type;
    $logger->debug("LedgerSMB::new: \$argstr = $argstr");
    my $query = ($argstr) ? new CGI::Simple($argstr) : new CGI::Simple;
    # my $params = $query->Vars; returns a tied hash with keys that
    # are not parameters of the CGI query.
    my %params = $query->Vars;
    $logger->debug("LedgerSMB::new: params = ", Data::Dumper::Dumper(\%params));
    $self->{VERSION} = $VERSION;
    $self->{_request} = $query;

    $self->merge(\%params);
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
    $self->{action} = "" unless defined $self->{action};
    $self->{action} =~ s/\W/_/g;
    $self->{action} = lc $self->{action};

    $self->{path} = "" unless defined $self->{path};

    if ( $self->{path} eq "bin/lynx" ) {
        $self->{menubar} = 1;

        # Applying the path is deprecated.  Use menubar instead.  CT.
        $self->{lynx} = 1;
        $self->{path} = "bin/lynx";
    }
    else {
        $self->{path} = "bin/mozilla";

    }

    $ENV{SCRIPT_NAME} = "" unless defined $ENV{SCRIPT_NAME};

    $ENV{SCRIPT_NAME} =~ m/([^\/\\]*.pl)\?*.*$/;
    $self->{script} = $1 unless !defined $1;
    $self->{script} = "" unless defined $self->{script};

    if ( ( $self->{script} =~ m#(\.\.|\\|/)# ) ) {
        $self->error("Access Denied");
    }
    if (!$self->{script}) {
        $self->{script} = 'login.pl';
    }
    $logger->debug("LedgerSMB.pm: \$self->{script} = $self->{script}");
    $logger->debug("LedgerSMB.pm: \$self->{action} = $self->{action}");
#    if ($self->{action} eq 'migrate_user'){
#        return $self;
#    }

    # This is suboptimal.  We need to have a better way for 1.4
    if ($self->{script} eq 'login.pl' &&
        ($self->{action} eq 'authenticate'  || $self->{action} eq '__default' 
		|| !$self->{action})){
        return $self;
    }
    if ($self->{script} eq 'setup.pl'){
        return $self;
    }
    if (!$self->{company} && $self->is_run_mode('cgi', 'mod_perl')){
         my $ccookie = $cookie{${LedgerSMB::Sysconfig::cookie_name}};
         $ccookie =~ s/.*:([^:]*)$/$1/;
         if($ccookie ne 'Login') { $self->{company} = $ccookie; } 
    }
    $logger->debug("LedgerSMB.pm: \$self->{company} = $self->{company}");

    $self->_db_init;

    LedgerSMB::Company_Config::initialize($self);


    if ($self->is_run_mode('cgi', 'mod_perl') and !$ENV{LSMB_NOHEAD}) {
       #check for valid session unless this is an inital authentication
       #request -- CT
       if (!LedgerSMB::Auth::session_check( $cookie{${LedgerSMB::Sysconfig::cookie_name}}, $self) ) {
            $logger->error("Session did not check");
            $self->_get_password("Session Expired");
            exit;
       }
       $logger->debug("LedgerSMB::new: session_check completed OK");
    }
    $self->get_user_info;
    my %date_setting = (
        'mm/dd/yy' => "SQL, US",
        'mm-dd-yy' => "POSTGRES, US",
        'dd/mm/yy' => "SQL, EUROPEAN",
        'dd-mm-yy' => "POSTGRES, EUROPEAN",
        'dd.mm.yy' => "GERMAN",
    );

    $self->{dbh}->do("set DateStyle to '" 
		.$date_setting{$self->{_user}->{dateformat}}."'");
    my $locale   = LedgerSMB::Locale->get_handle($self->{_user}->{language})
#    $self->{_locale} = LedgerSMB::Locale->get_handle('en') # temporary
     or $self->error(__FILE__.':'.__LINE__.": Locale not loaded: $!\n");
    $self->{_locale} = $locale;

    $self->{stylesheet} = $self->{_user}->{stylesheet};

    $logger->debug("End LedgerSMB.pm");

    return $self;

}

sub open_form {
    my ($self, $args) = @_;
    if (!$ENV{GATEWAY_INTERFACE}){
        return 1;
    }
    my @vars = $self->call_procedure(procname => 'form_open', 
                              args => [$self->{session_id}],
                              continue_on_error => 1
    );
    if ($args->{commit}){
       $self->{dbh}->commit;
    }
    $self->{form_id} = $vars[0]->{form_open};
}

sub check_form {
    my ($self) = @_;
    if (!$ENV{GATEWAY_INTERFACE}){
        return 1;
    }
    my @vars = $self->call_procedure(procname => 'form_check', 
                              args => [$self->{session_id}, $self->{form_id}]
    );
    return $vars[0]->{form_check};
}

sub close_form {
    my ($self) = @_;
    if (!$ENV{GATEWAY_INTERFACE}){
        return 1;
    }
    my @vars = $self->call_procedure(procname => 'form_close', 
                              args => [$self->{session_id}, $self->{form_id}]
    );
    delete $self->{form_id};
    return $vars[0]->{form_close};
}

sub get_user_info {
    my ($self) = @_;
    $self->{_user} = LedgerSMB::User->fetch_config($self);
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
    $str = "" unless defined $str;

    my $regex = qr/([^a-zA-Z0-9_.-])/;
    $str =~ s/$regex/sprintf("%%%02x", ord($1))/ge;
    return $str;
}

sub is_blank {
    my $self = shift @_;
    my %args = @_;
    my $name = $args{name};
    my $rc;

    if (not defined $name){
        $self->{_locale} = LedgerSMB::Locale->get_handle('en') unless defined $self->{_locale};
        $self->error($self->{_locale}->text('Field \"Name\" Not Defined'));
    }

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
    my %args  = (ref($_[0]) eq 'HASH')? %{$_[0]}: @_;
    my $myconfig = $args{user} || $self->{_user};
    my $amount   = $args{amount};
    my $places   = $args{precision};
    my $dash     = $args{neg_format};
    my $format   = $args{format};

    $dash = "" unless defined $dash;

    if (!defined $format){
       $format = $myconfig->{numberformat}
    }
    if (!defined $amount){
        return undef;
    }
    if (!defined $args{precision} and defined $args{money}){
       $places = $LedgerSMB::Sysconfig::decimal_places;
    }

    my $negative;
    if (defined $amount and ! UNIVERSAL::isa($amount, 'Math::BigFloat' )) {
        $amount = $self->parse_amount( 'user' => $myconfig, 'amount' => $amount );
    }
    $negative = ( $amount < 0 );
    $amount->babs();

    $places = "" unless defined $places;
    if ( $places =~ /\d+/ ) {

        #$places = 4 if $places == 2;
        $amount = $self->round_amount( $amount, $places );
    }

    # is the amount negative

    # Parse $myconfig->{numberformat}

    my ( $ts, $ds ) = ( $1, $2 );

    if (defined $amount) {

        if ( $format ) {

            my ( $whole, $dec ) = split /\./, "$amount";
            $dec = "" unless defined $dec;
            $amount = join '', reverse split //, $whole;

            if ($places) {
                $dec .= "0" x $places;
                $dec = substr( $dec, 0, $places );
            }

            if ( $format eq '1,000.00' ) {
                $amount =~ s/\d{3,}?/$&,/g;
                $amount =~ s/,$//;
                $amount = join '', reverse split //, $amount;
                $amount .= "\.$dec" if ( $dec ne "" );
            } 
	    elsif ( $format eq '1 000.00' ) {
                $amount =~ s/\d{3,}?/$& /g;
                $amount =~ s/\s$//;
                $amount = join '', reverse split //, $amount;
                $amount .= "\.$dec" if ( $dec ne "" );
            } 
	    elsif ( $format eq "1'000.00" ) {
                $amount =~ s/\d{3,}?/$&'/g;
                $amount =~ s/'$//;
                $amount = join '', reverse split //, $amount;
                $amount .= "\.$dec" if ( $dec ne "" );
            } 
	    elsif ( $format eq '1.000,00' ) {
                $amount =~ s/\d{3,}?/$&./g;
                $amount =~ s/\.$//;
                $amount = join '', reverse split //, $amount;
                $amount .= ",$dec" if ( $dec ne "" );
            } 
	    elsif ( $format eq '1000,00' ) {
                $amount = "$whole";
                $amount .= ",$dec" if ( $dec ne "" );
            } 
	    elsif ( $format eq '1000.00' ) {
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

            if ( $format =~ /0,00$/ ) {
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

    if ( ! defined $amount or $amount eq '' ) {
        return Math::BigFloat->bzero();
    }

    if ( UNIVERSAL::isa( $amount, 'Math::BigFloat' ) )
    {   #Avoiding double-parse issues 
        return $amount;
    }
    my $numberformat = $myconfig->{numberformat};
    $numberformat = "" unless defined $numberformat;

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
    
    #
    # We will grab the default value, if it isnt defined
    #
    if (!defined $places){
       $places = ${LedgerSMB::Sysconfig::decimal_places};
    }
    
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

# This should probably be moved to User too...
sub date_to_number {

    #based on SQL-Ledger's Form::datetonum
    my $self     = shift @_;
    my %args     = @_;
    my $myconfig = $args{user};
    my $date     = $args{date};

    $date = "" unless defined $date;

    my ( $yy, $mm, $dd );
    if ( $date ne "" && $date && $date =~ /\D/ ) {

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

sub sanitize_for_display {
    my $self = shift;
    my $var = shift;
    $self->error('Untested API');
    if (!$var){ 
	$var = $self;
    }
    for my $k (keys %$var){
	my $type = ref($var);
	if (UNIVERSAL::isa($var->{$k}, 'Math::BigFloat')){
              $var->{$k} = 
                  $self->format_amount({amount => $var->{$k}});
	}
	elsif ($type == 'HASH'){
               $self->sanitize_for_display($var->{$k});
        }
    }
    
}

sub finalize_request {
    throw CancelFurtherProcessing();
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

sub _db_init {
    my $self     = shift @_;
    my %args     = @_;
    my $creds = LedgerSMB::Auth::get_credentials();

    $logger->debug("LedgerSMB::_db_init: start");
  
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
        if (!$dbh){
            $self->{_auth_error} = $DBI::errstr;
        }

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
    $sth = $dbh->prepare("
            SELECT value FROM defaults 
             WHERE setting_key = 'role_prefix'");
    $sth->execute;


    ($self->{_role_prefix}) = $sth->fetchrow_array;
    if ($dbversion ne $self->{dbversion}){
        $self->error("Database is not the expected version.  Was $dbversion, expected $self->{dbversion}");
    }

    $sth = $dbh->prepare('SELECT check_expiration()');
    $sth->execute;
    ($self->{warn_expire}) = $sth->fetchrow_array;
   
    if ($self->{warn_expire}){
        $sth = $dbh->prepare('SELECT user__check_my_expiration()');
        $sth->execute;
        ($self->{pw_expires})  = $sth->fetchrow_array;
    }


    my $query = "SELECT t.extends, 
			coalesce (t.table_name, 'custom_' || extends) 
			|| ':' || f.field_name as field_def
		FROM custom_table_catalog t
		JOIN custom_field_catalog f USING (table_id)";
    $sth = $self->{dbh}->prepare($query);
    $sth->execute;
    my $ref;
    while ( $ref = $sth->fetchrow_hashref('NAME_lc') ) {
        push @{ $self->{custom_db_fields}{ $ref->{extends} } },
          $ref->{field_def};
    }

    # Adding role list to self 
    $self->{_roles} = [];
    $query = "select rolname from pg_roles 
               where pg_has_role(SESSION_USER, 'USAGE')";
    $sth = $dbh->prepare($query);
    $sth->execute();
    while (my @roles = $sth->fetchrow_array){
        push @{$self->{_roles}}, $roles[0];
    }
}

#private, for db connection errors
sub _on_connection_error {
    for (@_){
        $logger->error("$_");
    }
}

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

sub redo_rows {

    my $self  = shift @_;
    my %args  = @_;
    my @flds  = @{ $args{fields} };
    my $count = $args{count};
    my $index = ( $args{index} ) ? $args{index} : 'runningnumber';

    my @rows;
    my $i;    # increment counter use only
    for $i ( 1 .. $count ) {
        my $temphash = { _inc => $i };
        for my $fld (@flds) {
            $temphash->{$fld} = $self->{ "$fld" . "_$i" };
        }
        push @rows, $temphash;
    }
    $i = 1;
    for my $row ( sort { $a->{$index} <=> $b->{$index} } @rows ) {
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
        if ( defined $dst_arg && defined $src->{$arg} )
        {
            $logger->debug("LedgerSMB.pm: merge setting $dst_arg to $src->{$arg}");
        }
        elsif ( !defined $dst_arg && defined $src->{$arg} )
        {
            $logger->debug("LedgerSMB.pm: merge setting \$dst_arg is undefined \$src->{\$arg} is defined $src->{$arg}");
        }
        elsif ( defined $dst_arg && !defined $src->{$arg} )
        {
            $logger->debug("LedgerSMB.pm: merge setting \$dst_arg is defined $dst_arg \$src->{\$arg} is undefined");
        }
        elsif ( !defined $dst_arg && !defined $src->{$arg} )
        {
            $logger->debug("LedgerSMB.pm: merge setting \$dst_arg is undefined \$src->{\$arg} is undefined");
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



sub get_default_value_by_key 
{
    my ($self, $key) = @_;
    my $Settings = LedgerSMB::Setting->new({base => $self, copy => 'base'});
    $Settings->{key} = $key;
    $Settings->get;    
    $Settings->{value};    
}
1;


