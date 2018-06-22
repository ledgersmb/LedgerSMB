
package LedgerSMB;

=head1 NAME

LedgerSMB - The Base class for many LedgerSMB objects, including DBObject.

=head1 DESCRIPTION

This module creates a basic request handler with utility functions available
in database objects (LedgerSMB::DBObject)

=head1 METHODS

=over

=item new ()

This method creates a new base request instance. It also validates the
session/user credentials, as appropriate for the run mode.  Finally, it sets up
the database connections for the user.

=item open_form()

This sets a $self->{form_id} to be used in later form validation (anti-XSRF
measure).

=item check_form()

This returns true if the form_id was associated with the session, and false if
not.  Use this if the form may be re-used (back-button actions are valid).

=item close_form()

Identical with check_form() above, but also removes the form_id from the
session.  This should be used when back-button actions are not valid.

=item is_allowed_role({allowed_roles => @role_names})

This function returns 1 if the user's roles include any of the roles in
@role_names.

=item merge ($hashref, keys => @list, index => $number);

This command merges the $hashref into the current object.  If keys are
specified, only those keys are used.  Otherwise all keys are merged.

If an index is specified, the merged keys are given a form of
"$key" . "_$index", otherwise the key is used on both sides.


=item get_relative_url

Returns the script and query string part of the URL of the GET request,
without the script path, or undef.

=cut

=item upload([$filename])

This function returns - when called without arguments - the number of
files in the upload data when called in scalar context or the names
of the files when called in list context.

Calling the function with a filename argument returns a filehandle
to the content.

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

=item initialize_with_db

This function sets up the db handle for the request

=item to_json($output)

Serializes the Perl object (hash) $output to JSON and returns the
PSGI response triplet (status, headers, body).

=item system_info($dbh)

Returns a hashref with the keys being system information sections,
each being a hashref detailing configuration items with their values.

=back



=head1 Copyright (C) 2006-2017, The LedgerSMB core team.

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

use strict;
use warnings;

use Carp;
use Encode qw(perlio_ok);
use HTTP::Headers::Fast;
use HTTP::Status qw( HTTP_OK ) ;
use JSON::MaybeXS;
use Log::Log4perl;
use PGObject;

use LedgerSMB::Sysconfig;
use LedgerSMB::App_State;
use LedgerSMB::Locale;
use LedgerSMB::User;
use LedgerSMB::Company_Config;
use LedgerSMB::Template;

our $VERSION = '1.7.0-dev';

my $logger = Log::Log4perl->get_logger('LedgerSMB');
my $json = JSON::MaybeXS->new( pretty => 1,
                               utf8 => 1,
                               indent => 1,
                               convert_blessed => 1);


sub new {
    my ($class, $cgi_args, $script_name, $query_string,
        $uploads, $cookies, $auth, $db, $company, $session_id,
        $create_session_cb, $invalidate_session_cb) = @_;
    my $self = {};
    bless $self, $class;

    (my $package,my $filename,my $line)=caller;


    # Some tests construct LedgerSMB objects without $auth argument
    # (in fact, without any arguments), so check for having an $auth
    # arg before trying to call methods on it.
    $self->{login} = $auth->get_credentials->{login} if defined $auth;
    $self->{version} = $VERSION;
    $self->{dbversion} = $VERSION;
    $self->{VERSION} = $VERSION;
    $self->{_uploads} = $uploads  if defined $uploads;
    $self->{_cookies} = $cookies  if defined $cookies;
    $self->{query_string} = $query_string if defined $query_string;
    $self->{_auth} = $auth;
    $self->{script} = $script_name;
    $self->{dbh} = $db;
    $self->{company} = $company;
    $self->{_session_id} = $session_id;
    $self->{_create_session} = $create_session_cb;
    $self->{_logout} = $invalidate_session_cb;

    $self->_process_args($cgi_args);
    $self->_set_default_locale();

    return $self;
}

sub open_form {
    my ($self) = @_;
    my @vars = $self->call_procedure(procname => 'form_open',
                              args => [$self->{_session_id}],
                              continue_on_error => 1
    );
    return $self->{form_id} = $vars[0]->{form_open};
}

# move to another module
sub check_form {
    my ($self) = @_;
    my @vars = $self->call_procedure(funcname => 'form_check',
                              args => [$self->{_session_id}, $self->{form_id}]
    );
    return $vars[0]->{form_check};
}

