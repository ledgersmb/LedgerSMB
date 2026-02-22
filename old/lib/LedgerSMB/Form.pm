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
 # Copyright (C) 2006-2017
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

use v5.36.1;
use charnames qw(:full);
use open ':utf8';
use utf8;


use LedgerSMB;
use LedgerSMB::Magic qw( SCRIPT_OLDSCRIPTS );
use LedgerSMB::PGNumber;
use LedgerSMB::Setting::Sequence;
use LedgerSMB::Setting;
use LedgerSMB::StopProcessing;

use Carp;
use List::Util qw(first);
use Log::Any;
use LWP::Simple;
use PGObject;
use Symbol;
use Time::Local;



our $logger = Log::Any->get_logger(category => 'LedgerSMB::Form');


=item new Form([$argstr])

Returns a reference to new Form object.  The initial set of attributes is
obtained from $argstr, a CGI query string, or $ARGV[0].  All the values are
run through unescape to undo any URI encoding.

The version and dbversion attributes are set to hardcoded values; action,
nextsub, path, script, and login are filtered to remove some dangerous values.

$form->error may be called to deny access on some attribute values.

=cut

sub new {
    my $type = shift;
    my $argstr = shift;
    my $self = bless {}, $type;

    my %orig;
    if (defined $argstr) {
        %orig = split( /[&=]/, $argstr, -1);
        for ( keys %orig ) {
            $self->{unescape( "", $_) } = unescape( "", $orig{$_} );
        }

        for my $p(keys %$self){
            utf8::decode($self->{$p});
            utf8::upgrade($self->{$p});
            delete $self->{$p} if $self->{$p} eq '_!lsmb!empty!_';
            $self->{$p} =~ s/\N{NULL}//g;
        }
        $self->{nextsub} //= '';
        $self->{__action} //= $self->{nextsub};
    }
    $self->{version} = $self->{dbversion} = $LedgerSMB::VERSION;


    $self;
}


sub open_form {
    my ($self) = @_;
    my @results ;

    if ($self->{form_id} && $self->{form_id} =~ '^\s*$'){
        delete $self->{form_id};
    }

    #HV session_id not always set in LedgerSMB/Auth/DB.pm because of mix old,new code-chain?
    if ($self->{session_id}) {
        my $sth = $self->{dbh}->prepare('select form_open(?)');
        my $rc=$sth->execute($self->{session_id})
            or $self->dberror;
        #HV ERROR:Invalid session,if count(*) FROM session!=1,multiple login

        if(! $rc) {
            $logger->error("select form_open \$self->{form_id}=$self->{form_id} \$self->{session_id}=$self->{session_id} \$rc=$rc,invalid count FROM session?");
            return undef;
        }
        @results = $sth->fetchrow_array();
    }
    else {
        $logger->debug("no \$self->{session_id}!");
        return undef;
    }

    $self->{form_id} = $results[0];
    return $results[0];
}

sub check_form {
    my ($self) = @_;

    return 0 unless $self->{form_id};
    my $sth = $self->{dbh}->prepare('select form_check(?, ?)')
        or die $self->{dbh}->errstr;
    $sth->execute($self->{session_id}, $self->{form_id})
        or die $self->{dbh}->errstr;
    my @results = $sth->fetchrow_array();
    return $results[0];
}

