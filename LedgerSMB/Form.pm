=head1 NAME

LedgerSMB::Form - Provides general legacy support functions and the central object.

=head1 SYNOPSIS

This module provides general legacy support functions and the central object

=head1 STATUS

Deprecated

=head1 COPYRIGHT

 #====================================================================
 # LedgerSMB
 # Small Medium Business Accounting software
 # http://www.ledgersmb.org/
 #
 # Copyright (C) 2006
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
 #
 # This file has undergone whitespace cleanup.
 #
 #====================================================================
 #
 # main package
 #
 #====================================================================

=head1 METHODS

=over

=cut

package Form;

#inline documentation
use strict;

use LedgerSMB::Sysconfig;
use LedgerSMB::Auth;
use List::Util qw(first);
use Time::Local;
use Cwd;
use File::Copy;
use LedgerSMB::Company_Config;
use LedgerSMB::PGNumber;
use Log::Log4perl;
use LedgerSMB::App_State;
use LedgerSMB::Setting::Sequence;
use LedgerSMB::Setting;
use Try::Tiny;
use Carp;
use DBI;

use charnames qw(:full);
use open ':utf8';
use base qw(LedgerSMB::Request);
use utf8;

use Data::Dumper;


our $logger = Log::Log4perl->get_logger('LedgerSMB::Form');

# To be later set in config, but also hardwired in Template::HTML --CT

=item new Form([$argstr])

Returns a reference to new Form object.  The initial set of attributes is
obtained from $argstr, a CGI query string, or $ARGV[0].  All the values are
run through unescape to undo any URI encoding.

The version and dbversion attributes are set to hardcoded values; action,
nextsub, path, script, and login are filtered to remove some dangerous values.
Both menubar and lynx are set if path matches lynx.

$form->error may be called to deny access on some attribute values.

=cut