sub close_form {
    my ($self) = @_;
    my @vars = $self->call_procedure(funcname => 'form_close',
                              args => [$self->{_session_id}, $self->{form_id}]
    );
    delete $self->{form_id};
    return $vars[0]->{form_close};
}

sub initialize_with_db {
    my ($self) = @_;

    my $sth = $self->{dbh}->prepare(q{
            SELECT value FROM defaults
             WHERE setting_key = 'role_prefix'});
    $sth->execute;


    ($self->{_role_prefix}) = $sth->fetchrow_array;

    $sth = $self->{dbh}->prepare('SELECT check_expiration()');
    $sth->execute;
    ($self->{warn_expire}) = $sth->fetchrow_array;

    if ($self->{warn_expire}){
        $sth = $self->{dbh}->prepare('SELECT user__check_my_expiration()');
        $sth->execute;
        ($self->{pw_expires})  = $sth->fetchrow_array;
    }


    my $query = q{SELECT t.extends,
            coalesce (t.table_name, 'custom_' || extends)
            || ':' || f.field_name as field_def
        FROM custom_table_catalog t
        JOIN custom_field_catalog f USING (table_id)};
    $sth = $self->{dbh}->prepare($query);
    $sth->execute;
    my $ref;
    $self->{custom_db_fields} = {};
    while ( $ref = $sth->fetchrow_hashref('NAME_lc') ) {
        push @{ $self->{custom_db_fields}->{ $ref->{extends} } },
          $ref->{field_def};
    }

    LedgerSMB::Company_Config::initialize($self);

    $self->get_user_info;

    $self->{_locale} =
        LedgerSMB::Locale->get_handle($self->{_user}->{language})
        or $self->error(__FILE__.':'.__LINE__.": Locale not loaded: $!\n");

    $self->{stylesheet} =
        $self->{_user}->{stylesheet} unless $self->{stylesheet};

    return;
}


sub get_user_info {
    my ($self) = @_;
    $LedgerSMB::App_State::User =
        $self->{_user} =
        LedgerSMB::User->fetch_config($self);
    return $self->{_user}->{language} ||= 'en';
}

sub _set_default_locale {
    my ($self) = @_;

    my $lang = $LedgerSMB::Sysconfig::language;
    $self->{_locale}=LedgerSMB::Locale->get_handle($lang);
    $self->error( __FILE__ . ':' . __LINE__
                  . ": Locale ($lang) not loaded: $!\n" )
        unless $self->{_locale};

    return;
}

sub _process_args {
    my ($self, $args) = @_;

    for my $key (keys %$args){
        my @values = grep { defined $_ && $_ ne '' } $args->get_all($key);
        next if ! @values;

        $self->{$key} = (@values == 1) ? $values[0] : \@values;
    }
    return;
}

sub get_relative_url {
    my ($self) = @_;

    return $self->{script} .
        ($self->{query_string} ? "?$self->{query_string}" : '');
}

sub upload {
    my ($self, $name) = @_;

    if (! defined $name) {
        return map { $_->basename } $self->{_uploads}->values;
    }

    # Hash::MultiValue croaks when the key doesn't exist;
    # we want it to return C<undef> instead.
    my $tmpfname = eval { $self->{_uploads}->get_one($name)->path };
    return undef unless defined $tmpfname;

    my $headers = HTTP::Headers::Fast->new(
        Content_Type => $self->{_uploads}->get_one($name)->content_type
        );
    my $encoding = ':bytes';
    my $charset = $headers->content_type_charset;
    if ($charset) {
        if (perlio_ok $charset) {
            $encoding = ':encoding(' . $charset . ')';
        }
        else {
            die "Unsupported PerlIO encoding: $charset";
        }
    }

    open my $fh, "<$encoding", $tmpfname
        or die "Can't open uploaded temporary file $tmpfname: $!";

    my $bom_length = 0;
    if (! $charset
        && ($headers->content_is_text
            || $headers->content_is_xml)
        && -s $tmpfname >= 4) {
        sysread $fh, my $bytes, 4;
        if ("\xFF\xFE" eq substr($bytes, 0, 2)) {
            $encoding = 'UTF-16LE';
            $bom_length = 2;
        }
        elsif ("\xFE\xFF" eq substr($bytes, 0, 2)) {
            $encoding = 'UTF-16BE';
            $bom_length = 2;
        }
        elsif ("\xEF\xBB\xBF" eq substr($bytes, 0, 3)) {
            $encoding = 'UTF-8';
            $bom_length = 3;
        }
        elsif ("\x00\x00\xFE\xFF" eq $bytes) {
            $encoding = 'UTF-32LE';
            $bom_length = 4;
        }
        elsif ("\xFF\xFE\x00\x00" eq $bytes) {
            $encoding = 'UTF-32BE';
            $bom_length = 4;
        }
        sysseek $fh, 0, 0;
    }

    if ($bom_length) {
        binmode $fh, ':encoding(' . $encoding . ')';
        read($fh, my $unused, 1); # read the bom character
    }

    return $fh;
}