sub close_form {
    my ($self) = @_;
    if ($self->{form_id} && $self->{form_id} =~ '^\s*$'){
        delete $self->{form_id};
    }

    my $sth = $self->{dbh}->prepare('select form_close(?, ?)')
        or die $self->{dbh}->errstr;
    $sth->execute($self->{session_id}, $self->{form_id})
        or die $self->{dbh}->errstr;
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

    return if not defined $str;
    # for Apache 2 we escape strings twice
    if ($ENV{SERVER_SIGNATURE}
        && ( $ENV{SERVER_SIGNATURE} =~ /Apache\/2\.(\d+)\.(\d+)/ )
        && !$beenthere
    ) {
        $str = $self->escape( $str, 1 ) if $1 == 0 && $2 < 44;  ## no critic (ProhibitMagicNumbers) sniff
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

    return if ! defined $str;

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
            next if not defined $self->{$_};

            print qq|<input type="hidden" id="$_" name="$_" value="|
              . $self->quote( $self->{$_} )
              . qq|" />\n|;
        }
    }
    else {
        delete $self->{header};

        for ( grep { ! ref $self->{$_} } # no use serializing references
              grep { ! m/^all_/ }
              grep { ! m/^_/ }
              sort keys %$self ) {
            print qq|<input type="hidden" id="$_" name="$_" value="|
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

=item $form->call_procedure()

=cut

sub call_procedure {
    my $self = shift;
    my %args = @_;
    $args{funcschema} ||= $self->{_wire}->get( 'db' )->schema;
    $args{funcname} ||= $args{procname};
    $args{dbh} = $self->{dbh};
    $args{args} ||= [];
    return PGObject->call_procedure(%args);
}

=item $form->finalize_request();

Stops further processing, allowing post-request cleanup on intermediate
levels by throwing an exception.

This function replaces explicit 'exit()' calls.

=cut

sub finalize_request {
    LedgerSMB::StopProcessing->throw;
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

        $msg =~ s/\n/<br>/g;

    if (!$self->{header}) {
            $self->header;
            print qq| <body>|;
            $self->{header} = 1;
        }

        print "<b>$msg</b>";
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

    return 0 if ! defined $str;

    for ( split /\n/, $str ) {
        $rows += int( ( (length) - 2 ) / $cols ) + 1;
    }

    $maxrows = $rows unless defined $maxrows;

    return ( $rows > $maxrows ) ? $maxrows : $rows;
}

=item $form->dberror($msg);

Outputs a message as in $form->error but with $form->{dbh}->errstr automatically
appended to $msg.

=cut

sub dberror {
    my ( $self, $msg ) = @_;
    $self->error( "$msg\n" . $self->{dbh}->errstr );
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
environment, does not output anything.  $init is ignored.  $headeradd is
ignored.

=cut

sub header {

    my ( $self, $init, $headeradd ) = @_;

    return if $self->{header} or $ENV{LSMB_NOHEAD};
    my $cache = 1; # default
    if ($self->{_error}){
        $cache = 0;
    }
    elsif ($self->{dbh}){
        # we have a db connection, so are logged in.  Let's see about caching.
        local $@;
        $cache = 0 if eval { $self->get_setting('disable_back') };
    }

    $ENV{LSMB_NOHEAD} = 1; # Only run once.

    print qq|Content-Type: text/html; charset=utf-8\n\n|;
    # We're not sending HTML HEAD, because the client doesn't look at it...
    $self->{header} = 1;
}

=item $form->open_status_div( $div_id )

Returns a div tag with an id of C<$div_id>.

=cut

sub open_status_div {
    my ($self, $div_id) = @_;

    my $id = $div_id ? "id=\"$div_id\"" : '';
    return "<div $id>";
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
        $self->_redirect();
        $self->finalize_request();
    }
    else {
        $self->info($msg);
        print '</body>';
        $self->finalize_request;
    }
}

sub _redirect {
    # referenced directly from am.pl, because of the need of our return value
    my ($self) = @_;
    my ( $script, $argv ) = split( /\?/, $self->{callback} // '', 2 );

    if ( !$script ) {    # http redirect to login.pl if called w/no args
        print "Location: login.pl\n";
        print "Content-type: text/html\n\n";
        return;
    }

    unless (first { $_ eq $script } SCRIPT_OLDSCRIPTS->@*) {
        print "Location: $self->{callback}\n";
        print "Content-type: text/html\n\n";
        return;
    }

    my $form = Form->new($argv);
    $form->{$_} = $self->{$_} for (
        qw( dbh login favicon stylesheet titlebar password vc header ),
        grep { /^_/ and $_ ne '__action' } keys %$self
        );
    $form->{__action} ||= $self->{__action}; # default to old action if not set
    $form->{script} = $script;

    my %myconfig = %{ LedgerSMB::User->fetch_config( $form ) };
    if ( !$form->{dbh} and ( $script ne 'admin.pl' ) ) {
        $form->db_init( \%myconfig );
    }

    $lsmb_legacy::form = $form;
    require "old/bin/$script";

    my $ref = qualify_to_ref $form->{__action}, 'lsmb_legacy';
    &{ *{$ref} };

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

        if (defined $_ && $ordinal->{ $a[$_] }) {
              $a[0] = "$ordinal->{$a[0]} $self->{direction}";
          }
        elsif (!defined $_ && $ordinal->{ $a[0] }) {
              $a[0] = "$ordinal->{$a[0]} $self->{direction}";
          }
        else {
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
    $myconfig = {} unless defined $myconfig;
    $amount = "" unless defined $amount;
    $places = "0" unless defined $places;
    $dash = "" unless defined $dash;
    if ($self->{money_precision}){
       $places= $self->{money_precision};
    }
    $amount = $self->parse_amount( $myconfig, $amount )
        unless ref($amount) eq 'LedgerSMB::PGNumber';
    $myconfig->{numberformat} = '1000.00' unless $myconfig->{numberformat};
    return $amount->to_output({
               places => $places,
                money => $self->{money_precision},
           neg_format => $dash,
               format => $myconfig->{numberformat},
    });
}

sub formatter_options {
    my ( $self ) = @_;

    return {
        $self->{_user}->%{ qw( dateformat numberformat ) }
    };
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

    return $amount if $amount isa 'LedgerSMB::PGNumber';
    if ( ( ! defined $amount ) or ( $amount eq '' ) ) {
        $amount = '0';
    }

    return LedgerSMB::PGNumber->from_input(
        $amount,
        { format => $myconfig->{numberformat} }
    );
}

=item $form->parse_date($myconfig, $date);

Return a LedgerSMB::PGDate containing the value of $date where $date is
formatted as $myconfig->{dateformat}.  If $date is '' or undefined, undef
is returned.

=cut

sub parse_date {
    my ( $self, $myconfig, $date ) = @_;

    return $date if $date isa 'LedgerSMB::PGDate';
    if ( ( ! defined $date ) or ( $date eq '' ) ) {
        $date = '';
    }

    return LedgerSMB::PGDate->from_input(
        $date,
        { format => $myconfig->{dateformat} }
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
        if ($types[$_] == 3 or $types[$_] ==2) {  ## no critic (ProhibitMagicNumbers) sniff
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

    foreach my $key ( @{ $replace{order}{$format} } ) {
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
        }

        if ($myconfig->{dateformat} =~ /^yy/) {
            ( $yy, $mm, $dd ) = split /\D/, $date;
        }
        elsif ($myconfig->{dateformat} =~ /^mm/) {
            ( $mm, $dd, $yy ) = split /\D/, $date;
        }
        elsif ($myconfig->{dateformat} =~ /^dd/) {
            ( $dd, $mm, $yy ) = split /\D/, $date;
        }

        $dd *= 1;
        $mm *= 1;
        $yy += 2000 if length $yy == 2;  ## no critic (ProhibitMagicNumbers) sniff

        $dd = substr("0$dd", -2);  ## no critic (ProhibitMagicNumbers) sniff
        $mm = substr("0$mm", -2);  ## no critic (ProhibitMagicNumbers) sniff
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
            $diff = $repeat * 86400;  ## no critic (ProhibitMagicNumbers) sniff
        }
        elsif ( $unit eq 'weeks' ) {
            $diff = $repeat * 604800;  ## no critic (ProhibitMagicNumbers) sniff
        }
        elsif ( $unit eq 'months' ) {
            $diff = $mm + $repeat;

            my $whole = int( $diff / 12 );  ## no critic (ProhibitMagicNumbers) sniff
            $yy += $whole;

            $mm = ( $diff % 12 );  ## no critic (ProhibitMagicNumbers) sniff
            $mm = '12' if $mm == 0;
            $yy-- if $mm == 12;  ## no critic (ProhibitMagicNumbers) sniff
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
$button->{$name}{value} is the label for the button.

=cut

my $btn = 0;

sub print_button {
    my ( $self, $button, $name ) = @_;

    my $type = $button->{$name}{type} // 'dijit/form/Button';
    $btn++;

    my $doing_toast =
        $button->{$name}{doing} ? qq|data-lsmb-doing="$button->{$name}{doing}"|
        : '';
    my $done_toast =
        $button->{$name}{done} ? qq|data-lsmb-done="$button->{$name}{done}"|
        : '';

    my $title = $button->{$name}{tooltip} || $button->{$name}{value};
    print
qq|<button data-dojo-type="$type" class="submit" type="submit" name="__action" value="$name" id="action-$name-$btn" title="$title" $doing_toast $done_toast>$button->{$name}{value}</button>\n|;
}


=item $form->generate_selects(\%myconfig);

=cut

sub generate_selects {
     my ($form, $myconfig) = @_;
     my $locale = $form->{_locale};

     $form->currencies;
     if (@{$form->{currencies}}) {
        my @currencies = @{$form->{currencies}};
        $form->{defaultcurrency} = $currencies[0];
        $form->{currency} ||= $form->{defaultcurrency};
        $form->{selectcurrency} = "";

        foreach my $currency (@currencies) {
            my $selected = ($form->{currency} eq $currency)
                ? ' selected="selected"'
                : '';
            $form->{selectcurrency} .=
                "<option value=\"$currency\"$selected>$currency</option>\n";
          }
     }

     # partsgroups
    if ( $form->{all_partsgroup} && @{ $form->{all_partsgroup} } ) {
        $form->{selectpartsgroup} = "<option></option>\n";
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
                my $selected = ($form->{language} && $form->{language} eq $value) ?
                     ' selected="selected"' : "";
            $form->{selectlanguage} .=
              qq|<option value="$value"$selected>$_->{description}</option>\n|;
        }
    }

    # sales staff
    if ($form->{all_employee} && @{ $form->{all_employee} }) {
        $form->{selectemployee} = "";
        for (@{ $form->{all_employee} }) {
            my $value = "$_->{name}--$_->{id}";
            my $selected = ($form->{employee} eq $value
                || $form->{employee} eq $_->{name}) ?
                ' selected="selected"' : "";
            $form->{selectemployee} .=
                qq|<option value="$value"$selected>$_->{name}</option>\n|;
        }
    }

    # customers/vendors
     if ($form->{vc}) {
          if ( $form->{"all_$form->{vc}"} && @{ $form->{"all_$form->{vc}"} } ) {
                $form->{"select$form->{vc}"} = "";
              my $vc = $form->{vc};
              my $search_value = $form->{$vc};
              $search_value .= qq|--$form->{"${vc}_id"}|
                  unless $search_value and $search_value =~ /--/;

                for ( @{ $form->{"all_$form->{vc}"} } ) {
                     my $value = "$_->{name}--$_->{id}";
                  my $selected = ($search_value eq $value) ?
                          ' selected="selected"' : "";
                     $form->{"select$form->{vc}"} .=
                          qq|<option value="$value"$selected>$_->{name}</option>\n|;
                }
          }
     }

     # AR/AP links
     # AR_amount_*, AP_amount_*,
     if (defined $form->{ARAP}) {
        $form->create_links(
            module => $form->{ARAP},
                                      myconfig => $myconfig,
                                      vc => $form->{vc},
                                      billing => $form->{vc} eq 'customer'
                       && $form->{type} eq 'invoice'
        ) unless defined $form->{"$form->{ARAP}_links"};

          foreach my $key ( keys %{ $form->{"$form->{ARAP}_links"} } ) {

                $form->{"select$key"} = "";
                foreach my $ref ( @{ $form->{"$form->{ARAP}_links"}{$key} } ) {
                     my $value = "$ref->{accno}--$ref->{description}";
                     $form->{"select$key"} .=
                          # change the format here, then change it below too!
                          qq|<option value="$value">$value</option>\n|;
                }
          }

        my $min_lines = $form->get_setting('min_empty') // 0;
        my $rowcount = ($form->{rowcount}//0) + $min_lines;
        if ($rowcount) {
                for my $i ( 1 .. $rowcount ) {
                     $form->{"select$form->{ARAP}_amount_$i"} =
                         $form->{"select$form->{ARAP}_amount"};
                     if ($form->{"$form->{ARAP}_amount_$i"}) {
                         $form->{"select$form->{ARAP}_amount_$i"} =~
                             s/(value="\Q$form->{"$form->{ARAP}_amount_$i"}\E")/$1 selected="selected"/;
                     }
                }
          }
     }

     # formats
    $form->{selectformat} =
        join('',
             map {
                 my $val = lc $_;
                 qq|<option value="$val">$_|
             } $form->{_wire}->get( 'output_formatter' )->get_formats
        );

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
    return $self->get_setting( 'template_images' );
}


# Database routines used throughout

=item $form->db_init($myconfig);

Connect to the database that $myconfig is set to use and initialise the base
parameters.  The connection handle becomes $form->{dbh}
is populated.  The connection initiated has autocommit disabled.

=cut


sub db_init {
    my ( $self, $dbh, $myconfig ) = @_;

    $self->{dbh} = $dbh;
    _set_datestyle($dbh);
}

sub _set_datestyle {
    my $dbh = shift;
    my $datequery =
        q{select "value" from user_preference p join users u on u.id = p.user_id
           where "name" = 'dateformat' and username = CURRENT_USER};
    my $date_sth = $dbh->prepare($datequery);
    $date_sth->execute;
    my ($datestyle) = $date_sth->fetchrow_array;
    my %date_query = (
        'mm/dd/yyyy' => 'set DateStyle to \'SQL, US\'',
        'mm-dd-yyyy' => 'set DateStyle to \'POSTGRES, US\'',
        'dd/mm/yyyy' => 'set DateStyle to \'SQL, EUROPEAN\'',
        'dd-mm-yyyy' => 'set DateStyle to \'POSTGRES, EUROPEAN\'',
        'dd.mm.yyyy' => 'set DateStyle to \'GERMAN\''
    );
    $dbh->do( $date_query{ $datestyle } )
        if $datestyle and $date_query{ $datestyle };
    return;
}



=item $form->is_allowed_role($rolelist)

Returns true if any roles are allowed, false otherwise.

=cut

sub is_allowed_role {
    my ($self, $rolelist) = @_;
    my $sth = $self->{dbh}->prepare('SELECT lsmb__is_allowed_role(?)');
    $sth->execute($rolelist) || die $sth->errstr;
    my ($access) = $sth->fetchrow_array;
    return $access;
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

=item $form->add_shipto($id, $is_oe);

Inserts a new location_id reference into the table new_shipto, using the
Form->{shiptolocationid} property.

$is_oe determines whether the locaation is linked with a transaction or an oe.

If $is_oe is false, the value of trans_id is $id and of oe_id is NULL.
If $is_oe is true, the value of trans_id is NULL and of oe_id is $id.

=cut

sub add_shipto {

    my ($self, $id, $is_oe) = @_;
    if (! $self->{shiptolocationid}) {
        return;
    }

    if ($is_oe) {
        $self->{dbh}->do('update oe set shipto = ? where id = ?',
                         {},
                         $self->{shiptolocationid},
                         $id)
            or die $self->{dbh}->errstr;
    }
    elsif ($self->{vc} eq 'customer') {
        $self->{dbh}->do('update ar set shipto = ? where id = ?',
                         {},
                         $self->{shiptolocationid},
                         $id)
            or die $self->{dbh}->errstr;
    }
    else {
        $self->{dbh}->do('update ap set shipto = ? where id = ?',
                         {},
                         $self->{shiptolocationid},
                         $id)
            or die $self->{dbh}->errstr;
    }
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


=item $form->get_employee();

Returns a list containing the name and id of the logged in employee.

=cut

sub get_employee {
    my ($self) = @_;

    my $query = qq|
        SELECT name, id
          FROM entity WHERE id = person__get_my_entity_id()|;

    my $sth = $self->{dbh}->prepare($query);
    $sth->execute;
    my (@a) = $sth->fetchrow_array();

    $sth->finish;

    return @a;
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
        }
        elsif ($table eq 'vendor') {
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

    $self->{"${table}number"}=$self->like(lc $self->{"${table}number"}) if $self->{"${table}number"};#added % and % for searching key vendor/customer number.

    # Vendor and Customer are now views into entity_credit_account.
    my $query = qq/
        SELECT c.*, coalesce(ecl.address, el.address) as address,
                       coalesce(ecl.city, el.city) as city,
                       coalesce(ecl.zipcode, el.zipcode) as zipcode,
                       coalesce(ecl.state, el.state) as state,
                       coalesce(ecl.country, el.country) as country,
                       e.name, e.control_code,
                       ctf.default_reportable
                  FROM entity_credit_account c
          JOIN entity e ON (c.entity_id = e.id)
             LEFT JOIN (SELECT coalesce(line_one, '')
                               || ' ' || coalesce(line_two, '') as address,
                               l.city, etl.credit_id, mail_code as zipcode,
                               state, (select short_name from country
                                        where id=l.country_id) as country
                          FROM eca_to_location etl
                          JOIN location l ON etl.location_id = l.id
                          WHERE etl.location_class = 1) ecl
                        ON (c.id = ecl.credit_id)
             LEFT JOIN (SELECT coalesce(line_one, '')
                               || ' ' || coalesce(line_two, '') as address,
                               l.city, etl.entity_id, mail_code as zipcode,
                               state, (select short_name from country
                                        where id=l.country_id) as country
                          FROM entity_to_location etl
                          JOIN location l ON etl.location_id = l.id
                          WHERE etl.location_class = 1) el
                        ON (c.entity_id = el.entity_id)
             LEFT JOIN country_tax_form ctf ON (c.taxform_id = ctf.id)
         WHERE (e.name ILIKE ? || '%'
               OR c.meta_number ILIKE ? || '%'
                       or e.name @@ plainto_tsquery(?))
                       AND coalesce(?, c.entity_class) = c.entity_class
        $where
        ORDER BY e.name/;

    unshift( @queryargs, $self->{$table}, $self->{"${table}number"} ,
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

=item $form->all_vc($myconfig, $vc, $transdate, $job);

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

=cut

sub all_vc {

    my ($self, $myconfig, $vc, $transdate, $job) = @_;
    my $ref;
    my $dbh = $self->{dbh};

    my $sth;
    $sth = $dbh->prepare('SELECT value FROM defaults WHERE setting_key = ?');

    $sth->execute('vclimit');
    ($myconfig->{vclimit}) = $sth->fetchrow_array();

    if ($vc eq 'customer'){
        $self->{vc_class} = 2;
    }
    else {
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
    }
    else {
        $where = " ec.entity_class = ?";
        push @queryargs, $self->{vc_class};
    }

    $sth = $dbh->prepare($query);

    $sth->execute(@queryargs2);

    my ($count) = $sth->fetchrow_array;

    $sth->finish;

    if ( $count < ($myconfig->{vclimit} // 0) ) {
        $self->{"${vc}_id"} //= 0;
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
        $self->{employee} //= '';
        ( $self->{employee}, $self->{employee_id} ) = split /--/, $self->{employee};
        ( $self->{employee}, $self->{employee_id} ) = $self->get_employee
          unless $self->{employee_id};
    }

    $self->get_regular_metadata($myconfig, $vc, $transdate, $job);
}

=item $form->rebuild_vc()

=cut

sub rebuild_vc {
    my ($self, $vc, $transdate, $job) = @_;

    my ($null, %myconfig);
    ( $null, $self->{employee_id} ) = split /--/, $self->{employee};
    $self->all_vc(\%myconfig, $vc, $transdate, $job);
    $self->{"select$vc"} = "";
    for ( @{ $self->{"all_$vc"} } ) {
        $self->{"select$vc"} .=
          qq|<option value="$_->{name}--$_->{id}">$_->{name}\n|;
    }
    $self->{selectprojectnumber} = "";

    1;
}


=item $form->get_regular_metadata($myconfig, $vc, $transdate, $job)

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

=cut

sub get_regular_metadata {
    my ($self, $myconfig, $vc, $transdate, $job) = @_;
    my $dbh = $self->{dbh};
    local $@;
    $transdate = $transdate->to_db if eval { $transdate->can('to_db') };
    $self->all_employees( $myconfig, $dbh, $transdate, 1 );
    $self->all_business_units( $transdate, $self->{"${vc}_id"} );
    $self->all_taxaccounts( $myconfig, $dbh, $transdate );
    $self->all_languages();
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
    my $where = '';

    my @queryargs = ();

    if ($transdate) {
        $where = qq| AND (t.validto >= ? OR t.validto IS NULL)|;
        push( @queryargs, $transdate );
    }

    if ( $self->{taxaccounts} ) {

        # rebuild tax rates
        $query = qq|SELECT t.rate, t.taxnumber
                      FROM tax t
                      JOIN account a ON (a.id = t.chart_id)
                     WHERE a.accno = ?
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
        $query .= qq| sales AND|;
    }

    $query =~ s/(WHERE|AND)$//;
    $query .= qq|) ORDER BY name|;
    my $sth = $dbh->prepare($query);
    $sth->execute(@whereargs) || $self->dberror($query);

    $self->{all_employee} = [];
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
    my $query     = q|SELECT * FROM business_unit__list_classes('1', ?)|;
    my $class_sth = $dbh->prepare($query) || $self->dberror($query);
    $class_sth->execute($module_name) || $self->dberror($query);

    $query        = q|SELECT * FROM business_unit__list_by_class(?, ?, ?, 'false')|;
    my $bu_sth    = $dbh->prepare($query) || $self->dberror($query);

    $transdate  ||= undef; # set '' to undef
    while (my $classref = $class_sth->fetchrow_hashref('NAME_lc')){
        push @{$self->{bu_class}}, $classref;
        $bu_sth->execute($classref->{id}, $transdate, $credit_id) || $self->dberror($query);
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

=item $form->all_years();

Populates the hash $form->{all_month} with a mapping between a two-digit month
number and the English month name.  Populates the list $form->{all_years} with
all years which contain transactions.

=cut

sub all_years {

    my ($self) = @_;

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

If $form->{id} is not set, check $form->{"$form->{vc}_id"}.
If $form->{id} is set,
populate the invnumber, transdate, ${vc}_id, datepaid, duedate, ordnumber,
taxincluded, currency, notes, intnotes, ${vc}, department_id, department,
oldinvtotal, employee_id, employee, language_code, ponumber,
reverse, recurring, exchangerate, and acc_trans
attributes of $form with details about the transaction $form->{id}.  All of
these attributes, save for acc_trans, are scalar; $form->{acc_trans} refers to
a hash keyed by link elements whose values are lists of references to hashes
describing acc_trans table entries corresponding to the transaction $form->{id}.
The elements in the acc_trans entry hashes are accno, description, source,
amount, memo, transdate, cleared, project_id, projectnumber, and exchangerate.

The separate_duties and currencies $form attributes are filled with values
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
    $query = qq|SELECT a.accno, a.description, array_agg(l.description) as link
                  FROM account a
                  JOIN account_link l ON a.id = l.account_id AND NOT a.obsolete
                 WHERE (l.description LIKE ? OR a.tax)
                       AND (a.id in (select acc_trans.chart_id
                                       FROM acc_trans
                                      WHERE trans_id = coalesce(?, -1))
                           OR NOT a.obsolete)
              GROUP BY a.accno, a.description
              ORDER BY accno|;

    $sth = $dbh->prepare($query);
    $self->{id} = undef if $self->{id} && $self->{id} eq '';
    $sth->execute( "%" . "$module%", $self->{id}) || $self->dberror($query);

    $self->{accounts} = "";

    while ( my $ref = $sth->fetchrow_hashref('NAME_lc') ) {
        $self->{_accno_descriptions}->{$ref->{accno}} = $ref->{description};
        my $link = $ref->{link};

        push(@$link,"${module}_tax") # there's no "${module}_tax" link; only a tax boolean
            if $tax_accounts{$ref->{accno}};

        foreach my $key ( @$link ) {
            if ( $key =~ /$module/ ) { # *all* tax accounts selected in query above
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
                a.entity_credit_account AS ${vc}_id,
                a.duedate, a.ordnumber,
                a.taxincluded, a.curr AS currency, a.notes,
                a.intnotes, ce.name AS $vc,
                a.amount_tc AS oldinvtotal,
                case when a.amount_tc = 0 then 0
                else a.amount_bc / a.amount_tc end as exchangerate,
                a.person_id as employee_id, e.name AS employee,
                c.language_code, a.ponumber, a.reverse,
                txn.approved, ctf.default_reportable,
                txn.description, a.on_hold, a.crdate,
                a.shipto as shiptolocationid, a.shipto_attn as shiptoattn,
                a.is_return, $seq,
                t.workflow_id, t.reversing, t.reversing_reference,
                t.reversed_by, t.reversed_by_reference
            FROM $arap a
            JOIN transactions txn ON a.id = txn.id
            JOIN transactions_reversal t ON t.id = a.id
            JOIN entity_credit_account c
                ON (a.entity_credit_account = c.id)
            JOIN entity ce ON (ce.id = c.entity_id)
            LEFT JOIN entity_employee er
                                   ON (er.entity_id = a.person_id)
            LEFT JOIN entity e ON (er.entity_id = e.id)
            LEFT JOIN country_tax_form ctf
                                  ON (ctf.id = c.taxform_id)
            WHERE a.id = ? AND c.entity_class =
                (select id FROM entity_class
                WHERE class ilike ?)|;
        $sth = $dbh->prepare($query) || $self->dberror($query);
        $sth->execute( $self->{id}, $self->{vc} ) || $self->dberror($query);

        $ref = $sth->fetchrow_hashref('NAME_lc');
        $self->db_parse_numeric(sth=>$sth, hashref=>$ref);

        if (!defined $ref->{approved}){
           $ref->{approved} = 0;
        }

        foreach my $key (keys %$ref) {
            $self->{$key} = $ref->{$key} unless defined $self->{$key};

        }

        $sth->finish;

    # get customer e-mail accounts
    $query = qq|SELECT * FROM eca__list_contacts(?)
                      WHERE class_id BETWEEN 12 AND ?
                UNION
                SELECT * FROM entity__list_contacts(?)
                      WHERE class_id BETWEEN 12 AND ?
                      ORDER BY class_id DESC|;
    my %id_map = (
        12 => 'email',
               13 => 'cc',
               14 => 'bcc',
               15 => 'email',
               16 => 'cc',
        17 => 'bcc'
    );
    $sth = $dbh->prepare($query);
    my $max_class = ($billing) ? 17 : 14;
    $sth->execute(
        $self->{entity_credit_account},
        $max_class,
        $self->{entity_id},
        $max_class
    ) || $self->dberror($query);

    my $ctype;
    my $billing_email = 0;

    while ( $ref = $sth->fetchrow_hashref('NAME_lc') ) {
        $ctype = $id_map{$ref->{class_id}};
        $billing_email = 1
            if $ref->{class_id} == 15;

        # If there's an explicit billing email, don't use
        # the standard email addresses; otherwise fall back to standard
        $self->{$ctype} .= ($self->{$ctype} ? ", " : "") . $ref->{contact}
            if (
                ($ref->{class_id} < 15 && ! $billing_email)
                || $ref->{class_id} >= 15
            );
    }
    $sth->finish;

        # get recurring
        $self->get_recurring($dbh);

        # get amounts from individual entries
        $query = qq|
         SELECT c.accno, c.description, a.source, a.amount_tc as amount,
                case when a.amount_tc = 0 then 0 else (a.amount_bc/a.amount_tc)::numeric end as exchangerate,
                a.memo,a.entry_id, a.transdate, a.cleared,
                                array_agg(ARRAY[bul.class_id, bul.bu_id])
                                AS bu_lines,
               (exists (select 1 from payment_links pl
                         where a.entry_id = pl.entry_id)) AS payment_line,
               approved
            FROM acc_trans a
            JOIN account c ON (c.id = a.chart_id)
                   LEFT JOIN business_unit_ac bul ON a.entry_id = bul.entry_id
            WHERE a.trans_id = ?
--          AND a.fx_transaction = '0'
                        GROUP BY c.accno, c.description, a.source, a.amount_tc,
                           a.amount_bc, a.memo,a.entry_id, a.transdate, a.cleared
            ORDER BY transdate|;

        $sth = $dbh->prepare($query);
        $sth->execute( $self->{id} ) || $self->dberror($query);

        my $fld = ( $vc eq 'customer' ) ? 'buy' : 'sell';

        # store amounts in {acc_trans}{$key} for multiple accounts
        while ( my $ref = $sth->fetchrow_hashref('NAME_lc') ) {
            $self->db_parse_numeric(sth=>$sth, hashref=>$ref);#tshvr

            for my $aref (@{$ref->{bu_lines}}){
                if ($aref && $aref->[0]) {
                    $ref->{"b_unit_$aref->[0]"} = $aref->[1];
                }
            }

            if ($self->{reverse}){
                $ref->{amount} *= -1;
            }

            push @{ $self->{acc_trans}{ $xkeyref{ $ref->{accno} } } }, $ref;
        }

        $sth->finish;
    }

    for (qw(separate_duties curr lock_description)) {
        if ($_ eq 'current_date') {
            $query = qq| select $_|;
        }
        else {
            $query = qq|
                SELECT value FROM defaults
                 WHERE setting_key = '$_'|;
        }

        $sth = $dbh->prepare($query) || $self->dberror($query);
        $sth->execute || $self->dberror($query);

        ($val) = $sth->fetchrow_array();
        if ( $_ eq 'curr' ) {
            $self->{defaultcurrency} = $val;
        }
        else {
            $self->{$_} = $val;
        }

        $sth->finish;
    }
    $self->currencies;

    if (!$self->{id} && !$self->{transdate}){
        $self->{transdate} = $self->{current_date};
    }

    $self->all_vc(
        $myconfig,
        $vc,
        $self->{transdate},
        $job
    );
}

=item $form->currencies

=cut

sub currencies {
    my ($self) = @_;

    return $self->{currencies} if ref $self->{currencies};

    $self->{defaultcurrency} = $self->get_setting('curr');
    my $dbh = $self->{dbh};
    my $query = "select curr from currency";
    my $sth = $dbh->prepare($query);
    $sth->execute || $self->dberror($query);
    my @curr = sort grep { ! ($_ eq $self->{defaultcurrency}) }
               map { $_->[0] } @{$sth->fetchall_arrayref()};
    return $self->{currencies} = [
        $self->{defaultcurrency}, (@curr) ];
}

=item $form->get_setting($setting_name)

Looks up the value in the defaults table and returns it.

=cut

sub get_setting {
    my ($self, $setting) = @_;
    my $query = 'select * from setting_get(?)';
    my $sth = $self->{dbh}->prepare($query) or $self->dberror($query);
    $sth->execute($setting) or $self->dberror($query);
    my $ref = $sth->fetchrow_hashref('NAME_lc') or $self->dberror($query);
    return $ref->{value};
}

=item $form->is_closed( $transdate )

Returns true when $transdate is in a closed period.

=cut


sub is_closed {
    my ($self, $transdate) = @_;

    return '' if not $transdate;

    my $query = 'select ? <= max(end_date) from account_checkpoint';
    my $sth = $self->{dbh}->prepare($query)
        or $self->dberror($query);
    $transdate = $transdate->to_db() if ref $transdate;
    $sth->execute($transdate) or $self->dberror($query);
    my ($is_closed) = $sth->fetchrow_array;
    die $self->dberror($query) if $sth->err != 0;

    return $is_closed;
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

        }
        else {
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
        @queryargs = (
            $thisdate,
            $dateformat,
            sprintf('%d days', $days)
        );
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
        for (@{$flds}) {
            $self->{"${_}_$i"} = $new->[$j]->{$_}
        }
    }

    # delete empty rows
    foreach my $i ($count + 1 .. $numrows) {
        for (@{$flds}) {
            delete $self->{"${_}_$i"}
        }
    }
}

=item $form->get_partsgroup([$p]);

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

=cut

sub get_partsgroup {

    my ($self, $p) = @_;
    my $dbh = $self->{dbh};

    my $query = qq|SELECT DISTINCT pg.id, pg.partsgroup
                     FROM partsgroup pg
                     JOIN parts p ON (p.partsgroup_id = pg.id)|;

    my $where = '';
    my $sortorder = "partsgroup";

    if ( $p->{searchitems} ) {
        if ( $p->{searchitems} eq 'part' ) {
            $where = qq| WHERE (p.inventory_accno_id > 0
                                AND p.income_accno_id > 0)|;
        }
        elsif ($p->{searchitems} eq 'service') {
            $where = qq| WHERE p.inventory_accno_id IS NULL|;
        }
        elsif ($p->{searchitems} eq 'assembly') {
            $where = qq| WHERE p.assembly = '1'|;
        }
        elsif ($p->{searchitems} eq 'labor') {
            $where =
                qq| WHERE p.inventory_accno_id > 0 AND p.income_accno_id IS NULL|;
        }
        elsif ($p->{searchitems} eq 'nolabor') {
            $where = qq| WHERE p.income_accno_id > 0|;
        }
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
            LEFT JOIN partsgroup_translation t ON (t.trans_id = pg.id
                AND t.language_code = ?)|;
        @queryargs = (
            $p->{language_code}
        );
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
    $sth->execute(
        $self->{id}
    ) || $self->dberror($query);

    for (qw(email print)) {
        $self->{"recurring$_"} = ""
    }

    while ( my $ref = $sth->fetchrow_hashref('NAME_lc') ) {

        for (keys %$ref) {
            $self->{"recurring$_"} = $ref->{$_}
        }

        $self->{recurringemail} .= "$ref->{emaila}:";
        $self->{recurringprint} .= "$ref->{printa}:";

        for (qw(emaila printa)) {
            delete $self->{"recurring$_"}
        }
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

        $self->{recurringreference} = $self->escape(
            $self->{recurringreference},
            1
        );
        $self->{recurringmessage} = $self->escape(
            $self->{recurringmessage},
            1
        );
        for (
            qw(reference startdate repeat unit howmany
            payment print email message)
        ) {
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
    $sth->execute(
        $self->{id}
    ) || $self->dberror($query);

    $query = qq|DELETE FROM recurringprint
                 WHERE id = ?|;

    $sth = $dbh->prepare($query) || $self->dberror($query);
    $sth->execute(
        $self->{id}
    ) || $self->dberror($query);

    $query = qq|DELETE FROM recurring
                 WHERE id = ?|;

    $sth = $dbh->prepare($query) || $self->dberror($query);
    $sth->execute(
        $self->{id}
    ) || $self->dberror($query);

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

        for (qw(reference message)) {
            $s{$_} = $self->unescape($s{$_})
        }

        for (qw(repeat howmany payment)) {
            $s{$_} *= 1
        }

        # calculate enddate
        my $advance = $s{repeat} * ( $s{howmany} - 1 );

        $query = qq|SELECT (?::date + interval '$advance $s{unit}')|;

        my ($enddate) = $dbh->selectrow_array(
            $query,
            undef,
            $s{startdate}
        );

        # calculate nextdate
        $query = qq|
            SELECT current_date - ?::date AS a,
                ?::date - current_date AS b|;

        $sth = $dbh->prepare($query) || $self->dberror($query);
        $sth->execute(
            $s{startdate},
            $enddate
        ) || $self->dberror($query);
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
                ($nextdate) = $dbh->selectrow_array(
                    $query,
                    undef,
                    $s{startdate}
                ) || $self->dberror($query);
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
            $self->{id},
            $s{startdate},
            $enddate,
            $nextdate,
            "$s{repeat} $s{unit}",
            $s{howmany},
            $s{payment}
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
                $sth->execute(
                    $self->{id},
                    $p[$i],
                    $p[ $i + 1 ],
                    $s{message}
                ) || $self->dberror($query);
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
                $sth->execute(
                    $self->{id},
                    $p[$i],
                    $p[ $i + 1 ],
                    $p
                ) || $self->dberror($query);
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
    $sth->execute(
        $self->{intnotes},
        $self->{id}
    ) || $self->dberror($query);
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
              $self->{setting_sequence},
              $self
        );
    }

    my $dbh = $self->{dbh};

    my $var = $dbh->selectrow_array('select setting_increment(?)', {}, $fld);
    return $var;
}

=item should_update_defaults(fldname)

This should be used instead of direct tests, and checks for a sequence selected.

=cut

sub should_update_defaults {
    my ($self, $fldname) = @_;

    my $gapless_ar = LedgerSMB::Setting->new(dbh => $self->{dbh})
        ->get('gapless_ar');
    return 0 if $gapless_ar and ($fldname eq 'invnumber');

    if (!$self->{$fldname}){
       return 1;
    }

    if (!$self->{setting_sequence}){
        return 0;
    }

    my $sequence = LedgerSMB::Setting::Sequence->get(
        $self->{setting_sequence}
    );
    return 1 unless $sequence->accept_input;
    return 0;
}

=item $form->db_prepare_vars(var1, var2, ..., varI<n>)

Undefines $form->{varI<m>}, 1 <= I<m> <= I<n>, iff $form-<{varI<m> is both
false and not "0".

=cut



# New block of code to get control code from batch table


sub get_batch_control_code {

    my ( $self, $dbh, $batch_id) = @_;

    my ($query,$sth,$control);


    if ( !$dbh ) {
        $dbh = $self->{dbh};
    }

    $query=qq|select control_code from batch where id=?|;
    $sth=$dbh->prepare($query) || $self->dberror($query);
    $sth->execute(
        $batch_id
    ) || $self->dberror($query);
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
    $sth->execute(
        $batch_id
    ) || $self->dberror($query);
    $desc=$sth->fetchrow();
    $sth->finish();
    return $desc;

}

=item sequence_dropdown(setting_key, readonly)

This function returns the HTML code for a dropdown box for a given setting
key.  It is not generally to be used with code on new templates.

=cut

sub sequence_dropdown{
    my ($self, $setting_key, $readonly) = @_;
    return undef if $self->{id} and ($setting_key ne 'sinumber');
    my @sequences = LedgerSMB::Setting::Sequence->list($setting_key);
    $readonly = $readonly ? 'readonly="readonly"' : '';
    my $retval = qq|<select data-dojo-type="dijit/form/Select" name='setting_sequence' class='sequence' $readonly>\n|;
    $retval .= qq|<option></option>|;

    for my $seq (@sequences){
        my $selected = '';
        my $label = $seq->label;
        $selected = "selected='selected'"
            if $self->{setting_sequence} eq $label;
        $retval .= qq|<option value='$label' $selected>$label</option>\n|;
    }

    $retval .= "</select>";
    if (@sequences){
        return $retval;
    }
    else {
        return '';
    }
}
#end decrysiption

1;


=back