sub new {

    my $type = shift;
    my $argstr = shift;

    $ENV{CONTENT_LENGTH} = 0 unless defined $ENV{CONTENT_LENGTH};
    my $dojo_theme = $LedgerSMB::Sysconfig::dojo_template;

    if ( ( $ENV{CONTENT_LENGTH} != 0 )
         && ( $ENV{CONTENT_LENGTH} > $LedgerSMB::Sysconfig::max_post_size )
         && $LedgerSMB::Sysconfig::max_post_size  != -1) {
        print "Status: 413\n Request entity too large\n\n";
        die "Error: Request entity too large\n";
    }
    if ($argstr) {
        $_ = $argstr;
    }elsif ($ENV{CONTENT_LENGTH}!= 0){
        read( STDIN, $_, $ENV{CONTENT_LENGTH} );
    }
    elsif ( $ENV{QUERY_STRING} ) {
        $_ = $ENV{QUERY_STRING};
    }
    elsif ( $ARGV[0] ) {
        $_ = $ARGV[0];
    }
    $logger->trace(" RequestIn=$_") if $_;
    my $self = {};
    my $orig = {};
    %$orig = split /[&=]/ unless !defined $_;
    for ( keys %$orig ) {
        $self->{unescape( "", $_) } = unescape( "", $orig->{$_} );
    }

    for my $p(keys %$self){
        utf8::decode($self->{$p});
        utf8::upgrade($self->{$p});
    }
    $self->{action} = "" unless defined $self->{action};
    $self->{dojo_theme} = $dojo_theme;

    if($self->{header})
    {
     delete $self->{header};
     $logger->error("self->{header} unset!!");
    }
    if ( substr( $self->{action}, 0, 1 ) !~ /( |\.)/ ) {
        $self->{action} = lc $self->{action};
        $self->{action} =~ s/( |-|,|\#|\/|\.$)/_/g;
        if (defined $self->{nextsub}){
            $self->{nextsub} = lc $self->{nextsub};
            $self->{nextsub} =~ s/( |-|,|\#|\/|\.$)/_/g;
        } else {
            $self->{nextsub} = '';
        }
    }

    $self->{login} = "" unless defined $self->{login};
    $self->{login} =~ s/[^a-zA-Z0-9._+\@'-]//g;

    if ($ENV{HTTP_COOKIE}){
        $ENV{HTTP_COOKIE} =~ s/;\s*/;/g;
        my %cookie;
        my @cookies = split /;/, $ENV{HTTP_COOKIE};
        foreach (@cookies) {
            my ( $name, $value ) = split /=/, $_, 2;
            $cookie{$name} = $value;
        }
        $self->{cookie} = $cookie{${LedgerSMB::Sysconfig::cookie_name}};
        $self->{cookie} =~ m/.*:([^:]*)$/;
        $self->{company} = $1
            if ! $self->{company};
    }

    $self->{menubar} = 1 if ( ( defined $self->{path} ) && ( $self->{path} =~ /lynx/i ) );

    #menubar will be deprecated, replaced with below
    $self->{lynx} = 1 if ( ( defined $self->{path} ) && ( $self->{path} =~ /lynx/i ) );

    $self->{version}   = "1.5.0-dev";
    $self->{dbversion} = "1.5.0-dev";

    bless $self, $type;

    if ( !defined $self->{path} or $self->{path} ne 'bin/lynx' ) { $self->{path} = 'bin/mozilla'; }
    #if ( $self->{path} ne 'bin/lynx' ) { $self->{path} = 'bin/mozilla'; }

    if ( ( $self->{script} )
        and not List::Util::first { $_ eq $self->{script} }
        @{LedgerSMB::Sysconfig::scripts} )
    {
        $self->error( 'Access Denied', __LINE__, __FILE__ );
    }

    if ( ( $self->{action} =~ /(:|')/ ) || ( $self->{nextsub} =~ /(:|')/ ) ) {
        $self->error( "Access Denied", __LINE__, __FILE__ );
    }

    #for ( keys %$self ) { $self->{$_} =~ s/\N{NULL}//g }
    for ( keys %$self ) { if ( defined $self->{$_} ) { $self->{$_}=~ s/\N{NULL}//g; } }

    if ( ($self->{action} eq 'redirect') || ($self->{nextsub} eq 'redirect') ) {
        $self->error( "Access Denied", __LINE__, __FILE__ );
    }
    $self;
}


sub open_form {
    my ($self) = @_;
    my @results ;
    if ($self->{form_id} =~ '^\s*$'){
        delete $self->{form_id};
    }
    if (!$ENV{GATEWAY_INTERFACE}){
        return 1;
    }
    #HV session_id not always set in LedgerSMB/Auth/DB.pm because of mix old,new code-chain?
    if($self->{session_id})
    {
    my $sth = $self->{dbh}->prepare('select form_open(?)');
    my $rc=$sth->execute($self->{session_id});#HV ERROR:Invalid session,if count(*) FROM session!=1,multiple login
    if(! $rc)
    {
     $logger->error("select form_open \$self->{form_id}=$self->{form_id} \$self->{session_id}=$self->{session_id} \$rc=$rc,invalid count FROM session?");
     return undef;
    }
    @results = $sth->fetchrow_array();
    }
    else
    {
     $logger->debug("no \$self->{session_id}!");
     return undef;
    }

    $self->{form_id} = $results[0];
    return $results[0];
}

sub check_form {
    my ($self) = @_;
    if (!$ENV{GATEWAY_INTERFACE}){
        return 1;
    }
    my $sth = $self->{dbh}->prepare('select form_check(?, ?)');
    $sth->execute($self->{session_id}, $self->{form_id});
    my @results = $sth->fetchrow_array();
    return $results[0];
}

sub close_form {
    my ($self) = @_;
    if ($self->{form_id} =~ '^\s*$'){
        delete $self->{form_id};
    }
    if (!$ENV{GATEWAY_INTERFACE}){
        return 1;
    }
    my $sth = $self->{dbh}->prepare('select form_close(?, ?)');
    $sth->execute($self->{session_id}, $self->{form_id});
    my @results = $sth->fetchrow_array();
    delete $self->{close_form};
    return $results[0];
}


=item open_form()

This sets a $self->{form_id} to be used in later form validation (anti-XSRF
measure).

=item check_form()

This returns true if the form_id was associated with the session, and false if
not.  Use this if the form may be re-used (back-button actions are valid).

=item close_form()

Identical with check_form() above, but also removes the form_id from the
session.  This should be used when back-button actions are not valid.


=item $form->escape($str[, $beenthere]);

Returns the URI-encoded $str.  $beenthere is a boolean that when true forces a
single encoding run.  When false, it escapes the string twice if it detects
that it is running on a version of Apache 2.0 earlier than 2.0.44.

Note that recurring transaction support depends on this function escaping ','.

=cut

sub escape {
    my ( $self, $str, $beenthere ) = @_;

    # for Apache 2 we escape strings twice
    if ( ( $ENV{SERVER_SIGNATURE} =~ /Apache\/2\.(\d+)\.(\d+)/ )
        && !$beenthere )
    {
        $str = $self->escape( $str, 1 ) if $1 == 0 && $2 < 44;
    }

    utf8::encode($str);
    # SC: Adding commas to the ignore list will break recurring transactions
    $str =~ s/([^a-zA-Z0-9_.-])/sprintf("%%%02x", ord($1))/ge;
    $str;

}

=item $form->unescape($str);

Returns the unencoded form of the URI-encoded $str.

=cut

sub unescape {
    my ( $self, $str ) = @_;

    $str =~ tr/+/ /;
    $str =~ s/\\$//;

    utf8::encode($str) if utf8::is_utf8($str);
    $str =~ s/%([0-9a-fA-Z]{2})/pack("C",hex($1))/eg;
    utf8::decode($str);
    $str =~ s/\r?\n/\n/g;

    $str;

}

=item $form->quote($str);

Replaces all double quotes in $str with '&quot;'.  Does nothing if $str is a
reference.

=cut

sub quote {
    my ( $self, $str ) = @_;

    if ( $str && !ref($str) ) {
        $str =~ s/"/&quot;/g;
    }

    $str;

}

=item $form->unquote($str);

Replaces all '&quot;' in $str with double quotes.  Does nothing if $str is a
reference.

=cut

sub unquote {
    my ( $self, $str ) = @_;

    if ( $str && !ref($str) ) {
        $str =~ s/&quot;/"/g;
    }

    $str;

}

=item $form->hide_form([...]);

Outputs hidden HTML form fields to STDOUT.  If values are passed into this
function, only those $form values are output.  If no values are passed in, all
$form values are output as well as deleting $form->{header}.  Values from the
$form object are run through $form->quote, whereas keys/names are not.

Sample output:

 <input type="hidden" name="login" value="testuser" />

=cut

sub hide_form {
    my $self = shift;

    if (@_) {

        for (@_) {
            print qq|<input type="hidden" name="$_" value="|
              . $self->quote( $self->{$_} )
              . qq|" />\n|;
        }

    }
    else {
        delete $self->{header};

        for ( sort keys %$self ) {
            print qq|<input type="hidden" name="$_" value="|
              . $self->quote( $self->{$_} )
              . qq|" />\n|;
        }
    }
}


=item $form->error($msg);

The function simply dies with message $msg however this is wrapped so that older
behavior occurs, from the handler, see below for this older behavior.

Output an error message, $msg.  If a CGI environment is detected, this outputs
an HTTP and HTML header section if required, and displays the message after
running it through $form->format_string.  If it is not a CGI environment and
$ENV{error_function} is set, call the specified function with $msg as the sole
argument.  Otherwise, this function simply dies with $msg.

This function does not return.  Execution is terminated at the end of the
appropriate path.

=cut

sub error {
    my ( $self, $msg ) = @_;
    Carp::croak $msg;
}

=item $form->finalize_request();

Stops further processing, allowing post-request cleanup on intermediate
levels by throwing an exception.

This function replaces explicit 'exit()' calls.

=cut

sub finalize_request {
    LedgerSMB::finalize_request();
    die;
}



=item $form->info($msg);

Output an informational message, $msg.  If a CGI environment is detected, this
outputs an HTTP and HTML header section if required, and displays the message
in bold tags without escaping.  If it is not a CGI environment and
$ENV{info_function} is set, call the specified function with $msg as the sole
argument.  Otherwise, this function simply prints $msg to STDOUT.

=cut

sub info {
    my ( $self, $msg ) = @_;

    if ( $ENV{GATEWAY_INTERFACE} ) {
        $msg =~ s/\n/<br>/g;

        delete $self->{pre};

        if ( !$self->{header} ) {
            $self->header;
            print qq| <body>|;
            $self->{header} = 1;
        }

        print "<b>$msg</b>";

    }
    else {

        if ( $ENV{info_function} ) {
            __PACKAGE__->can($ENV{info_function})->($msg);
        }
        else {
            print "$msg\n";
        }
    }
}

=item $form->numtextrows($str, $cols[, $maxrows]);

Returns the number of rows of $cols columns can be formed by $str.  If $maxrows
is set and the number of rows is greater than $maxrows, this returns $maxrows.
In the determination of rowcount, newline characters, "\n", are taken into
account while spaces are not.

=cut

sub numtextrows {

    my ( $self, $str, $cols, $maxrows ) = @_;

    my $rows = 0;

    for ( split /\n/, $str ) {
        $rows += int( ( (length) - 2 ) / $cols ) + 1;
    }

    $maxrows = $rows unless defined $maxrows;

    return ( $rows > $maxrows ) ? $maxrows : $rows;

}

=item $form->dberror($msg);

Outputs a message as in $form->error but with $DBI::errstr automatically
appended to $msg.

=cut

sub dberror {
    my ( $self, $msg ) = @_;
    $self->error( "$msg\n" . $DBI::errstr );
}

=item $form->isblank($name, $msg);

Calls $form->error($msg) if the value of $form->{$name} matches /^\s*$/.

=cut

sub isblank {
    my ( $self, $name, $msg ) = @_;
    $self->error($msg) if $self->{$name} =~ /^\s*$/;
}

=item $form->header([$init, $headeradd]);

Outputs HTML and HTTP headers and sets $form->{header} to indicate that headers
have been output.  If called with $form->{header} set or in a non-CGI
environment, does not output anything.  $init is ignored.  $headeradd is data
to be added to the <head> portion of the output headers.  $form->{stylesheet},
$form->{title}, $form->{titlebar}, and $form->{pre} all affect the output of
this function.

If the stylesheet indicated by $form->{stylesheet} exists, output a link tag
to reference it.  If $form->{title} is false, the title text is the value of
$form->{titlebar}.  If $form->{title} is true, the title text takes the form of
"$form->{title} - $form->{titlebar}".  The value of $form->{pre} is output
immediately after the closing of <head>.

=cut

sub header {

    my ( $self, $init, $headeradd ) = @_;

    return if $self->{header} or $ENV{LSMB_NOHEAD};
    my $cache = 1; # default
    if ($self->{_error}){
        $cache = 0;
    }
    elsif ($LedgerSMB::App_State::DBH){
        # we have a db connection, so are logged in.  Let's see about caching.
        local ($@); # pre-5.14, do not die() in this block
        $cache = 0 if eval { LedgerSMB::Setting->get('disable_back')};
    }

    $ENV{LSMB_NOHEAD} = 1; # Only run once.
    my ( $stylesheet, $favicon, $charset );

    my $dojo_theme = $self->{dojo_theme};
    $dojo_theme ||= $LedgerSMB::Sysconfig::dojo_theme;
    $self->{dojo_theme} = $dojo_theme; # Needed for theming of old screens
    if ( $ENV{GATEWAY_INTERFACE} ) {
        if ( $self->{stylesheet} && ( -f "css/$self->{stylesheet}" ) ) {
            $stylesheet =
qq|<link rel="stylesheet" href="$LedgerSMB::Sysconfig::cssdir| .
qq|$self->{stylesheet}" type="text/css" title="LedgerSMB stylesheet" />\n|;
        }

        $self->{charset} ||= "utf-8";
        $charset =
qq|<meta http-equiv="content-type" content="text/html; charset=$self->{charset}" />\n|;

        $self->{titlebar} =
          ( $self->{title} )
          ? "$self->{title} - $self->{titlebar}"
          : $self->{titlebar};
        if ($self->{warn_expire}){
            $headeradd .= qq|
        <script type="text/javascript" language="JavaScript">
        window.alert('Warning:  Your password will expire in $self->{pw_expires}');
    </script>|;
        }
        my $dformat = $LedgerSMB::App_State::User->{dateformat};

        print qq|Content-Type: text/html; charset=utf-8\n\n
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
        "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
    <title>$self->{titlebar}</title> |;
        if (!$cache){
            print qq|
    <meta http-equiv="Pragma" content="no-cache" />
    <meta http-equiv="Cache-Control" content="must-revalidate" />
    <meta http-equiv="Expires" content="-1" /> |;
        }
        print qq|
    <link rel="shortcut icon" href="favicon.ico" type="image/x-icon" />
    $stylesheet
    $charset
        <link rel="stylesheet" href="UI/lib/dojo/dijit/themes/$dojo_theme/$dojo_theme.css" type="text/css" title="LedgerSMB stylesheet" />
        <link rel="stylesheet" href="UI/lib/dojo/dojo/resources/dojo.css" type="text/css" title="LedgerSMB stylesheet" />
        <script type="text/javascript" language="JavaScript">
          var dojoConfig = {
               async: 1,
               parseOnLoad: 0,
               packages: [{"name":"lsmb","location":"../../.."}]
           }
           var lsmbConfig = {dateformat: '$dformat'};
        </script>
       <script type="text/javascript" language="JavaScript" src="UI/lib/dojo/dojo/dojo.js"></script>
        <script type="text/javascript" language="JavaScript" src="UI/lib/main.js"></script>
    <meta name="robots" content="noindex,nofollow" />
        $headeradd
</head>

        $self->{pre} \n|;
    }

    $self->{header} = 1;
}

=item $form->open_status_div

Returns a div tag with an id of statusdiv.

If $form->{id} is set and $form->{approved} the class is set to "posted" and if
id is set but not approved, this is set to "saved."  If neither applies, we set
to "new."

=cut

sub open_status_div {
    my ($self) = @_;
    my $class;
    if ($self->{approved} and $self->{id}){
        $class = "posted";
    } elsif ($self->{id}){
        $class = "saved";
    } else {
        $class = "new";
    }
    my $status = $LedgerSMB::App_State::Locale->text(
            'Action: [_1], ID: [_2]', $self->{action}, $self->{id}
    );
    return "<div id='statusdiv' class='$class'>
            <div id='history'>$status</div>";
}

=item $form->close_status_div

Simply returns a </div> tag.  This is included for clarity of code.

=cut

sub close_status_div { return '</div>'; }

=item $form->redirect([$msg]);

If $form->{callback} is set or $msg is not set, call the redirect function in
common.pl.  If main::redirect returns, exit.

Otherwise, output $msg as an informational message with $form->info($msg).

=cut

sub redirect {

    my ( $self, $msg ) = @_;

    if ( $self->{callback} || !$msg ) {
        $logger->trace("Full redirect \$self->{callback}=$self->{callback} \$msg=$msg");
        $self->_redirect();
        $self->finalize_request();
    }
    else {
        $self->info($msg);
    }
}

sub _redirect {
    # referenced directly from am.pl, because of the need of our return value
    use List::Util qw(first);
    my ($form) = @_;

    my ( $script, $argv ) = split( /\?/, $form->{callback} );

    my @common_attrs = qw(
      dbh login favicon stylesheet titlebar password custom_db_fields vc header
    );

    if ( !$script ) {    # http redirect to login.pl if called w/no args
        print "Location: login.pl\n";
        print "Content-type: text/html\n\n";
        return;
    }
    if (first { $_ eq $script } @{LedgerSMB::Sysconfig::newscripts}){
        print "Location: $form->{callback}\n";
        print "Content-type: text/html\n\n";
        return;
    }
    $form->error(
        $form->_locale->text(
            "[_1]:[_2]:[_3]: Invalid Redirect", __FILE__, __LINE__, $script)
    ) unless first { $_ eq $script } @{LedgerSMB::Sysconfig::scripts};

    my %temphash;
    for (@common_attrs) {
        $temphash{$_} = $form->{$_};
    }
    $temphash{action} = $form->{action};

    undef $form;
    $form = new Form($argv);

    for (@common_attrs) {
        $form->{$_} = $temphash{$_};
    }
    $form->{action} ||= $temphash{action}; # default to old action if not set

    $form->{script} = $script;

    my %myconfig = %{ LedgerSMB::User->fetch_config( $form ) };
    if ( !$form->{dbh} and ( $script ne 'admin.pl' ) ) {
        $form->db_init( \%myconfig );
    }

    require "bin/$script";

    &{ $form->{action} };

}


=item $form->sort_columns(@columns);

Sorts the list @columns.  If $form->{sort} is unset, do nothing.  If the value
of $form->{sort} does not exist in @columns, returns the list formed by the
value of $form->{sort} followed by the values of @columns.  If the value of
$form->{sort} is in @columns, return the list formed by @columns with the value
of $form->{sort} moved to the head of the list.

=cut

sub sort_columns {

    my ( $self, @columns ) = @_;

    if ( $self->{sort} ) {
        $self->{sort} =~ s/^"*(.*?)"*$/$1/;
        if (@columns) {
            @columns = grep !/^$self->{sort}$/, @columns;
            if ($self->{sort} !~ /^\w*$/){
                $self->{sort} = $self->{dbh}->quote_identifier($self->{sort});
            }
            splice @columns, 0, 0, $self->{sort};
        }
    }

    @columns;
}

=item $form->sort_order($columns[, $ordinal]);

Returns a string that contains ordering details for the columns in SQL form.
$columns is a reference to a list of columns, $ordinal is a reference to a hash
that maps column names to ordinal positions.  This function depends upon the
values of $form->{direction}, $form->{sort}, and $form->{oldsort}.

If $form->{direction} is false, it becomes 'ASC'.  If $form->{direction} is true
and $form->{sort} and $form->{oldsort} are equal, reverse the order specified by
$form->{direction}.  $form->{oldsort} is set to the same value as $form->{sort}

The actual sorting of $columns happens as in $form->sort_columns(@$columns).

If $ordinal is set, the positions given by it are substituted for the names of
columns returned.

=cut

sub sort_order {

    my ( $self, $columns, $ordinal ) = @_;

    $self = "" unless defined $self;
    $self->{sort} = "" unless defined $self->{sort};
    $self->{oldsort} = "" unless defined $self->{oldsort};
    $self->{direction} = "" unless defined $self->{direction};

    # setup direction
    if ( $self->{direction} ) {

        if ( $self->{sort} eq $self->{oldsort} ) {

            if ( $self->{direction} eq 'ASC' ) {
                $self->{direction} = "DESC";
            }
            else {
                $self->{direction} = "ASC";
            }
        }

    }
    else {

        $self->{direction} = "ASC";
    }

    $self->{oldsort} = $self->{sort};

    my @a = $self->sort_columns( @{$columns} );

    if (ref $ordinal eq 'HASH') {
        #$a[0] =
          #( $ordinal->{ $a[$_] } )
          #? "$ordinal->{$a[0]} $self->{direction}";
          #: "$a[0] $self->{direction}";

          if ( defined $_ && $ordinal->{ $a[$_] } )
          {
              $a[0] = "$ordinal->{$a[0]} $self->{direction}";
          }
          elsif ( !defined $_ && $ordinal->{ $a[0] } )
          {
              $a[0] = "$ordinal->{$a[0]} $self->{direction}";
          }
          else
          {
              $a[0] = "$a[0] $self->{direction}";
          }

        for ( 1 .. $#a ) {
            $a[$_] = $ordinal->{ $a[$_] } if $ordinal->{ $a[$_] };
        }

    }
    else {
        $a[0] .= " $self->{direction}";
    }

    my $sortorder = join ',', @a;
    $sortorder;
}

=item $form->format_amount($myconfig, $amount, $places, $dash);

Returns $amount as formatted in the form specified by $form->{numberformat}.
$places is the number of decimal places to have in the output.  $dash indicates
how to represent conditions surrounding values.

 +-------+----------+---------+------+
 | $dash | -1.00    | 1.00    | 0.00 |
 +-------+----------+---------+------+
 |   -   | (1.00)   | 1.00    |   -  |
 | DRCR  |  1.00 DR | 1.00 CR | DRCR |
 |   0   | -1.00    | 1.00    | 0.00 |
 |   x   | -1.00    | 1.00    |   x  |
 | undef | -1.00    | 1.00    |      |
 +-------+----------+---------+------+

Sample behaviour of the formatted output of various numbers for select $dash
values.

=cut

sub format_amount {

    my ( $self, $myconfig, $amount, $places, $dash ) = @_;

    $self = "" unless defined $self;
    my $negative;
    $myconfig = {} unless defined $myconfig;
    $amount = "" unless defined $amount;
    $places = "0" unless defined $places;
    $dash = "" unless defined $dash;
    $amount = $self->parse_amount($myconfig, $amount);
    if ($self->{money_precision}){
       $places= $self->{money_precision};
    }
    $myconfig->{numberformat} = '1000.00' unless $myconfig->{numberformat};
    $amount = $self->parse_amount( $myconfig, $amount )
        unless ref($amount) eq 'LedgerSMB::PGNumber';
    return $amount->to_output({
               places => $places,
                money => $self->{money_precision},
           neg_format => $dash,
               format => $myconfig->{numberformat},
    });
}

=item $form->parse_amount($myconfig, $amount);

Return a LedgerSMB::PGNumber containing the value of $amount where $amount is
formatted as $myconfig->{numberformat}.  If $amount is '' or undefined, it is
treated as zero.  DRCR and parenthesis notation is accepted in addition to
negative sign notation.

Calls $form->error if the value is NaN.

=cut

sub parse_amount {

    my ( $self, $myconfig, $amount ) = @_;
    { # pre-5.14 compatibility block
        local ($@); # pre-5.14, do not die() in this block
        return $amount if eval {$amount->isa('LedgerSMB::PGNumber') };
    }

    if ( ( ! defined $amount ) or ( $amount eq '' ) ) {
        $amount = '0';
    }

    return LedgerSMB::PGNumber->from_input($amount,
                                           {format => $myconfig->{numberformat}}
    );
}

=item $form->round_amount($amount, $places);

Rounds the provided $amount to $places decimal places.

=cut

sub round_amount {

    my ( $self, $amount, $places ) = @_;

    # These rounding rules follow from the previous implementation.
    # They should be changed to allow different rules for different accounts.
    LedgerSMB::PGNumber->round_mode('+inf') if $amount >= 0;
    LedgerSMB::PGNumber->round_mode('-inf') if $amount < 0;

    $amount = LedgerSMB::PGNumber->new($amount)->ffround( -$places ) if $places >= 0;
    $amount = LedgerSMB::PGNumber->new($amount)->ffround( -( $places - 1 ) )
      if $places < 0;

    $amount->precision(undef); #we are assuming whole cents so do not round
                               #immediately on arithmatic.  This is necessary
                               #because LedgerSMB::PGNumber is arithmatically
                               #correct wrt accuracy and precision.

    return $amount;
}

=item $form->db_parse_numeric('sth' => $sth, ['arrayref' => $arrayref, 'hashref' => $hashref])

Converts numeric values in the result set $arrayref or $hashref to
LedgerSMB::PGNumber using $sth to determine which fields are numeric.

=cut

sub db_parse_numeric {
    my $self = shift;
    my %args = @_;
    my ($sth, $arrayref, $hashref) = ($args{sth}, $args{arrayref},
          $args{hashref});
    my @types = @{$sth->{TYPE}};
    my @names = @{$sth->{NAME_lc}};
    for (0 .. $#names){
        #   numeric            float4/real
        if ($types[$_] == 3 or $types[$_] ==2) {
            $arrayref->[$_] ||= 0 if defined $arrayref;
            $hashref->{$names[$_]} ||=0 if defined $hashref;
            $arrayref->[$_] = LedgerSMB::PGNumber->new($arrayref->[$_])
              if defined $arrayref;
            $hashref->{$names[$_]} = LedgerSMB::PGNumber->new($hashref->{$names[$_]})
              if defined $hashref;
        }

    }
    return ($hashref || $arrayref);
}

=item $form->format_string(@fields);

Escape the values of $form selected by @fields for the format specified by
$form->{format}.

=cut

sub format_string {

    my ( $self, @fields ) = @_;

    my $format = $self->{format};

    if ( $self->{format} =~ /(postscript|pdf)/ ) {
        $format = 'tex';
    }

    my %replace = (
        'order' => {
            html => [ '<',  '>', '\n', '\r' ],
            txt  => [ '\n', '\r' ],
        },
        html => {
            '<'  => '&lt;',
            '>'  => '&gt;',
            '\n' => '<br />',
            '\r' => '<br />'
        },
        txt => { '\n' => "\n", '\r' => "\r" },
    );

    my $key;

    foreach $key ( @{ $replace{order}{$format} } ) {
        for (@fields) { $self->{$_} =~ s/$key/$replace{$format}{$key}/g }
    }

}

=item $form->datetonum($myconfig, $date[, $picture]);

Converts $date from the format $myconfig->{dateformat} to the format 'yyyymmdd'.
If the year extracted is only two-digits, the year given is assumed to be in the
range 2000-2099.

If $date does not contain any non-digits, datetonum does nothing.

$picture is ignored.

=cut

sub datetonum {

    my ( $self, $myconfig, $date, $picture ) = @_;

    $date = "" unless defined $date;

    if ($date =~ /^\d{4}-\d{2}-\d{2}$/){
        $date =~ s/-//g;
        return $date;
    }

    if ( $date && $date =~ /\D/ ) {

        my $yy;
        my $mm;
        my $dd;

        if ( $date =~ /^\d{4}-\d\d-\d\d$/ ) {
            ( $yy, $mm, $dd ) = split /\D/, $date;
        } if ( $myconfig->{dateformat} =~ /^yy/ ) {
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

=item $form->add_date($myconfig, $date, $repeat, $unit);

Returns the date $repeat $units from $date in the input format.  $date can
either be in $myconfig->{dateformat} or 'yyyymmdd' (four digit year required for
this option).  The valid values for $unit are 'days', 'weeks', 'months', and
'years'.

This function is unreliable for $unit values other than 'days' or 'weeks' and
can die horribly.

=cut

sub add_date {

    my ( $self, $myconfig, $date, $repeat, $unit ) = @_;

    my $diff = 0;
    my $spc  = $myconfig->{dateformat};
    my $yy;
    my $mm;
    my $dd;
    $spc =~ s/\w//g;
    $spc = substr( $spc, 0, 1 );
    if ($date) {

        if ( $date =~ /\D/ ) {

            if ( $myconfig->{dateformat} =~ /^yy/ ) {
                ( $yy, $mm, $dd ) = split /\D/, $date;
            }
            elsif ( $myconfig->{dateformat} =~ /^mm/ ) {
                ( $mm, $dd, $yy ) = split /\D/, $date;
            }
            elsif ( $myconfig->{dateformat} =~ /^dd/ ) {
                ( $dd, $mm, $yy ) = split /\D/, $date;
            }

        }
        else {

            # ISO
            ( $yy, $mm, $dd ) = ($date =~ /(....)(..)(..)/);
        }

        if ( $unit eq 'days' ) {
            $diff = $repeat * 86400;
        }
        elsif ( $unit eq 'weeks' ) {
            $diff = $repeat * 604800;
        }
        elsif ( $unit eq 'months' ) {
            $diff = $mm + $repeat;

            my $whole = int( $diff / 12 );
            $yy += $whole;

            $mm = ( $diff % 12 );
            $mm = '12' if $mm == 0;
            $yy-- if $mm == 12;
            $diff = 0;
        }
        elsif ( $unit eq 'years' ) {
            $yy += $repeat;
        }

        $mm--;

        my @t = localtime( Time::Local::timelocal( 0, 0, 0, $dd, $mm, $yy ) + $diff );

        $t[4]++;
        $mm = substr( "0$t[4]", -2 );
        $dd = substr( "0$t[3]", -2 );
        $yy = $t[5] + 1900;

        if ( $date =~ /\D/ ) {

            if ( $myconfig->{dateformat} =~ /^yy/ ) {
                $date = "$yy$spc$mm$spc$dd";
            }
            elsif ( $myconfig->{dateformat} =~ /^mm/ ) {
                $date = "$mm$spc$dd$spc$yy";
            }
            elsif ( $myconfig->{dateformat} =~ /^dd/ ) {
                $date = "$dd$spc$mm$spc$yy";
            }

        }
        else {
            $date = "$yy$mm$dd";
        }
    }

    $date;
}

=item $form->print_button($button, $name);

Outputs a submit button to STDOUT.  $button is a hashref that contains data
about buttons, $name is the key for the element in $button to output.  Each
value in $button is a reference to a hash of two elements, 'key' and 'value'.

$name is the value of the button that gets sent to the server when clicked,
$button->{$name}{key} is the accesskey, and $button->{$name}{value} is the label
for the button.

=cut

sub print_button {
    my ( $self, $button, $name ) = @_;

    print
qq|<button data-dojo-type="dijit/form/Button" class="submit" type="submit" name="action" value="$name" accesskey="$button->{$name}{key}" title="$button->{$name}{value} [Alt-$button->{$name}{key}]">$button->{$name}{value}</button>\n|;
}


=item $form->generate_selects(\%myconfig);

=cut

sub generate_selects {
     my ($form, $myconfig) = @_;


    # currencies
     if (!$form->{currencies}) {
          $form->{currencies} = $form->get_setting('curr');
     }
     if ($form->{currencies}) {
          my %curr;
          my @curr = split( /:/, $form->{currencies} );
          $form->{defaultcurrency} = $curr[0];
          foreach (@curr) {
                $curr{$_} = 1;
          }
          my @curr = keys %curr;

          $form->{currency} = $form->{defaultcurrency}
               unless $form->{currency};
          $form->{selectcurrency} = "";
          for (@curr) {
                my $selected =
                     ($form->{currency} eq $_)
                     ? " selected=\"selected\"" : "";
                $form->{selectcurrency} .=
                     "<option value=\"$_\"$selected>$_</option>\n"
          }
     }

     # partsgroups
    if ( $form->{all_partsgroup} && @{ $form->{all_partsgroup} } ) {
        $form->{selectpartsgroup} = "<option></option>\n";
          $form->{selectpartsgroup} = "";
        foreach my $ref ( @{ $form->{all_partsgroup} } ) {
                my $value = "$ref->{partsgroup}--$ref->{id}";
                my $selected = ($form->{partsgroup} eq $value) ?
                     ' selected="selected"' : "";
            if ( $ref->{translation} ) {
                $form->{selectpartsgroup} .=
                          qq|<option value="$value"$selected>$ref->{translation}</option>\n|;
            }
            else {
                $form->{selectpartsgroup} .=
                          qq|<option value="$value"$selected>$ref->{partsgroup}</option>\n|;
            }
        }
    }

     # projects
    if ( $form->{all_project} && @{ $form->{all_project} } ) {
        $form->{selectprojectnumber} = "<option></option>\n";
          $form->{selectprojectnumber} = "";
        for ( @{ $form->{all_project} } ) {
                my $value = "$_->{projectnumber}--$_->{id}";
            $form->{selectprojectnumber} .=
                     # change the format here, then change it below!
                     qq|<option value="$value">$_->{projectnumber}</option>\n|;
        }
          if ($form->{rowcount}) {
                for my $i ( 1 .. $form->{rowcount} ) {
                     $form->{"selectprojectnumber_$i"} =
                          $form->{"selectprojectnumber"};
                     $form->{"selectprojectnumber_$i"} =~
                          s/(value="\Q$form->{"projectnumber_$i"}\E")/$1 selected="selected"/;
                }
          }
    }

    # departments
    if ( $form->{all_department} && @{ $form->{all_department} } ) {
        $form->{selectdepartment} = "<option></option>\n";
        for ( @{ $form->{all_department} } ) {
                my $value = "$_->{description}--$_->{id}";
                my $selected = ($form->{department} eq $value) ?
                     ' selected="selected"' : "";
            $form->{selectdepartment} .=
                     qq|<option value="$value"$selected>$_->{description}</option>\n|;
        }
    }

     # languages
    if ( $form->{all_language} && @{ $form->{all_language} } ) {
        $form->{selectlanguage} = "<option></option>\n";
        for ( @{ $form->{all_language} } ) {
                my $value = $_->{code};
                my $selected = ($form->{language} eq $value) ?
                     ' selected="selected"' : "";
            $form->{selectlanguage} .=
              qq|<option value="$value"$selected>$_->{description}</option>\n|;
        }
    }

    # sales staff
    if ( $form->{all_employees} && @{ $form->{all_employee} } ) {
        $form->{selectemployee} = "";
        for ( @{ $form->{all_employee} } ) {
            $form->{selectemployee} .=
              qq|<option value="$_->{name}--$_->{id}">$_->{name}</option>\n|;
        }
    }

    # customers/vendors
     if ($form->{vc}) {
          if ( $form->{"all_$form->{vc}"} && @{ $form->{"all_$form->{vc}"} } ) {
                $form->{"select$form->{vc}"} = "";
                for ( @{ $form->{"all_$form->{vc}"} } ) {
                     my $value = "$_->{name}--$_->{id}";
                     my $selected = ($form->{$form->{vc}} eq $value) ?
                          ' selected="selected"' : "";
                     $form->{"select$form->{vc}"} .=
                          qq|<option value="$value"$selected>$_->{name}</option>\n|;
                }
          }
     }

     # AR/AP links
     # AR_amount_*, AP_amount_*,
     if (defined $form->{ARAP}) {
          $form->create_links( module => $form->{ARAP},
                                      myconfig => $myconfig,
                                      vc => $form->{vc},
                                      billing => $form->{vc} eq 'customer'
                                      && $form->{type} eq 'invoice')
                unless defined $form->{"$form->{ARAP}_links"};

          foreach my $key ( keys %{ $form->{"$form->{ARAP}_links"} } ) {

                $form->{"select$key"} = "";
                foreach my $ref ( @{ $form->{"$form->{ARAP}_links"}{$key} } ) {
                     my $value = "$ref->{accno}--$ref->{description}";
                     $form->{"select$key"} .=
                          # change the format here, then change it below too!
                          qq|<option value="$value">$value</option>\n|;
                }
          }

          if ($form->{rowcount}) {
                for my $i ( 1 .. $form->{rowcount} ) {
                     $form->{"select$form->{ARAP}_amount_$i"} =
                          $form->{"select$form->{ARAP}_amount"};
                     $form->{"select$form->{ARAP}_amount_$i"} =~
                          s/(value="\Q$form->{"$form->{ARAP}_amount_$i"}\E")/$1 selected="selected"/;
                }
          }
     }

     # formats
    $form->{selectformat} = qq|<option value="html">html<option value="csv">csv\n|;
    if ( ${LedgerSMB::Sysconfig::latex} ) {
        $form->{selectformat} .= qq|
            <option value="postscript">|
                . $LedgerSMB::App_State::Locale->text('Postscript')
                . qq|<option value="pdf">|
                . $LedgerSMB::App_State::Locale->text('PDF');
    }

    # warehouse
    if ( $form->{all_warehouse} &&  @{ $form->{all_warehouse} } ) {
        $form->{selectwarehouse} = "<option></option>\n";
        for ( @{ $form->{all_warehouse} } ) {
                my $value = "$_->{description}--$_->{id}";
                my $selected = ($form->{warehouse} eq $value) ?
                     ' selected="selected"' : "";
            $form->{selectwarehouse} .=
                     qq|<option value="$value"$selected>$_->{description}\n|;
        }
    }

}

=item test_should_get_images

Returns true if images should get be retrieved for embedding in templates

=cut


sub test_should_get_images {
    my ($self)  = @_;
    my $dbh = $self->{dbh};
    my $sth = $dbh->prepare(
        "SELECT value FROM defaults WHERE setting_key = 'template_images'"
    );
    $sth->execute;
    my ($retval) = $sth->fetchrow_array();
    return $retval;
}


# Database routines used throughout

=item $form->db_init($myconfig);

Connect to the database that $myconfig is set to use and initialise the base
parameters.  The connection handle becomes $form->{dbh} and
$form->{custom_db_fields} is populated.  The connection initiated has
autocommit disabled.

=cut

sub db_init {
    my ( $self, $myconfig ) = @_;
    $logger->trace("begin");
    if (!$self->{company}){
        $self->{company} = $LedgerSMB::Sysconfig::default_db;
    }
    my $dbname = $self->{company};
    $self->{dbh} = LedgerSMB::App_State::DBH;
    $self->{dbh} ||= LedgerSMB::DBH->connect($self->{company});
    LedgerSMB::Auth::credential_prompt unless $self->{dbh};
    my $dbh = $self->{dbh};

    if ($ENV{GATEWAY_INTERFACE} and !$ENV{LSMB_NOHEAD}) {
        if (! LedgerSMB::Session::check( $self->{cookie}, $self)) {
            LedgerSMB::Auth::credential_prompt;
        }
    }

    LedgerSMB::App_State::set_DBH($dbh);
    LedgerSMB::DBH->set_datestyle;


    $self->{db_dateformat} = $myconfig->{dateformat};    #shim

    LedgerSMB::DBH->require_version($self->{version}) if $self->{version};

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
    # Roles tracking
    $self->{_roles} = [];
    $query = "select rolname from pg_roles
               where pg_has_role(rolname, 'USAGE')
                     and rolname like
                          coalesce((select value from defaults
                                     where setting_key = 'role_prefix'),
                                   'lsmb_' || current_database() || '__') || '%'";
    $sth = $dbh->prepare($query);
    $sth->execute();
    while (my @roles = $sth->fetchrow_array){
        push @{$self->{_roles}}, $roles[0];
    }

    $sth = $self->{dbh}->prepare("
            SELECT value FROM defaults
             WHERE setting_key = 'role_prefix'");
    $sth->execute;

    ($self->{_role_prefix}) = $sth->fetchrow_array;
    $LedgerSMB::App_State::Roles = @{$self->{_roles}};
    $LedgerSMB::App_State::Role_Prefix = $self->{_role_prefix};
    $LedgerSMB::App_State::DBName = $dbname;
    # Expect @{$self->{_roles}} to go away sometime during 1.4/1.5 development
    # -CT

    $sth = $self->{dbh}->prepare("
            SELECT value FROM defaults
             WHERE setting_key = 'dojo_theme'");
    $sth->execute;

    ($self->{dojo_theme}) = $sth->fetchrow_array;
    $LedgerSMB::App_State::dojo_theme = $self->{dojo_theme};
    $sth = $dbh->prepare('SELECT check_expiration()');
    $sth->execute;
    ($self->{warn_expire}) = $sth->fetchrow_array;
    if ($self->{warn_expire}){
        $sth = $dbh->prepare('SELECT user__check_my_expiration()');
        $sth->execute;
        ($self->{pw_expires})  = $sth->fetchrow_array;
    }
    $sth->finish();
    $LedgerSMB::App_State::DBH = $self->{dbh};
    LedgerSMB::Company_Config::initialize($self);
    $logger->trace("end");
}

=item $form->run_custom_queries($tablename, $query_type[, $linenum]);

Runs queries against custom fields for the specified $query_type against
$tablename.

Valid values for $query_type are any casing of 'SELECT', 'INSERT', and 'UPDATE'.

=cut

sub run_custom_queries {
    my ( $self, $tablename, $query_type, $linenum ) = @_;
    return unless exists $self->{custom_db_fields}
           and ref $self->{custom_db_fields}
           and exists $self->{custom_db_fields}->{$tablename};
    my $dbh = $self->{dbh};
    if ( $query_type !~ /^(select|insert|update)$/i ) {
        $self->error(
                "Passed incorrect query type to run_custom_queries."
        );
    }
    my @rc;
    my %temphash;
    my @templist;
    my @elements;
    my $query;
    my $did_insert;
    my $ins_values;
    my $sth;
    if ($linenum) {
        $linenum = "_$linenum";
    }

    $query_type = uc($query_type);
    for ( @{ $self->{custom_db_fields}->{$tablename} } ) {
        @elements = split( /:/, $_ );
        push @{ $temphash{ $elements[0] } }, $elements[1];
    }
    for ( keys %temphash ) {
        my @data;
        my $ins_values;
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
            $sth   = $dbh->prepare($query)
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
            my $query = shift @{$_};
            my $sth   = $self->{dbh}->prepare($query);
            $sth->execute( $self->{id} );
            my $ref = $sth->fetchrow_hashref('NAME_lc');
            for ( keys %{$ref} ) {
                $self->{$_} = $ref->{$_};
            }
        }
    }
    @rc;
}

=item $form->dbquote($var);

If $var is an empty string, return NULL, otherwise return $var as quoted by
$form->{dbh}->quote($var).

=cut

sub dbquote {

    my ( $self, $var ) = @_;

    if ( $var eq '' ) {
        $_ = "NULL";
    }
    else {
        $_ = $self->{dbh}->quote($var);
    }
    $_;
}

=item $form->update_balance($dbh, $table, $field, $where, $value);

B<WARNING>: This is a dangerous private function.  All apps calling it must be
careful to avoid SQL injection issues.

If $value is set, sets the value of $field in $table to the sum of the current
stored value and $value.  In order to not annihilate the values in $table,
$where must contain a WHERE clause that limits the UPDATE to a single row.

=cut

sub update_balance {

    # This is a dangerous private function.  All apps calling it must
    # be careful to avoid SQL injection issues

    my ( $self, $dbh, $table, $field, $where, $value ) = @_;


    $table = $dbh->quote_identifier($table);
    $field = $dbh->quote_identifier($field);
    # if we have a value, go do it
    if ($value) {

        # retrieve balance from table
        my $query = "SELECT $field FROM $table WHERE $where FOR UPDATE";
        my ($balance) = $dbh->selectrow_array($query);

        $balance = $dbh->quote($balance + $value);

        # update balance
        $query = "UPDATE $table SET $field = $balance WHERE $where";
        $dbh->do($query) || $self->dberror($query);
    }
}

=item $form->update_exchangerate($dbh, $curr, $transdate, $buy, $sell);

Updates the exchange rates $buy and $sell for the given $currency on $transdate.
If there is not yet an exchange rate for $currency on $transdate, an entry is
inserted.  This returns without doing anything if $curr eq ''.

$dbh is not used, favouring $self->{dbh}.

=cut

sub update_exchangerate {

    my ( $self, $dbh, $curr, $transdate, $buy, $sell ) = @_;

    # some sanity check for currency
    return if ( $curr eq "" );

    my $query = qq|
        SELECT curr
        FROM exchangerate
        WHERE curr = ?
        AND transdate = ?
        FOR UPDATE|;

    my $sth = $self->{dbh}->prepare($query);
    $sth->execute( $curr, $transdate ) || $self->dberror($query);

    my $set;
    my @queryargs;

    if ( $buy && $sell ) {
        $set = "buy = ?, sell = ?";
        @queryargs = ( $buy, $sell );
    }
    elsif ($buy) {
        $set       = "buy = ?";
        @queryargs = ($buy);
    }
    elsif ($sell) {
        $set       = "sell = ?";
        @queryargs = ($sell);
    }

    if ( !$set ) {
        $self->error("Exchange rate missing!");
    }
    if ( $sth->fetchrow_array ) {
        $query = qq|UPDATE exchangerate
                       SET $set
                     WHERE curr = ?
                       AND transdate = ?|;
        push( @queryargs, $curr, $transdate );

    }
    else {
        $query = qq|
            INSERT INTO exchangerate (
            curr, buy, sell, transdate)
            VALUES (?, ?, ?, ?)|;
        @queryargs = ( $curr, $buy, $sell, $transdate );
    }
    $sth->finish;
    $sth = $self->{dbh}->prepare($query);

    $sth->execute(@queryargs) || $self->dberror($query);

}

=item $form->save_exchangerate($myconfig, $currency, $transdate, $rate, $fld);

Saves the exchange rate $rate for the given $currency on $transdate for the
provided purpose in $fld.  $fld can be either 'buy' or 'sell'.

$myconfig is not used.  $self->update_exchangerate is used for the majority of
the work.

=cut

sub save_exchangerate {

    my ( $self, $myconfig, $currency, $transdate, $rate, $fld ) = @_;

    my ( $buy, $sell ) = ( 0, 0 );
    $buy  = $rate if $fld eq 'buy';
    $sell = $rate if $fld eq 'sell';

    $self->update_exchangerate( $self->{dbh}, $currency, $transdate, $buy,
        $sell );

}

=item $form->get_exchangerate($dbh, $curr, $transdate, $fld);

Returns the exchange rate in relation to the default currency for $currency on
$transdate for the purpose indicated by $fld.  $fld can be either 'buy' or
'sell' to get usable results.

$dbh is not used, favouring $self->{dbh}.

=cut

sub get_exchangerate {

    my ( $self, $dbh, $curr, $transdate, $fld ) = @_;

    my $exchangerate = 1;

    if ($transdate) {
        my $query = qq|
            SELECT $fld FROM exchangerate
            WHERE curr = ? AND transdate = ?|;
        my $sth = $self->{dbh}->prepare($query);
        $sth->execute( $curr, $transdate );

        ($exchangerate) = $sth->fetchrow_array;
    $exchangerate = LedgerSMB::PGNumber->new($exchangerate);
        $sth->finish;
    }

    $exchangerate;
}

=item $form->check_exchangerate($myconfig, $currency, $transdate, $fld);

Returns some true value when an entry for $currency on $transdate is true for
the purpose indicated by $fld.  $fld can be either 'buy' or 'sell' to get
usable results.  Returns false if $transdate is not set.

$myconfig is not used.

=cut

sub check_exchangerate {

    my ( $self, $myconfig, $currency, $transdate, $fld ) = @_;

    return "" unless $transdate;

    my $query = qq|
        SELECT $fld
        FROM exchangerate
        WHERE curr = ? AND transdate = ?|;

    my $sth = $self->{dbh}->prepare($query);
    $sth->execute( $currency, $transdate );
    my @array = $sth->fetchrow_array;
    $self->db_parse_numeric(sth => $sth, arrayref => \@array);
    my ($exchangerate) = @array;

    $sth->finish;

    $exchangerate;
}

=item $form->add_shipto($dbh, $id);

Inserts a new address into the table shipto if the value of any of the shipto
address components in $form differs to the regular attribute in $form.  The
inserted value of trans_id is $id, the other fields correspond with the shipto
address components of $form.

$dbh is unused.

=cut

sub add_shipto {

      my ( $self,$dbh,$id, $oe) = @_;
        if (! $self->{locationid}) {
        return;
    }
    my $query = qq|
            INSERT INTO new_shipto
            (trans_id, oe_id,location_id)
            VALUES ( ?, ?, ?)
            |;

        my $sth = $self->{dbh}->prepare($query) || $self->dberror($query);
        my $trans_id;
        my $oe_id;
        if ($oe){
           $trans_id = undef;
           $oe_id = $id;
        } else {
           $trans_id = $id;
           $oe_id = undef;
        }
        $sth->execute(
                        $trans_id,
            $oe_id,
            $self->{locationid}

              ) || $self->dberror($query);

    $sth->finish;



}

=item $form->get_shipto ($location_id)

Returns the shipto record of the corresponding location, and attaches the info
as expected for the templates

=cut

sub get_shipto {
    my ($self, $location_id) = @_;
    my $query = qq| select line_one, line_two, city, state, mail_code,
                           c.name as country
                      from location l
                      join country c on c.id = l.country_id
                     where l.id = ? |;
    my $sth = $self->{dbh}->prepare($query);
    $sth->execute($location_id);
    my $ref = $sth->fetchrow_hashref('NAME_lc');
    $self->{shiptoaddress1} = $ref->{line_one};
    $self->{shiptoaddress2} = $ref->{line_two};
    $self->{shiptocity} = $ref->{city};
    $self->{shiptostate} = $ref->{state};
    $self->{shiptozipcode} = $ref->{mail_code};
    $self->{shiptocountry} = $ref->{country};
    return $ref;
}


=item $form->get_employee($dbh);

Returns a list containing the name and id of the employee $form->{login}.  Any
portion of $form->{login} including and past '@' are ignored.

$dbh is unused.

=cut

sub get_employee {
    my ( $self, $dbh ) = @_;

    my $login = $self->{login};
    $login =~ s/@.*//;

    my $query = qq|
        SELECT name, id
          FROM entity WHERE id IN (select entity_id
                     FROM users
                    WHERE username = ?)|;

    my $sth = $self->{dbh}->prepare($query);
    $sth->execute($login);
    my (@a) = $sth->fetchrow_array();

    $sth->finish;

    @a;
}

=item $form->get_name($myconfig, $table[, $transdate])

Sets $form->{name_list} to refer to a list of customers or vendors whose names
or numbers match the value found in $form->{$table} and returns the number of
matches.  $table can be 'vendor', 'customer', or 'employee'; if the optional
field $transdate is provided, the result set is further limited to $table
entries which were active on the provided date as determined by the start and
end dates.  The elements of $form->{name_list} are references returned rows in
hashref form and are sorted by the name field.  The fields of the hash are those
of the view $table and the table entity.

$myconfig is unused.

=cut

# this sub gets the id and name from $table
sub get_name {

    my ( $self, $myconfig, $table, $transdate, $entity_class) = @_;

    if (!$entity_class){
       if ($table eq 'customer'){
           $entity_class = 2;
       } elsif ($table eq 'vendor') {
           $entity_class = 1;
       }
    }

    my @queryargs;
    my $where;
    if ($transdate) {
        $where = qq|
            AND (c.startdate IS NULL OR c.startdate <= ?)
                    AND (c.enddate IS NULL OR c.enddate >= ?)|;

        @queryargs = ( $transdate, $transdate );
    }

    # SC: Check for valid table/view name.  Other values will cause SQL errors.
    if ($table !~ /^(vendor|customer|employee)$/i) {
        $self->error('Invalid name source');
    }
    # Company name is stored in $self->{vendor} or $self->{customer}
    if ($self->{"${table}number"} eq ''){
        $self->{"${table}number"} = $self->{$table};
    }

    my $name = $self->like( lc $self->{$table} ) if $self->{$table};

    $self->{"${table}number"}=$self->like(lc $self->{"${table}number"}) if $self->{"${table}number"};#added % and % for searching key vendor/customer number.

    # Vendor and Customer are now views into entity_credit_account.
    my $query = qq/
        SELECT c.*, coalesce(ecl.address, el.address) as address,
                       coalesce(ecl.city, el.city) as city,
                       e.name, e.control_code,
                       ctf.default_reportable
                  FROM entity_credit_account c
          JOIN entity e ON (c.entity_id = e.id)
             LEFT JOIN (SELECT coalesce(line_one, '')
                               || ' ' || coalesce(line_two, '') as address,
                               l.city, etl.credit_id
                          FROM eca_to_location etl
                          JOIN location l ON etl.location_id = l.id
                          WHERE etl.location_class = 1) ecl
                        ON (c.id = ecl.credit_id)
             LEFT JOIN (SELECT coalesce(line_one, '')
                               || ' ' || coalesce(line_two, '') as address,
                               l.city, etl.entity_id
                          FROM entity_to_location etl
                          JOIN location l ON etl.location_id = l.id
                          WHERE etl.location_class = 1) el
                        ON (c.entity_id = el.entity_id)
             LEFT JOIN country_tax_form ctf ON (c.taxform_id = ctf.id)
         WHERE (lower(e.name) LIKE ?
               OR c.meta_number ILIKE ?
                       or e.name @@ plainto_tsquery(?))
                       AND coalesce(?, c.entity_class) = c.entity_class
        $where
        ORDER BY e.name/;

    unshift( @queryargs, $name, $self->{"${table}number"} ,
                         $self->{$table}, $entity_class);
    my $sth = $self->{dbh}->prepare($query);
    $sth->execute(@queryargs) || $self->dberror($query);

    my $i = 0;
    @{ $self->{name_list} } = ();
    while ( my $ref = $sth->fetchrow_hashref('NAME_lc') ) {
        push( @{ $self->{name_list} }, $ref );
        $i++;
    }
    $sth->finish;

    return $i;
}

=item $form->all_vc($myconfig, $vc, $module, $dbh, $transdate, $job);

Populates the list referred to by $form->{all_${vc}} with hashes of either
vendor or customer id and name, ordered by the name.  This will be vendor
details unless $vc is set to 'customer'.  This list can be limited to only
vendors or customers which are usable on a given day by specifying $transdate.
As a further restriction, $form->{all_${vc}} will not be populated if the
number of vendors or customers that would be present in that list exceeds, or
is equal to, $myconfig->{vclimit}.

In addition to the possible population of $form->{all_${vc}},
$form->{employee_id} is looked up if not already set, the list
$form->{all_language} is populated using the language table and is sorted by the
description, and $form->all_employees, $form->all_departments,
$form->all_business_units, and $form->all_taxaccounts are all run.

$module and $dbh are unused.

=cut

sub all_vc {

    my ( $self, $myconfig, $vc, $module, $dbh, $transdate, $job ) = @_;
    my $ref;
    my $table;

    if ($module eq 'AR'){
        $table = 'ar';
    } elsif ($module eq 'AP'){
        $table = 'ap';
    }

    $dbh = $self->{dbh};

    my $sth;
    $sth = $dbh->prepare('SELECT value FROM defaults WHERE setting_key = ?');

    $sth->execute('vclimit');
    ($myconfig->{vclimit}) = $sth->fetchrow_array();

    if ($vc eq 'customer'){
        $self->{vc_class} = 2;
    } else {
        $self->{vc_class} = 1;
        $vc = 'vendor';
    }
    my $query = qq|SELECT count(*) FROM entity_credit_account ec
        where ec.entity_class = ?|;
    my $where;
    my @queryargs2 = ($self->{vc_class});
    my @queryargs;
    if ($transdate) {
        $query .= qq| AND (ec.startdate IS NULL OR ec.startdate <= ?)
                AND (ec.enddate IS NULL OR ec.enddate >= ?)|;
        $where = qq| (ec.startdate IS NULL OR ec.startdate <= ?)
            AND (ec.enddate IS NULL OR ec.enddate >= ?)
            AND ec.entity_class = ?|;
        push (@queryargs, $transdate, $transdate, $self->{vc_class});
        push (@queryargs2, $transdate, $transdate);
    } else {
        $where = " true";
    }

    $sth = $dbh->prepare($query);

    $sth->execute(@queryargs2);

    my ($count) = $sth->fetchrow_array;

    $sth->finish;

    if ($self->{id}) {
    ### fixme: the segment below assumes that the form ID is a
    # credit account id, which it isn't necessarily (maybe never?)
    # when called from bin/oe.pl, it's an order id.
        $query = qq|
        SELECT ec.id, e.name
          FROM entity e
          JOIN entity_credit_account ec ON (ec.entity_id = e.id)
         WHERE ec.id = (select entity_credit_account FROM $table
                WHERE id = ?)
        ORDER BY name|;
        $sth = $self->{dbh}->prepare($query);
        $sth->execute($self->{id});
        ($self->{"${vc}_id"}, $self->{$vc}) = $sth->fetchrow_array();
    }

    if ( $count < $myconfig->{vclimit} ) {

        $self->{"${vc}_id"} *= 1;

        $query = qq|SELECT ec.id, e.name
                      FROM entity e
                      JOIN entity_credit_account ec ON ec.entity_id = e.id
                     WHERE
                           $where
                     UNION
                    SELECT ec.id, e.name
                      FROM entity e
                      JOIN entity_credit_account ec ON ec.entity_id = e.id
                     WHERE ec.id = ?
                  ORDER BY name|;

        push( @queryargs, $self->{"${vc}_id"} );

        $sth = $dbh->prepare($query);
        $sth->execute(@queryargs) || $self->dberror($query);

        @{ $self->{"all_$vc"} } = ();

        while ( $ref = $sth->fetchrow_hashref('NAME_lc') ) {
            push @{ $self->{"all_$vc"} }, $ref;
        }

        $sth->finish;

    }

    # get self
    if ( !$self->{employee_id} ) {
        ( $self->{employee}, $self->{employee_id} ) = split /--/,
          $self->{employee};
        ( $self->{employee}, $self->{employee_id} ) = $self->get_employee($dbh)
          unless $self->{employee_id};
    }

    $self->get_regular_metadata($myconfig,$vc, $module, $dbh, $transdate, $job);
}

=item $form->get_regular_metadata($myconfig, $vc, $module, $dbh, $transdate,
                                 $job)

This is API-compatible with all_vc.  It is a handy wrapper function that calls
the following functions:
all_employees
all_departments
all_business_units
all_taxaccounts

It is preferable to using all_vc where the latter does not work properly due to
variable collisions, etc.

$form->{employee_id} is looked up if not already set, the list
$form->{all_language} is populated using the language table and is sorted by the
description, and $form->all_employees, $form->all_departments,
$form->all_business_units, and $form->all_taxaccounts are all run.

$module and $dbh are unused.

=cut

sub get_regular_metadata {
    my ( $self, $myconfig, $vc, $module, $dbh, $transdate, $job ) = @_;
    $dbh = $self->{dbh};
    { # pre-5.14 compatibility block
        local ($@); # pre-5.14, do not die() in this block
        $transdate = $transdate->to_db if eval { $transdate->can('to_db') };
    }

    $self->all_employees( $myconfig, $dbh, $transdate, 1 );
    $self->all_business_units( $myconfig, $dbh, $transdate, $job );
    $self->all_taxaccounts( $myconfig, $dbh, $transdate );
    $self->all_languages();
}

=item $form->all_accounts()

Sets $form->{accounts} to all accounts.  Returns the list as well.
Example:  my @account_list = $form->all_accounts();

=cut

sub all_accounts {
    my ($self) = @_;
    my $ref;
    $self->{all_accounts} = [];
    my $sth = $self->{dbh}->prepare('SELECT * FROM chart_list_all()');
    $sth->execute || $self->dberror('SELECT * FROM chart_list_all()');
    while ($ref = $sth->fetchrow_hashref('NAME_lc')){
        push(@{$self->{all_accounts}}, $ref);
    }
    $sth->finish;
    return @{$self->{all_accounts}};
}

=item $form->all_taxaccounts($myconfig, $dbh2[, $transdate]);

Get the tax rates and numbers for all the taxes in $form->{taxaccounts}.  Does
nothing if $form->{taxaccounts} is false.  Taxes are listed as a space separated
list of account numbers from the chart.  The retrieved values are placed within
$form->{${accno}_rate} and $form->{${accno}_taxnumber}.  If $transdate is set,
then only process taxes that were valid on $transdate.

$myconfig and $dbh2 are unused.

=cut

sub all_taxaccounts {

    my ( $self, $myconfig, $dbh2, $transdate ) = @_;

    my $dbh = $self->{dbh};

    my $sth;
    my $query;
    my $where;

    my @queryargs = ();

    if ($transdate) {
        $where = qq| AND (t.validto >= ? OR t.validto IS NULL)|;
        push( @queryargs, $transdate );
    }

    if ( $self->{taxaccounts} ) {

        # rebuild tax rates
        $query = qq|SELECT t.rate, t.taxnumber
                      FROM tax t
                      JOIN chart c ON (c.id = t.chart_id)
                     WHERE c.accno = ?
                    $where
                  ORDER BY accno, validto|;

        $sth = $dbh->prepare($query) || $self->dberror($query);

        foreach my $accno ( split / /, $self->{taxaccounts} ) {
            $sth->execute( $accno, @queryargs );
            ( $self->{"${accno}_rate"}, $self->{"${accno}_taxnumber"} ) =
              $sth->fetchrow_array;
            $sth->finish;
        }
    }
}

=item $form->all_employees($myconfig, $dbh2, $transdate, $sales);

Sets $form->{all_employee} to be a reference to an array referencing hashes of
employee information.  The hashes are of the form {'id' => id, 'name' => name}.
If $transdate is set, the query is limited to employees who are active on that
day.  If $sales is true, only employees with the sales flag set are added.

$dbh2 is unused.

=cut

sub all_employees {

    my ( $self, $myconfig, $dbh2, $transdate, $sales ) = @_;

    my $dbh       = $self->{dbh};
    my @whereargs = ();

    # setup employees/sales contacts
    my $query = qq|
        SELECT id, name
        FROM entity
        WHERE id IN (SELECT entity_id FROM entity_employee
                    WHERE|;

    if ($transdate) {
        $query .= qq| (startdate IS NULL OR startdate <= ?)
        AND (enddate IS NULL OR enddate >= ?) AND|;
        @whereargs = ( $transdate, $transdate );
    }
    else {
        $query .= qq| enddate IS NULL AND|;
    }

    if ($sales) {
        $query .= qq| sales = '1' AND|;
    }

    $query =~ s/(WHERE|AND)$//;
    $query .= qq|) ORDER BY name|;
    my $sth = $dbh->prepare($query);
    $sth->execute(@whereargs) || $self->dberror($query);

    while ( my $ref = $sth->fetchrow_hashref('NAME_lc') ) {
        push @{ $self->{all_employee} }, $ref;
    }

    $sth->finish;
}

=item $form->all_business_units([$transdate, $credit_id]);

Returns a list at bu_class with class information, ordered by order information
and a list of units in lists at bu_units->$class_id.  $transdate is used to
filter projects active at specified date.  $credit_id is to filter out
units assigned to other customers.

=cut

sub all_business_units {

    my ( $self, $transdate, $credit_id, $module_name) = @_;
    $self->{bu_class} = [];
    $self->{b_units} = {};

    my $dbh       = $self->{dbh};
    my $class_sth = $dbh->prepare(
                q|SELECT * FROM business_unit__list_classes('1', ?)|
    );
    $class_sth->execute($module_name);

    my $bu_sth    = $dbh->prepare(
                q|SELECT *
                    FROM business_unit__list_by_class(?, ?, ?, 'false')|
    );

    while (my $classref = $class_sth->fetchrow_hashref('NAME_lc')){
        push @{$self->{bu_class}}, $classref;
        $bu_sth->execute($classref->{id}, $transdate, $credit_id);
        $self->{b_units}->{$classref->{id}} = [];
        while (my $buref = $bu_sth->fetchrow_hashref('NAME_lc')){
           push @{$self->{b_units}->{$classref->{id}}}, $buref;
        }
    }
    $class_sth->finish;
    $bu_sth->finish;

}

=item $form->all_languages($myconfig);

Set $form->{all_language} to be a reference to a list of hashrefs describing
languages using the form {'code' => code, 'description' => description}.

=cut

sub all_languages {

    my ( $self ) = @_;

    my $dbh = $self->{dbh};

    my $query = qq|
        SELECT code, description
        FROM language
    ORDER BY description|;

    my $sth = $dbh->prepare($query);
    $sth->execute || $self->dberror($query);

    $self->{all_language} = [];

    while ( my $ref = $sth->fetchrow_hashref('NAME_lc') ) {
        push @{ $self->{all_language} }, $ref;
    }

    $sth->finish;
}

=item $form->all_years($myconfig[, $dbh2]);

Populates the hash $form->{all_month} with a mapping between a two-digit month
number and the English month name.  Populates the list $form->{all_years} with
all years which contain transactions.

$dbh2 is unused.

=cut

sub all_years {

    my ( $self, $myconfig ) = @_;

    my $dbh = $self->{dbh};
    $self->{all_years} = [];

    # get years
    my $query = qq|
        SELECT * FROM date_get_all_years()|;

    my $sth = $dbh->prepare($query);
    $sth->execute();
    while (my ($year) = $sth->fetchrow_array()){
      push @{$self->{all_years}}, $year;
    }

    #this should probably be changed to use locale
    %{ $self->{all_month} } = (
        '01' => 'January',
        '02' => 'February',
        '03' => 'March',
        '04' => 'April',
        '05' => 'May ',
        '06' => 'June',
        '07' => 'July',
        '08' => 'August',
        '09' => 'September',
        '10' => 'October',
        '11' => 'November',
        '12' => 'December'
    );

}

=item $form->create_links( { module => $module,
    myconfig => $myconfig, vc => $vc, billing => $billing [, job => $job ] });

Populates the hash referred to as $form->{${module}_links} details about
accounts that have $module in their link field.  The hash is keyed upon link
elements such as 'AP_amount' and 'AR_tax' and they refer to lists of hashes
containing accno and description for the appropriate accounts.  If the key does
not contain 'tax', the account number is appended to the space separated list
$form->{accounts}.  $module is typically 'AR' or 'AP' and is the base type of
the accounts looked up.

If $form->{id} is not set, check $form->{"$form->{vc}_id"}.  If neither is set,
use $form->lastname_used to populate the details.  If $form->{id} is set,
populate the invnumber, transdate, ${vc}_id, datepaid, duedate, ordnumber,
taxincluded, currency, notes, intnotes, ${vc}, department_id, department,
oldinvtotal, oldtotalpaid, employee_id, employee, language_code, ponumber,
reverse, printed, emailed, queued, recurring, exchangerate, and acc_trans
attributes of $form with details about the transaction $form->{id}.  All of
these attributes, save for acc_trans, are scalar; $form->{acc_trans} refers to
a hash keyed by link elements whose values are lists of references to hashes
describing acc_trans table entries corresponding to the transaction $form->{id}.
The elements in the acc_trans entry hashes are accno, description, source,
amount, memo, transdate, cleared, project_id, projectnumber, and exchangerate.

The closedto, separate_duties, revtrans, and currencies $form attributes are filled with values
from the defaults table, while $form->{current_date} is populated with the
current date.  If $form->{id} is not set, then $form->{transdate} also takes on
the current date.

When $billing is provided and true, the email addresses are selected
from the billing contact classes, when available, falling back to the
normal email classes when not.

After all this, it calls $form->all_vc to conclude.

=cut

sub create_links {

    my $self = shift;
    my %args = @_;
    my $module = $args{module};
    my $myconfig = $args{myconfig};
    my $billing = $args{billing};
    my $vc = $args{vc};
    my $job = $args{job};

    # get last customers or vendors
    my ( $query, $sth );

    if (!$self->{dbh}) {
        $self->db_init($myconfig);
    }

    my $dbh = $self->{dbh};

    my %xkeyref = ();

    my $val;
    my $ref;
    my $key;
    my %tax_accounts;

    $sth = $dbh->prepare("SELECT accno FROM account WHERE tax");
    $sth->execute();
    while ( my $ref = $sth->fetchrow_hashref('NAME_lc') ) {
        $tax_accounts{$ref->{accno}} = 1;
    }

    # now get the account numbers
    $query = qq|SELECT a.accno, a.description, a.link
                  FROM chart a
                  JOIN account ON a.id = account.id AND NOT account.obsolete
                 WHERE (link LIKE ?) OR account.tax
                       AND (a.id in (select acc_trans.chart_id
                                       FROM acc_trans
                                      WHERE trans_id = coalesce(?, -1))
                           OR NOT account.obsolete)
              ORDER BY accno|;

    $sth = $dbh->prepare($query);
    $self->{id} = undef if $self->{id} eq '';
    $sth->execute( "%" . "$module%", $self->{id}) || $self->dberror($query);

    $self->{accounts} = "";

    while ( my $ref = $sth->fetchrow_hashref('NAME_lc') ) {
        my $link = $ref->{link};

        $link .= ($link ? ":" : "") . "${module}_tax"
            if $tax_accounts{$ref->{accno}};

        foreach my $key ( split /:/, $link ) {

            if ( $key =~ /$module/ ) {

                # cross reference for keys
                $xkeyref{ $ref->{accno} } = $key;

                push @{ $self->{"${module}_links"}{$key} },
                  {
                    accno       => $ref->{accno},
                    description => $ref->{description}
                  };

                $self->{accounts} .= "$ref->{accno} "
                  unless $key =~ /tax/;
            }
        }
    }

    $sth->finish;

    my $arap = ( $vc eq 'customer' ) ? 'ar' : 'ap';
    $vc = 'vendor' unless $vc eq 'customer';
    my $seq = ( $vc eq 'customer' ) ? 'a.setting_sequence'
                                    : 'NULL as setting_sequence';

    if ( $self->{id} ) {

        $query = qq|
            SELECT a.invnumber, a.transdate,
                a.entity_credit_account AS entity_id,
                a.datepaid, a.duedate, a.ordnumber,
                a.taxincluded, a.curr AS currency, a.notes,
                a.intnotes, ce.name AS $vc,
                a.amount AS oldinvtotal, a.paid AS oldtotalpaid,
                a.person_id, e.name AS employee,
                c.language_code, a.ponumber, a.reverse,
                                a.approved, ctf.default_reportable,
                                a.description, a.on_hold, a.crdate,
                                ns.location_id as locationid, a.is_return, $seq
            FROM $arap a
            JOIN entity_credit_account c
                ON (a.entity_credit_account = c.id)
            JOIN entity ce ON (ce.id = c.entity_id)
            LEFT JOIN entity_employee er
                                   ON (er.entity_id = a.person_id)
            LEFT JOIN entity e ON (er.entity_id = e.id)
                        LEFT JOIN country_tax_form ctf
                                  ON (ctf.id = c.taxform_id)
                        LEFT JOIN new_shipto ns on a.id = ns.trans_id
            WHERE a.id = ? AND c.entity_class =
                (select id FROM entity_class
                WHERE class ilike ?)|;

        $sth = $dbh->prepare($query);
        $sth->execute( $self->{id}, $self->{vc} ) || $self->dberror($query);

        $ref = $sth->fetchrow_hashref('NAME_lc');
        $self->db_parse_numeric(sth=>$sth, hashref=>$ref);

        if (!defined $ref->{approved}){
           $ref->{approved} = 0;
        }

        foreach $key ( keys %$ref ) {
            $self->{$key} = $ref->{$key};
        }

        $sth->finish;

        # get printed, emailed
        $query = qq|
            SELECT s.printed, s.emailed, s.spoolfile, s.formname
            FROM status s WHERE s.trans_id = ?|;
        $sth = $dbh->prepare($query);
        $sth->execute( $self->{id} ) || $self->dberror($query);
        while ( $ref = $sth->fetchrow_hashref('NAME_lc') ) {
            $self->{printed} .= "$ref->{formname} "
              if $ref->{printed};
            $self->{emailed} .= "$ref->{formname} "
              if $ref->{emailed};
            $self->{queued} .= "$ref->{formname} " . "$ref->{spoolfile} "
              if $ref->{spoolfile};
        }
        $sth->finish;
        for (qw(printed emailed queued)) { $self->{$_} =~ s/ +$//g }

    # get customer e-mail accounts
    $query = qq|SELECT * FROM eca__list_contacts(?)
                      WHERE class_id BETWEEN 12 AND ?
                      ORDER BY class_id DESC;|;
    my %id_map = ( 12 => 'email',
               13 => 'cc',
               14 => 'bcc',
               15 => 'email',
               16 => 'cc',
               17 => 'bcc' );
    $sth = $dbh->prepare($query);
    $sth->execute( $self->{entity_id},
                   $billing ? 17 : 14) || $self->dberror( $query );

    my $ctype;
    my $billing_email = 0;
    while ( $ref = $sth->fetchrow_hashref('NAME_lc') ) {
        $ctype = $ref->{class_id};
        $ctype = $id_map{$ctype};
        $billing_email = 1
        if $ref->{class_id} == 15;

        # If there's an explicit billing email, don't use
        # the standard email addresses; otherwise fall back to standard
        $self->{$ctype} .= ($self->{$ctype} ? ", " : "") . $ref->{contact}
        if (($ref->{class_id} < 15 && ! $billing_email)
            || $ref->{class_id} >= 15);
    }
    $sth->finish;

        # get recurring
        $self->get_recurring($dbh);

        # get amounts from individual entries
        $query = qq|
            SELECT c.accno, c.description, a.source, a.amount,
                a.memo,a.entry_id, a.transdate, a.cleared,
                                compound_array(ARRAY[ARRAY[bul.class_id, bul.bu_id]])
                                AS bu_lines
            FROM acc_trans a
            JOIN chart c ON (c.id = a.chart_id)
                   LEFT JOIN business_unit_ac bul ON a.entry_id = bul.entry_id
            WHERE a.trans_id = ?
                AND a.fx_transaction = '0'
                        GROUP BY c.accno, c.description, a.source, a.amount,
                                a.memo,a.entry_id, a.transdate, a.cleared
            ORDER BY transdate|;

        $sth = $dbh->prepare($query);
        $sth->execute( $self->{id} ) || $self->dberror($query);

        my $fld = ( $vc eq 'customer' ) ? 'buy' : 'sell';

        $self->{exchangerate} =
          $self->get_exchangerate( $dbh, $self->{currency}, $self->{transdate},
            $fld );

        # store amounts in {acc_trans}{$key} for multiple accounts
        while ( my $ref = $sth->fetchrow_hashref('NAME_lc') ) {
            $self->db_parse_numeric(sth=>$sth, hashref=>$ref);#tshvr
            for my $aref (@{$ref->{bu_lines}}){
                $ref->{"b_unit_$aref->[0]"} = $aref->[1];
            }
            $ref->{exchangerate} =
              $self->get_exchangerate( $dbh, $self->{currency},
                $ref->{transdate}, $fld );
            if ($self->{reverse}){
                $ref->{amount} *= -1;
            }

            push @{ $self->{acc_trans}{ $xkeyref{ $ref->{accno} } } }, $ref;
        }

        $sth->finish;


    }
    else {

        if ( !$self->{"$self->{vc}_id"} ) {
            $self->lastname_used( $myconfig, $dbh, $vc, $module );
        }
    }
    for (qw(separate_duties current_date curr closedto revtrans lock_description)) {
        if ($_ eq 'closedto'){
            $query = qq|
                SELECT value::date FROM defaults
                 WHERE setting_key = '$_'|;
        } elsif ($_ eq 'current_date') {
            $query = qq| select $_|;
        } else {
            $query = qq|
                SELECT value FROM defaults
                 WHERE setting_key = '$_'|;
        }

        $sth = $dbh->prepare($query);
        $sth->execute || $self->dberror($query);

        ($val) = $sth->fetchrow_array();
        if ( $_ eq 'curr' ) {
            $self->{currencies} = $val;
        }
        else {
            $self->{$_} = $val;
        }
        $sth->finish;
    }
    if (!$self->{id} && !$self->{transdate}){
        $self->{transdate} = $self->{current_date};
    }

    $self->all_vc( $myconfig, $vc, $module, $dbh, $self->{transdate}, $job );
}

=item $form->get_setting($setting_name)

Looks up the value in the defaults table and returns it.

=cut

sub get_setting {
    my ($self, $setting) = @_;
    my $sth = $self->{dbh}->prepare('select * from setting_get(?)');
    $sth->execute($setting);
    my $ref = $sth->fetchrow_hashref('NAME_lc');
    return $ref->{value};
}

=item $form->lastname_used($myconfig, $dbh2, $vc, $module);

Fills the name, currency, ${vc}_id, duedate, and possibly invoice_notes
attributes of $form with the last used values for the transaction type specified
by both $vc and $form->{type}.  $vc can be either 'vendor' or 'customer' and if
unspecified will take on the value given in $form->{vc}, defaulting to 'vendor'.
If $form->{type} matches /_order/, the transaction type used is order, if it
matches /_quotation/, quotations are looked through.  If $form->{type} does not
match either of the above, then ar or ap transactions are used.

$myconfig, $dbh2, and $module are unused.

=cut

sub lastname_used {

    my ( $self, $myconfig, $dbh2, $vc, $module ) = @_;

    my $dbh = $self->{dbh};
    $vc ||= $self->{vc};    # add default to correct for improper passing
    my $arap;
    my $where;
    if ($vc eq 'customer') {
        $arap = 'ar';
    } else {
        $arap = 'ap';
        $vc = 'vendor';
    }
    my $sth;

    if ( $self->{type} =~ /_order/ ) {
        $arap  = 'oe';
        $where = "quotation = '0'";
    }

    if ( $self->{type} =~ /_quotation/ ) {
        $arap  = 'oe';
        $where = "quotation = '1'";
    }
    $where = "AND $where " if $where;
    my $inv_notes;
    # $inv_notes = "ct.invoice_notes," if $vc eq 'customer';
    # $inv_notes apparently not implemented at present.  --CT
    my $query = qq|
        SELECT entity.name, ct.curr AS currency, entity_id AS ${vc}_id,
            current_date + ct.terms AS duedate,
            $inv_notes
            ct.curr AS currency
        FROM entity_credit_account ct
        JOIN entity ON (ct.entity_id = entity.id)
        WHERE entity.id = (select entity_id from $arap
                            where entity_id IS NOT NULL $where
                                 order by id DESC limit 1)|;

    $sth = $self->{dbh}->prepare($query);
    $sth->execute() || $self->dberror($query);

    my $ref = $sth->fetchrow_hashref('NAME_lc');
    for ( keys %$ref ) { $self->{$_} = $ref->{$_} }
    $sth->finish;
}

=item $form->current_date($myconfig[, $thisdate, $days]);

If $thisdate is false, get the current date from the database.

If $thisdate is true, get the date $days days from $thisdate in the date
format specified by $myconfig->{dateformat} from the database.

=cut

sub current_date {

    my ( $self, $myconfig, $thisdate, $days ) = @_;

    my $dbh = $self->{dbh};
    my $query;
    my @queryargs;

    $days *= 1;
    if ($thisdate) {

        my $dateformat;

        if ($thisdate =~ /\d\d\d\d-\d\d-\d\d/) {
            $dateformat = 'yyyy-mm-dd';

        } else {
            $dateformat = $myconfig->{dateformat};
            if ( $myconfig->{dateformat} !~ /^y/ ) {
                my @a = split /\D/, $thisdate;
                $dateformat .= "yy" if ( length $a[2] > 2 );
            }

            if ( $thisdate !~ /\D/ ) {
                $dateformat = 'yyyymmdd';
            }
        }

        $query = qq|SELECT (to_date(?, ?)
                + ?::interval)::date AS thisdate|;
        @queryargs = ( $thisdate, $dateformat, sprintf('%d days', $days) );

    }
    else {
        $query     = qq|SELECT current_date AS thisdate|;
        @queryargs = ();
    }

    my $sth = $dbh->prepare($query);
    $sth->execute(@queryargs);
    $thisdate = $sth->fetchrow_array;
    $thisdate;
}

=item $form->like($str);

Returns '%$str%'

=cut

sub like {

    my ( $self, $str ) = @_;

    "%$str%";
}

=item $form->redo_rows($flds, $new, $count, $numrows);

$flds refers to a list of field names and $new refers to a list of row detail
hashes with the elements of $flds as keys as well as runningnumber for an order
or another multi-row item that normally expresses elements in the form
$form->{${fieldname}_${index}}.

For every $field in @{$flds} populates $form->{${field}_$i} with an appropriate
value from a $new detail hash where $i is an index between 1 and $count.  The
ordering of the details is done in terms of the runningnumber element of the
row detail hashes in $new.

All $form attributes with names of the form ${field}_$i where the index $i is
between $count + 1 and $numrows is deleted.

=cut

sub redo_rows {

    my ( $self, $flds, $new, $count, $numrows ) = @_;

    my @ndx = ();

    for ( 1 .. $count ) {
        push @ndx, { num => $new->[ $_ - 1 ]->{runningnumber}, ndx => $_ };
    }

    my $i = 0;

    # fill rows
    foreach my $item ( sort { $a->{num} <=> $b->{num} } @ndx ) {
        $i++;
        my $j = $item->{ndx} - 1;
        for ( @{$flds} ) { $self->{"${_}_$i"} = $new->[$j]->{$_} }
    }

    # delete empty rows
    for $i ( $count + 1 .. $numrows ) {
        for ( @{$flds} ) { delete $self->{"${_}_$i"} }
    }
}

=item $form->get_partsgroup($myconfig[, $p]);

Populates the list referred to as $form->{all_partsgroup}.  $p refers to a hash
that describes which partsgroups to retrieve.  $p->{searchitems} can be 'part',
'service', 'assembly', 'labor', or 'nolabor' and will limit the groups to those
that contain the item type described.  $p->{searchitems} and $p->{all} conflict.
If $p->{all} is set and $p->{language_code} is not, all partsgroups are
retrieved.  If $p->{language_code} is set, also include the translation
description specified by $p->{language_code} for the partsgroup.

The results in $form->{all_partsgroup} are normally sorted by partsgroup name.
If a language_code is specified, the results are then sorted by the translated
description.

$myconfig is unused.

=cut

sub get_partsgroup {

    my ( $self, $myconfig, $p ) = @_;

    my $dbh = $self->{dbh};

    my $query = qq|SELECT DISTINCT pg.id, pg.partsgroup
                     FROM partsgroup pg
                     JOIN parts p ON (p.partsgroup_id = pg.id)|;

    my $where;
    my $sortorder = "partsgroup";

    if ( $p->{searchitems} eq 'part' ) {
        $where = qq| WHERE (p.inventory_accno_id > 0
                       AND p.income_accno_id > 0)|;
    } elsif ( $p->{searchitems} eq 'service' ) {
        $where = qq| WHERE p.inventory_accno_id IS NULL|;
    } elsif ( $p->{searchitems} eq 'assembly' ) {
        $where = qq| WHERE p.assembly = '1'|;
    } elsif ( $p->{searchitems} eq 'labor' ) {
        $where =
          qq| WHERE p.inventory_accno_id > 0 AND p.income_accno_id IS NULL|;
    } elsif ( $p->{searchitems} eq 'nolabor' ) {
        $where = qq| WHERE p.income_accno_id > 0|;
    }

    if ( $p->{all} ) {
        $query = qq|SELECT id, partsgroup
                      FROM partsgroup|;
    }
    my @queryargs = ();

    if ( $p->{language_code} ) {
        $sortorder = "translation";

        $query = qq|
            SELECT DISTINCT pg.id, pg.partsgroup,
                t.description AS translation
            FROM partsgroup pg
            JOIN parts p ON (p.partsgroup_id = pg.id)
            LEFT JOIN translation t ON (t.trans_id = pg.id
                AND t.language_code = ?)|;
        @queryargs = ( $p->{language_code} );
    }

    $query .= qq| $where ORDER BY $sortorder|;

    my $sth = $dbh->prepare($query);
    $sth->execute(@queryargs) || $self->dberror($query);

    $self->{all_partsgroup} = ();

    while ( my $ref = $sth->fetchrow_hashref('NAME_lc') ) {
        push @{ $self->{all_partsgroup} }, $ref;
    }

    $sth->finish;
}

=item $form->update_status($myconfig);

DELETEs all status rows which have a formname of $form->{formname} and a
trans_id of $form->{id}.  INSERTs a new row into status where trans_id is
$form->{id}, formname is $form->{formname}, printed and emailed are true if
their respective $form attributes match /$form->{formname}/, and spoolfile is
the file extracted from the string $form->{queued} or NULL if there is no entry
for $form->{formname}.

$myconfig is unused.

=cut

sub update_status {

    my ( $self, $myconfig, $commit ) = @_;

    # no id return
    return unless $self->{id};

    my $dbh = $self->{dbh};

    my %queued = split / +/, $self->{queued};
    my $spoolfile =
      ( $queued{ $self->{formname} } )
      ? $queued{ $self->{formname} }
      : undef;

    my $query = qq|DELETE FROM status
                    WHERE formname = ?
                      AND trans_id = ?|;

    my $sth = $dbh->prepare($query);
    $sth->execute( $self->{formname}, $self->{id} ) || $self->dberror($query);

    $sth->finish;

    my $printed = ( $self->{printed} =~ /$self->{formname}/ ) ? "1" : "0";
    my $emailed = ( $self->{emailed} =~ /$self->{formname}/ ) ? "1" : "0";

    $query = qq|
        INSERT INTO status
            (trans_id, printed, emailed, spoolfile, formname)
        VALUES (?, ?, ?, ?, ?)|;

    $sth = $dbh->prepare($query);
    $sth->execute( $self->{id}, $printed, $emailed, $spoolfile,
        $self->{formname} ) || $self->dberror($query);
    $sth->finish;
}

=item $form->save_status();

Clears out any old status entries for $form->{id} and saves new status entries.
Queued form names are extracted from $form->{queued}.  Printed and emailed form
names are extracted from $form->{printed} and $form->{emailed}.  The queued,
printed, and emailed fields are space separated lists.

=cut

sub save_status {

    my ($self) = @_;

    my $dbh = $self->{dbh};


    my $formnames  = $self->{printed};
    my $emailforms = $self->{emailed};

    my $query = qq|DELETE FROM status
                    WHERE trans_id = ?|;

    my $sth = $dbh->prepare($query);
    $sth->execute( $self->{id} ) || $self->dberror($query);
    $sth->finish;

    my %queued;
    my $formname;

    my $printed;
    my $emailed;

    if ( $self->{queued} ) {

        %queued = split / +/, $self->{queued};

        foreach $formname ( keys %queued ) {

            $printed = ( $self->{printed} =~ /$formname/ ) ? "1" : "0";
            $emailed = ( $self->{emailed} =~ /$formname/ ) ? "1" : "0";

            if ( $queued{$formname} ) {
                $query = qq|
                    INSERT INTO status
                        (trans_id, printed, emailed,
                        spoolfile, formname)
                    VALUES (?, ?, ?, ?, ?)|;

                $sth = $dbh->prepare($query);
                $sth->execute( $self->{id}, $printed, $emailed,
                    $queued{$formname}, $formname )
                  || $self->dberror($query);
                $sth->finish;
            }

            $formnames  =~ s/$formname//;
            $emailforms =~ s/$formname//;

        }
    }

    # save printed, emailed info
    $formnames  =~ s/^ +//g;
    $emailforms =~ s/^ +//g;

    my %status = ();
    for ( split / +/, $formnames )  { $status{$_}{printed} = 1 }
    for ( split / +/, $emailforms ) { $status{$_}{emailed} = 1 }

    foreach my $formname ( keys %status ) {
        $printed = ( $formnames  =~ /$self->{formname}/ ) ? "1" : "0";
        $emailed = ( $emailforms =~ /$self->{formname}/ ) ? "1" : "0";

        $query = qq|
            INSERT INTO status (trans_id, printed, emailed,
                formname)
            VALUES (?, ?, ?, ?)|;

        $sth = $dbh->prepare($query);
        $sth->execute( $self->{id}, $printed, $emailed, $formname );
        $sth->finish;
    }
}

=item $form->get_recurring();

Sets $form->{recurring} to contain info about the recurrence schedule for the
action $form->{id}.  $form->{recurring} is of the same form used by
$form->save_recurring($dbh2, $myconfig).

  reference,startdate,repeat,unit,howmany,payment,print,email,message
       text      date    int text     int     int  text  text    text

=cut

sub get_recurring {

    my ($self) = @_;

    my $dbh = $self->{dbh};
    my $query = qq/
                SELECT extract(days from recurring_interval) as days,
             extract(months from recurring_interval) as months,
             extract(years from recurring_interval) as years,
             s.*, se.formname || ':' || se.format AS emaila,
            se.message, sp.formname || ':' ||
                sp.format || ':' || sp.printer AS printa
        FROM recurring s
        LEFT JOIN recurringemail se ON (s.id = se.id)
        LEFT JOIN recurringprint sp ON (s.id = sp.id)
        WHERE s.id = ?/;

    my $sth = $dbh->prepare($query);
    $sth->execute( $self->{id} ) || $self->dberror($query);

    for (qw(email print)) { $self->{"recurring$_"} = "" }

    while ( my $ref = $sth->fetchrow_hashref('NAME_lc') ) {
        for ( keys %$ref ) { $self->{"recurring$_"} = $ref->{$_} }
        $self->{recurringemail} .= "$ref->{emaila}:";
        $self->{recurringprint} .= "$ref->{printa}:";
        for (qw(emaila printa)) { delete $self->{"recurring$_"} }
    }

    $sth->finish;
    chop $self->{recurringemail};
    chop $self->{recurringprint};

    if ( $self->{recurringyears} ) {
        $self->{recurringunit} = 'years';
        $self->{recurringrepeat} = $self->{recurringyears};
    }
    elsif ( $self->{recurringmonths} ) {
        $self->{recurringunit} = 'months';
        $self->{recurringrepeat} = $self->{recurringmonths};
    }
    elsif ( $self->{recurringdays} && ( $self->{recurringdays} % 7 == 0 ) ) {
        $self->{recurringunit} = 'weeks';
        $self->{recurringrepeat} = $self->{recurringdays} / 7;
    }
    elsif ( $self->{recurringdays} ) {
        $self->{recurringunit} = 'days';
        $self->{recurringrepeat} = $self->{recurringdays};
    }

    if ( $self->{recurringstartdate} ) {

        $self->{recurringreference} =
          $self->escape( $self->{recurringreference}, 1 );
        $self->{recurringmessage} =
          $self->escape( $self->{recurringmessage}, 1 );
        for (
            qw(reference startdate repeat unit howmany
            payment print email message)
          )
        {

            $self->{recurring} .= qq|$self->{"recurring$_"},|;
        }

        chop $self->{recurring};
    }
}

=item $form->save_recurring($dbh2, $myconfig);

Saves or deletes recurring transaction scheduling.  $form->{id} is used to
determine the id used in the various recurring tables.  A recurring transaction
schedule is deleted by having $form->{recurring} be false.  For adding or
updating a schedule, $form->{recurring} is a comma separated field with partial
subfield quoting of the form:

  reference,startdate,repeat,unit,howmany,payment,print,email,message
       text      date    int text     int     int  text  text    text

=over

=item reference

A URI-encoded reference string for the recurrence set.

=item startdate

The index date for the recurrence.

=item repeat

The unitless repetition frequency.

=item unit

The interval unit used.  Can be 'days', 'weeks', 'months', or 'years',
capitalisation and pluralisation ignored.

=item howmany

The number of recurrences for the transaction.

=item payment

Flag to indicate if a payment is included in the transaction.

=item print

A colon separated list of formname:format:printer triplets.

=item email

A colon separated list of formname:format pairs.

=item message

A URI-encoded message for the emails to be sent.

=back

Values for the nextdate and enddate columns of the recurring table are
calculated using startdate, repeat, unit, howmany, and the current database
date.  All other fields of the recurring, recurringemail, and recurringprint are
obtained directly from $form->{recurring}.

B<WARNING>: This function does not check the validity of most subfields of
$form->{recurring}.

$dbh2 is not used.

=cut

sub save_recurring {

    my ( $self, $dbh2, $myconfig, $is_oe) = @_;

    my $dbh = $self->{dbh};

    my $query;

    $query = qq|DELETE FROM recurringemail
                 WHERE id = ?|;

    my $sth = $dbh->prepare($query) || $self->dberror($query);
    $sth->execute( $self->{id} ) || $self->dberror($query);

    $query = qq|DELETE FROM recurringprint
                 WHERE id = ?|;

    $sth = $dbh->prepare($query) || $self->dberror($query);
    $sth->execute( $self->{id} ) || $self->dberror($query);

    $query = qq|DELETE FROM recurring
                 WHERE id = ?|;

    $sth = $dbh->prepare($query) || $self->dberror($query);
    $sth->execute( $self->{id} ) || $self->dberror($query);

    if ( $self->{recurring} ) {

        my %s = ();
        (
            $s{reference}, $s{startdate}, $s{repeat},
            $s{unit},      $s{howmany},   $s{payment},
            $s{print},     $s{email},     $s{message}
        ) = split /,/, $self->{recurring};

        if ($s{unit} !~ /^(day|week|month|year)s?$/i){
            $dbh->rollback;
            $self->error("Invalid recurrence unit");
        }
        if ($s{howmany} == 0){
            $self->error("Cannot set to recur 0 times");
        }

        for (qw(reference message)) { $s{$_} = $self->unescape( $s{$_} ) }
        for (qw(repeat howmany payment)) { $s{$_} *= 1 }

        # calculate enddate
        my $advance = $s{repeat} * ( $s{howmany} - 1 );

        $query = qq|SELECT (?::date + interval '$advance $s{unit}')|;

        my ($enddate) = $dbh->selectrow_array($query, undef, $s{startdate});

        # calculate nextdate
        $query = qq|
            SELECT current_date - ?::date AS a,
                ?::date - current_date AS b|;

        $sth = $dbh->prepare($query) || $self->dberror($query);
        $sth->execute( $s{startdate}, $enddate ) || $self->dberror($query);
        my ( $a, $b ) = $sth->fetchrow_array;

        if ( $a + $b ) {
            $advance =
              int( ( $a / ( $a + $b ) ) * ( $s{howmany} - 1 ) + 1 ) *
              $s{repeat};
        }
        else {
            $advance = 0;
        }

        my $nextdate = $enddate;
        if ( $advance > 0 ) {
            if ( $advance < ( $s{repeat} * $s{howmany} ) ) {

                $query = qq|SELECT (?::date + interval '$advance $s{unit}')|;

                ($nextdate) = $dbh->selectrow_array($query, undef, $s{startdate}) || $self->dberror($query);
            }

        }
        else {
            $nextdate = $s{startdate};
        }

        if ( $self->{recurringnextdate} ) {

            $nextdate = $self->{recurringnextdate};

            $query = qq|SELECT ?::date - ?::date|;

            if ( $dbh->selectrow_array($query, undef, $enddate, $nextdate) < 0 ) {
                undef $nextdate;
            }
        }

        $self->{recurringpayment} *= 1;

        $query = qq|
            INSERT INTO recurring
                (id, reference, startdate, enddate, nextdate,
                                recurring_interval, howmany, payment)
                        VALUES (?, null, ?, ?, ?, ?::interval, ?, ?)|;

        $sth = $dbh->prepare($query) || $self->dberror($query);
        $sth->execute(
            $self->{id}, $s{startdate},
            $enddate,    $nextdate,     "$s{repeat} $s{unit}",
            $s{howmany},   $s{payment}
        ) || $self->dberror($query);

        my @p;
        my $p;
        my $i;
        my $sth;

        if ( $s{email} ) {

            # formname:format
            @p = split /:/, $s{email};

            $query =
              qq|INSERT INTO recurringemail (id, formname, format, message)
                        VALUES (?, ?, ?, ?)|;

            $sth = $dbh->prepare($query) || $self->dberror($query);

            for ( $i = 0 ; $i <= $#p ; $i += 2 ) {
                $sth->execute( $self->{id}, $p[$i], $p[ $i + 1 ], $s{message} )
                    || $self->dberror($query);
            }

            $sth->finish;
        }

        if ( $s{print} ) {

            # formname:format:printer
            @p = split /:/, $s{print};

            $query =
              qq|INSERT INTO recurringprint (id, formname, format, printer)
                        VALUES (?, ?, ?, ?)|;

            $sth = $dbh->prepare($query) || $self->dberror($query);

            for ( $i = 0 ; $i <= $#p ; $i += 3 ) {
                $p = ( $p[ $i + 2 ] ) ? $p[ $i + 2 ] : "";
                $sth->execute( $self->{id}, $p[$i], $p[ $i + 1 ], $p )
                    || $self->dberror($query);
            }

            $sth->finish;
        }
    }

}


=item $form->save_intnotes($myconfig, $vc);

Sets the intnotes field of the entry in the table $vc that has the id
$form->{id} to the value of $form->{intnotes}.

Does nothing if $form->{id} is not set.

=cut

sub save_intnotes {

    my ( $self, $myconfig, $vc ) = @_;

    # no id return
    return unless $self->{id};

    my $dbh = $self->{dbh};

    my $query = qq|UPDATE $vc SET intnotes = ? WHERE id = ?|;

    my $sth = $dbh->prepare($query);
    $sth->execute( $self->{intnotes}, $self->{id} ) || $self->dberror($query);
}

=item $form->update_defaults($myconfig, $fld[, $dbh [, $nocommit]);

Updates the defaults entry for the setting $fld following rules specified by
the existing value and returns the processed value that results.  If $form is
false, such as the case when invoked as "Form::update_defaults('',...)", $dbh is
used as the handle.  When $form is set, it uses $form->{dbh}, initialising the
connection if it does not yet exist.  The entry $fld must exist prior to
executing this function and this update function does not handle the general
case of updating the defaults table.

Note that nocommit prevents the db from committing in this function.

B<NOTE>: rules handling is currently broken.

Rules followed by this function's processing:

=over

=item *

If digits are found in the field, increment the left-most set.  This change,
unlike the others is reflected in the UPDATE.

=item *

Replace <?lsmb date ?> with the date specified in $form->{transdate} formatted
as $myconfig->{dateformat}.

=item *

Replace <?lsmb curr ?> with the value of $form->{currency}

=back

=cut

sub update_defaults {

    my ( $self, $myconfig, $fld,$dbh_parm,$nocommit) = @_;
    if ($self->{setting_sequence}){
        return LedgerSMB::Setting::Sequence->increment(
              $self->{setting_sequence}, $self);
    }

    my $dbh = LedgerSMB::App_State::DBH;

    #if ( !$self ) { #if !$self, previous statement would already have failed!
    #    $dbh = $_[3];
    #}

    my $query = qq|
        SELECT value FROM defaults
         WHERE setting_key = ? FOR UPDATE|;
    my $sth = $self->{dbh}->prepare($query);
    $sth->execute($fld);
    ($_) = $sth->fetchrow_array();

    $_ = "0" unless $_;

# check for and replace
# <?lsmb DATE ?>, <?lsmb YYMMDD ?>, <?lsmb YEAR ?>, <?lsmb MONTH ?>, <?lsmb DAY ?> or variations of
# <?lsmb NAME 1 1 3 ?>, <?lsmb BUSINESS ?>, <?lsmb BUSINESS 10 ?>, <?lsmb CURR... ?>
# <?lsmb DESCRIPTION 1 1 3 ?>, <?lsmb ITEM 1 1 3 ?>, <?lsmb PARTSGROUP 1 1 3 ?> only for parts
# <?lsmb PHONE ?> for customer and vendors

    my $num = $_;
    ($num) = $num =~ /\D*(\d+)\D*$/;

    if ( defined $num ) {
        my $incnum;

        # if we have leading zeros check how long it is

        if ( $num =~ /^0/ ) {
            my $l = length $num;
            $incnum = $num + 1;
            $l -= length $incnum;

            # pad it out with zeros
            my $padzero = "0" x $l;
            $incnum = ( "0" x $l ) . $incnum;
        }
        else {
            $incnum = $num + 1;
        }

        s/$num/$incnum/;
    }

    my $dbvar = $_;
    my $var   = $_;
    my $str;
    my $param;

    if (/<\?lsmb /) {

        while (/<\?lsmb /) {

            s/<\?lsmb .*? \?>//;
            last unless $&;
            $param = $&;
            $str   = "";

            if ( $param =~ /<\?lsmb date \?>/i ) {
                $str = (
                    $self->split_date(
                        $myconfig->{dateformat},
                        $self->{transdate}
                    )
                )[0];
                $var =~ s/$param/$str/;
            }

            if ( $param =~
/<\?lsmb (name|business|description|item|partsgroup|phone|custom)/i
              )
            {
            #SC: XXX hairy, undoc, possibly broken

                my $fld = lc $&;
                $fld =~ s/<\?lsmb //;

                if ( $fld =~ /name/ ) {
                    if ( $self->{type} ) {
                        $fld = $self->{vc};
                    }
                }

                my $p = $param;
                $p =~ s/(<|>|%)//g;
                my @p = split / /, $p;
                my @n = split / /, uc $self->{$fld};

                if ( $#p > 0 ) {

                    for ( my $i = 1 ; $i <= $#p ; $i++ ) {
                        $str .= substr( $n[ $i - 1 ], 0, $p[$i] );
                    }

                }
                else {
                    ($str) = split /--/, $self->{$fld};
                }

                $var =~ s/$param/$str/;
                $var =~ s/\W//g if $fld eq 'phone';
            }

            if ( $param =~ /<\?lsmb (yy|mm|dd)/i ) {
        # SC: XXX Does this even work anymore?
                my $p = $param;
                $p =~ s/lsmb//;
                $p =~ s/[^YyMmDd]//g;
                my %d = ( yy => 1, mm => 2, dd => 3 );
                my $str = $p;

                my @a = $self->split_date( $myconfig->{dateformat},
                    $self->{transdate} );
                for my $k( keys %d ) { $str =~ s/$k/$a[ $d{$k} ]/i}
                $var =~ s/\Q$param\E/$str/i;
            }

            if ( $param =~ /<\?lsmb curr/i ) {
                my $curr = $self->{currency} || $self->{curr};
                $var =~ s/<\?lsmb curr \?>/$curr/i;
            }
        }
    }

    $query = qq|
        UPDATE defaults
           SET value = ?
         WHERE setting_key = ?|;

    $sth = $self->{dbh}->prepare($query);
    $sth->execute( $dbvar, $fld ) || $self->dberror($query);

    return $var;
}

=item should_update_defaults(fldname)

This should be used instead of direct tests, and checks for a sequence selected.

=cut

sub should_update_defaults {
    my ($self, $fldname) = @_;

    my $gapless_ar = LedgerSMB::Setting->get('gapless_ar');
    return 0 if $gapless_ar and ($fldname eq 'invnumber');

    if (!$self->{$fldname}){
       return 1;
    }
    if (!$self->{setting_sequence}){
        return 0;
    }

    my $sequence = LedgerSMB::Setting::Sequence->get($self->{setting_sequence});
    return 1 unless $sequence->accept_input;
    return 0;
}

=item $form->update_invnumber

If invnumber is not set, updates it.  Used when gapless numbering is in effect

=cut

sub update_invnumber {
    my $self = shift;
    my $sth = $LedgerSMB::App_State::DBH->prepare(
        'select invnumber from ar where id = ?'
    );
    $sth->execute($self->{id});
    my ($invnumber) = $sth->fetchrow_array;
    return if defined $invnumber or !$sth->rows;
    $sth->finish;
    $sth = $LedgerSMB::App_State::DBH->prepare(
      'update ar set invnumber = ? where id = ?'
    );
    $sth->execute($self->update_defaults(
                          $LedgerSMB::App_State::User, 'sinumber'
                                        ), $self->{id});
}

=item $form->db_prepare_vars(var1, var2, ..., varI<n>)

Undefines $form->{varI<m>}, 1 <= I<m> <= I<n>, iff $form-<{varI<m> is both
false and not "0".

=cut

sub db_prepare_vars {
    my $self = shift;

    for (@_) {
        if ( !$self->{$_} and $self->{$_} ne "0" ) {
            undef $self->{$_};
        }
    }
}

=item $form->split_date($dateformat[, $date]);

Returns ($rv, $yy, $mm, $dd) for the provided $date, or the current date if no
date is provided.  $rv is a seperator-free merging of the fields $yy, $mm, and
$dd in the ordering supplied by $dateformat.  If the supplied $date does not
contain non-digit characters, $rv is $date and the other return values are
undefined.

$yy is two digits.

=cut

sub split_date {

    my ( $self, $dateformat, $date ) = @_;

    my $mm;
    my $dd;
    my $yy;
    my $rv;

    if ( !$date ) {
        my @d = localtime;
        $dd = $d[3];
        $mm = ++$d[4];
        $yy = substr( $d[5], -2 );
        $mm = substr( "0$mm", -2 );
        $dd = substr( "0$dd", -2 );
    }
    $dateformat = 'yyyy-mm-dd' if $date =~ /\d{4}\D\d{2}\D\d{2}/;

    if ( $dateformat =~ /^yy/ ) {

        if ($date) {

            if ( $date =~ /\D/ ) {
                ( $yy, $mm, $dd ) = split /\D/, $date;
                $mm *= 1;
                $dd *= 1;
                $mm = substr( "0$mm", -2 );
                $dd = substr( "0$dd", -2 );
                $yy = substr( $yy,    -2 );
                $rv = "$yy$mm$dd";
            }
            else {
                $rv = $date;
            }
        }
        else {
            $rv = "$yy$mm$dd";
        }
    }
    elsif ( $dateformat =~ /^mm/ ) {

        if ($date) {

            if ( $date =~ /\D/ ) {
                ( $mm, $dd, $yy ) = split /\D/, $date;
                $mm *= 1;
                $dd *= 1;
                $mm = substr( "0$mm", -2 );
                $dd = substr( "0$dd", -2 );
                $yy = substr( $yy,    -2 );
                $rv = "$mm$dd$yy";
            }
            else {
                $rv = $date;
            }
        }
        else {
            $rv = "$mm$dd$yy";
        }
    }
    elsif ( $dateformat =~ /^dd/ ) {

        if ($date) {

            if ( $date =~ /\D/ ) {
                ( $dd, $mm, $yy ) = split /\D/, $date;
                $mm *= 1;
                $dd *= 1;
                $mm = substr( "0$mm", -2 );
                $dd = substr( "0$dd", -2 );
                $yy = substr( $yy,    -2 );
                $rv = "$dd$mm$yy";
            }
            else {
                $rv = $date;
            }
        }
        else {
            $rv = "$dd$mm$yy";
        }
    }

    ( $rv, $yy, $mm, $dd );
}

=item $form->format_date($date);

Returns $date converted from 'yyyy-mm-dd' format to the format specified by
$form->{db_dateformat}.  If the supplied date does not match /^\d{4}\D/,
return the supplied date.

This function takes a four digit year and returns the date with a four digit
year.

=cut

sub format_date {

    # takes an iso date in, and converts it to the date for printing
    my ( $self, $date ) = @_;
    my $datestring;
    if ( $date =~ /^\d{4}\D/ ) {    # is an ISO date
        $datestring = $self->{db_dateformat};
        my ( $yyyy, $mm, $dd ) = split( /\W/, $date );
        $datestring =~ s/y+/$yyyy/;
        $datestring =~ s/mm/$mm/;
        $datestring =~ s/dd/$dd/;
    }
    else {                          # return date
        $datestring = $date;
    }
    return $datestring;
}

=item $form->from_to($yyyy, $mm[, $interval]);

Returns the date $yyyy-$mm-01 and the the last day of the month interval - 1
months from then in the form ($form->format_date(fromdate),
$form->format_date(later)).  If $interval is false but defined, the later date
is the current date.

This function dies horribly when $mm + $interval > 24

=cut

sub from_to {

    my ( $self, $yyyy, $mm, $interval ) = @_;

    $yyyy = 0 unless defined $yyyy;
    $mm = 0 unless defined $mm;

    my @t;
    my $dd       = 1;
    my $fromdate = "$yyyy-${mm}-01";
    my $bd       = 1;

    if ( defined $interval ) {

        if ( $interval == 12 ) {
            $yyyy++;
        }
        else {

            if ( ( $mm += $interval ) > 12 ) {
                $mm -= 12;
                $yyyy++;
            }

            if ( $interval == 0 ) {
                @t    = localtime(time);
                $dd   = $t[3];
                $mm   = $t[4] + 1;
                $yyyy = $t[5] + 1900;
                $bd   = 0;
            }
        }

    }
    else {

        if ( ++$mm > 12 ) {
            $mm -= 12;
            $yyyy++;
        }
    }

    $mm--;
    @t = localtime( Time::Local::timelocal( 0, 0, 0, $dd, $mm, $yyyy ) - $bd );

    $t[4]++;
    $t[4] = substr( "0$t[4]", -2 );
    $t[3] = substr( "0$t[3]", -2 );
    $t[5] += 1900;


    return ( $fromdate, "$t[5]-$t[4]-$t[3]" );
}


# New block of code to get control code from batch table


sub get_batch_control_code {

    my ( $self, $dbh, $batch_id) = @_;

    my ($query,$sth,$control);


    if ( !$dbh ) {
        $dbh = $self->{dbh};
    }

    $query=qq|select control_code from batch where id=?|;
    $sth=$dbh->prepare($query) || $self->dberror($query);
    $sth->execute($batch_id) || $self->dberror($query);
    $control=$sth->fetchrow();
    $sth->finish();
    return $control;

}


#end get control code from batch table


#start description

sub get_batch_description {

    my ( $self, $dbh, $batch_id) = @_;

    my ($query,$sth,$desc);


    if ( !$dbh ) {
        $dbh = $self->{dbh};
    }

    $query=qq|select description from batch where id=?|;
    $sth=$dbh->prepare($query) || $self->dberror($query);
    $sth->execute($batch_id) || $self->dberror($query);
    $desc=$sth->fetchrow();
    $sth->finish();
    return $desc;

}

=item sequence_dropdown(setting_key)

This function returns the HTML code for a dropdown box for a given setting
key.  It is not generally to be used with code on new templates.

=cut

sub sequence_dropdown{
    my ($self, $setting_key) = @_;
    return undef if $self->{id} and ($setting_key ne 'sinumber');
    my @sequences = LedgerSMB::Setting::Sequence->list($setting_key);
    my $retval = qq|<select name='setting_sequence' class='sequence'>\n|;
    $retval .= qq|<option></option>|;
    for my $seq (@sequences){
        my $selected = '';
        my $label = $seq->label;
        $selected = "SELECTED='SELECTED'"
            if $self->{setting_sequence} eq $label;
        $retval .= qq|<option value='$label' $selected>$label</option>\n|;
    }
    $retval .= "</select>";
    if (@sequences){
        return $retval;
    } else {
        return undef
    }
}
#end decrysiption

1;


=back