sub call_procedure {
    my $self = shift;
    my %args = @_;
    $args{funcschema} ||= $LedgerSMB::Sysconfig::db_namespace;
    $args{funcname} ||= $args{procname};
    $args{dbh} = LedgerSMB::App_State::DBH();
    $args{args} ||= [];
    return PGObject->call_procedure(%args);
}

# Keeping this here due to common requirements
sub is_allowed_role {
    my ($self, $args) = @_;
    my ($access) =  $self->call_procedure(
         procname => 'lsmb__is_allowed_role', args => [$args->{allowed_roles}]
    );
    return $access->{lsmb__is_allowed_role};
}

sub error {
    my ($self, $msg) = @_;
    Carp::croak $msg;
}


# Database routines used throughout

sub dberror{
   my $self = shift @_;
   my $state_error = {};
   my $locale = $LedgerSMB::App_State::Locale;
   if(! $locale){$locale=$self->{_locale};}#tshvr4
   my $dbh = $LedgerSMB::App_State::DBH;
   $state_error = {
            '42883' => $locale->text('Internal Database Error'),
            '42501' => $locale->text('Access Denied'),
            '42401' => $locale->text('Access Denied'),
            '22008' => $locale->text('Invalid date/time entered'),
            '22012' => $locale->text('Division by 0 error'),
            '22004' => $locale->text('Required input not provided'),
            '23502' => $locale->text('Required input not provided'),
            '23505' => $locale->text('Conflict with Existing Data.  Perhaps you already entered this?'),
            'P0001' => $locale->text('Error from Function:') . "\n" .
                    $dbh->errstr,
   };
   $logger->error("Logging SQL State $dbh->state, error $dbh->err, string $dbh->errstr");

   if (defined $state_error->{$dbh->state}){
       die $state_error->{$dbh->state}
           . "\n" .
          $locale->text('More information has been reported in the error logs');
   }
   die $dbh->state . ':' . $dbh->errstr;
}

sub merge {
    (my $package,my $filename,my $line)=caller;
    my ( $self, $src ) = @_;
    $logger->debug("begin caller \$filename=$filename \$line=$line");
       # Removed dbh from logging string since not used on this api call and
       # not initialized in test cases -CT
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
            $logger->trace("LedgerSMB.pm: merge setting $dst_arg to $src->{$arg}");
        }
        elsif ( !defined $dst_arg && defined $src->{$arg} )
        {
            $logger->trace("LedgerSMB.pm: merge setting \$dst_arg is undefined \$src->{\$arg} is defined $src->{$arg}");
        }
        elsif ( defined $dst_arg && !defined $src->{$arg} )
        {
            $logger->trace("LedgerSMB.pm: merge setting \$dst_arg is defined $dst_arg \$src->{\$arg} is undefined");
        }
        elsif ( !defined $dst_arg && !defined $src->{$arg} )
        {
            $logger->trace('LedgerSMB.pm: merge setting $dst_arg is undefined $src->{$arg} is undefined');
        }
        $self->{$dst_arg} = $src->{$arg};
    }
    $logger->debug("end caller \$filename=$filename \$line=$line");
    return;
}

sub to_json {
    my ($self, $output) = @_;

    my $response_data = LedgerSMB::Template::preprocess(
        $output,
        sub {return shift} # no escaping
    );

    return [
        HTTP_OK,
        [ 'Content-Type' => 'application/json; charset=UTF-8' ],
        [ $json->encode($response_data) ],
    ];
}

sub system_info {
    my ($dbh) = @_;

    return {
        system => {
            perl => $^V->stringify,
            LedgerSMB => $VERSION,
            Plack => $Plack::VERSION,
            INCLUDE_PATH => join("\n", @INC),
        }
    };
}


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2006-2018 The LedgerSMB Core Team

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;


