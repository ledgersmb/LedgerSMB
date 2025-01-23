
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

=item verify_csrf()

This method verifies the C<csrf_token> value in request parameters (held in
C<$self->{csrf_token}>) against the value in the session object.  When one is
not defined or they are not equal, this function returns a PSGI triplet to be
used as the response resulting in a 400 -- Bad Request.

When the CSRF token matches, C<undef> is returned indicating processing is to
continue.

=item open_form()

This sets a $self->{form_id} to be used in later form validation (anti-XSRF
measure).

=item close_form()

This returns true if the form_id was associated with the session, and false if
not and also removes the form_id from the
session.

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

Returns a URL-decoded string to prevent double-encoding when the URL
is round-tripped.x

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

=item system_info($dbh)

Returns a hashref with the keys being system information sections,
each being a hashref detailing configuration items with their values.

=item setting()

Accessor method and lazy initialisation for a shared LedgerSMB::Setting
instance.

Returns a reference to an initialised LedgerSMB::Setting instance.

=item all_months()

Returns hashref of localized date data with following members:

=over

=item dropdown

Month information in drop down format.

=item hashref

Month info in hashref format in 01 => January format

=back

=item all_years()

Returns hashref of localized date data with following members:

=over

=item dropdown

Month information in drop down format.

=item hashref

Month info in hashref format in 01 => January format

=back

=item enabled_languages()

Returns arrayref of hashes with the following keys:

=over

=item value

The code of the language as per the CLDR

=item text

The name of the language, translated into the user's selected language

=back

=item enabled_countries()

Returns arrayref of hashes with the following keys:

=over

=item id

The internal identifier for the country

=item short_name

The 2-leter iso code of the country

=item name

The country's full name translated into the user's selected language

=back

=item report_renderer_ui

Returns a code reference to render a report on the UI - pass as the
named argument 'renderer' to the C<LedgerSMB::Report->render> method.

  my $report = LedgerSMB::Report
  $report->render( renderer => $request->report_renderer_ui);


=item report_renderer_doc

Returns a code reference to render a report as a document - pass as the
named argument 'renderer' to the C<LedgerSMB::Report->render> method.

  my $report = LedgerSMB::Report
  $report->render( renderer => $request->report_renderer_doc);


=item render_report($report)

Renders the report as a document or UI element, depending on whether
the request's C<format> property has a non-false value.

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
use DateTime::Format::Duration::ISO8601;
use Encode qw(perlio_ok);
use HTTP::Headers::Fast;
use HTTP::Status qw( HTTP_OK HTTP_BAD_REQUEST );
use List::Util qw( pairgrep );
use Locale::CLDR;
use Locales unicode => 1;
use Log::Any;
use Math::BigFloat;
use Math::BigInt;
use PGObject;
use Plack;
use URI;
use URI::Escape;

use LedgerSMB::App_State;
use LedgerSMB::Locale;
use LedgerSMB::User;
use LedgerSMB::Company_Config;
use LedgerSMB::PSGI::Util qw( template_response );
use LedgerSMB::Setting;
use LedgerSMB::Template;

our $VERSION = '1.11.20';

my $logger = Log::Any->get_logger(category => 'LedgerSMB');
my $expiration_parser = DateTime::Format::Duration::ISO8601->new;

sub new {
    my ($class, $request, $wire) = @_;
    my $self = {};
    bless $self, $class;

    # Properties prefixed with underscore are hidden from UI templates.
    #
    # Some tests construct LedgerSMB objects without $auth argument
    # (in fact, without any arguments), so check for having an $auth
    # arg before trying to call methods on it.
    $self->{login} = $request->env->{'lsmb.session'}->{login};
    $self->{version} = $VERSION;
    $self->{dbversion} = $VERSION;
    $self->{_uploads} = $request->uploads if defined $request->uploads;
    $self->{_cookies} = $request->cookies if defined $request->cookies;
    $self->{query_string} = $request->query_string if defined $request->query_string;
    $self->{script} = $request->env->{'lsmb.script'};
    $self->{dbh} = $request->env->{'lsmb.app'};
    $self->{company} = $request->env->{'lsmb.session'}->{company};
    $self->{_session_id} = $request->env->{'lsmb.session_id'};
    $self->{_create_session} = $request->env->{'lsmb.create_session_cb'};
    $self->{_logout} = $request->env->{'lsmb.invalidate_session_cb'};
    $self->{_setting} = $request->env->{'lsmb.setting'};
    $self->{_req} = $request;
    $self->{_wire} = $wire;

    my $q = $self->{query_string} // '';
    $self->{_uri} = URI->new(
        $request->env->{'lsmb.script'} . ($q ? "?$q" : ''),
        $request->request_uri
        );

    # Initialize ourselves from parameters in $self->{_req}
    $self->_process_args;
    $self->_set_default_locale();

    return $self;
}


sub verify_csrf {
    my ($self) = @_;
    my $got = $self->{csrf_token};
    my $want = $self->{_req}->env->{'lsmb.session'}->{csrf_token};
    if (not ($got and $want and $got eq $want)) {
        $logger->debug( "CSRF have '$got'; want '$want'" );
        return [ HTTP_BAD_REQUEST,
                 [ 'Content-Type' => 'text/plain; charset=ascii' ],
                 [ 'Bad request: CSRF token failure' ] ];
    }
    return undef;
}

sub open_form {
    my ($self) = @_;
    my @vars = $self->call_procedure(procname => 'form_open',
                              args => [$self->{_session_id}],
                              continue_on_error => 1
    );
    return $self->{form_id} = $vars[0]->{form_open};
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
    my $sth;


    $sth = $self->{dbh}->prepare('SELECT check_expiration()')
        or die $self->{dbh}->errstr;
    $sth->execute or die $sth->errstr;
    ($self->{warn_expire}) = $sth->fetchrow_array;

    if ($self->{warn_expire}){
        $sth = $self->{dbh}->prepare('SELECT user__check_my_expiration()')
            or die $self->{dbh}->errstr;
        $sth->execute or die $sth->errstr;
        my ($pw_expires) = $sth->fetchrow_array;
        $self->{pw_expires} = $expiration_parser->parse_duration($pw_expires);
    }

    $self->{_company_config} =
        LedgerSMB::Company_Config::initialize($self->{dbh});

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
    LedgerSMB::App_State::set_User(
        $self->{_user} =
        LedgerSMB::User->fetch_config($self));
    return $self->{_user}->{language} ||= 'en';
}

sub _set_default_locale {
    my ($self) = @_;

    my $lang = $self->{_wire}->get( 'default_locale' )
        ->from_header( $self->{_req}->header( 'Accept-Language' ) );

    $self->{_user}->{language} = $lang;
    $self->{_locale}=LedgerSMB::Locale->get_handle($lang);
    $self->error( __FILE__ . ':' . __LINE__
                  . ": Locale ($lang) not loaded: $!\n" )
        unless $self->{_locale};

    return;
}

sub _process_args {
    my ($self) = @_;

    # Prefer body parameters over query string parameters
    # Normally, they shouldn't both be present, but there's at least a bug in
    # Safari 15 which submits query parameters, even when told not to.
    #
    # $self->{_req}->parameters values query and body parameters equally, causing
    # them to be collected into arrays when both are specified. This way, we
    # prefer one over the other instead.
    for my $args ($self->{_req}->query_parameters, $self->{_req}->body_parameters) {
        for my $key (keys %$args){
            my @values = grep { defined $_ && $_ ne '' } $args->get_all($key);
            next if ! @values;

            my $value = (@values == 1) ? $values[0] : \@values;
            next if $value eq '_!lsmb!empty!_';

            $self->{$key} = $value;
        }
    }
    return;
}

sub upload {
    my ($self, $name) = @_;

    if (! defined $name) {
        return map { $_->basename } $self->{_uploads}->values;
    }

    my $upload = $self->{_uploads}->get($name) or return undef;
    my $tmpfname = $upload->path;

    my $headers = HTTP::Headers::Fast->new(
        Content_Type => $upload->content_type
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
        else { # no BOM
            $encoding = 'UTF-8';
            $bom_length = 0;
        }
        sysseek $fh, 0, 0;
    }

    if ($encoding) {
        binmode $fh, ':encoding(' . $encoding . ')';
    }
    if ($bom_length) {
        read($fh, my $unused, 1); # read the bom character
    }

    return $fh;
}

sub call_procedure {
    my $self = shift;
    my %args = @_;
    $args{funcschema} ||= $self->{_wire}->get( 'db' )->schema;
    $args{funcname} ||= $args{procname};
    $args{dbh} = $self->{dbh};
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
   my $locale = $self->{_locale};
   my $dbh = $self->{_dbh};
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
    return;
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

sub setting {
    my ($self) = @_;

    unless($self->{_setting}) {
        $self->{dbh} or croak(
            'cannot initialise LedgerSMB::Setting object -'.
            'database handler is undefined'
        );
        $self->{_setting} = LedgerSMB::Setting->new();
        $self->{_setting}->set_dbh($self->{dbh});
    }

    return $self->{_setting};
}

sub all_months {
    my ($self) = @_;
    my $i18n = $self->{_locale};
    my $months = {
     '01' => $i18n->text('January'),
     '02' => $i18n->text('February'),
     '03' => $i18n->text('March'),
     '04' => $i18n->text('April'),
     '05' => $i18n->text('May'),
     '06' => $i18n->text('June'),
     '07' => $i18n->text('July'),
     '08' => $i18n->text('August'),
     '09' => $i18n->text('September'),
     '10' => $i18n->text('October'),
     '11' => $i18n->text('November'),
     '12' => $i18n->text('December'),
    };

    my $for_dropdown = [];
    my $as_hashref = {};
    for my $key (sort {$a cmp $b} keys %$months){
        push @$for_dropdown, {text => $months->{$key}, value => $key};
    }
    return { as_hashref => $months, dropdown=> $for_dropdown };
}

sub all_years {
    my ($self) = @_;

    my @years = $self->call_procedure(
        funcname => 'date_get_all_years'
        );

    return { as_hashref => \@years,
             dropdown => [ map { +{ text => $_->{date_get_all_years},
                                    value => $_->{date_get_all_years} }
                           } @years ] };
}

sub enabled_languages {
    my ($self) = @_;

    my $l = Locales->new( $self->{_user}->{language} );
    return [
        map {
            +{
                value => $_->{code},
                text => ucfirst($l->get_language_from_code($_->{code})
                                // $_->{description})
            }
        } $self->call_procedure(funcname => 'person__list_languages')
        ];
}

sub enabled_countries {
    my ($self) = @_;

    local $Math::BigInt::upgrade = undef;
    local $Math::BigFloat::downgrade = undef;
    my $regions = Locale::CLDR->new($self->{_user}->{language})->all_regions;
    return [
        map {
            +{
                $_->%*,
                name => $regions->{$_->{short_name}} // $_->{name}
            }
        } $self->call_procedure(funcname => 'location_list_country')
        ];
}

sub report_renderer_ui {
  my ($request) = @_;
  my $ui = $request->{_wire}->get('ui');
  my $uri = $request->{_uri}->clone;
  if (not pairgrep { $a eq 'company' } $uri->query_form) {
      $uri->query_form(
          $uri->query_form,
          company => $request->{company},
          );
  }

  return sub {
      my ($template_name, $report, $vars, $cvars) = @_;
      $vars->{REPORT_LINK} = $uri->as_string;
      $vars->{SCRIPT} = $request->{script};
      $vars->{SETTINGS} = {
          papersize    => 'letter', # default paper size when not configured
          (%{$request->{_company_config} // {}},)
      };
      $vars->{SETTINGS}->{company_name} ||= $request->{company};
      $vars->{HIDDENS} = $request->{hiddens};
      $vars->{FORM_ID} = $request->{form_id};

      return $ui->render($request, "Reports/$template_name", $vars, $cvars);
  };
}

sub report_renderer_doc {
    my ($request) = @_;
    my $renderer =
        $request->{_wire}->get( 'output_formatter' )->report_doc_renderer(
            $request->{_dbh},
            uc($request->{format}) || 'HTML',
            {
                SETTINGS => {
                     # default paper size when not configured
                    papersize    => 'letter',
                    (%{$request->{_company_config} // {}},)
                }
            });

    return sub {
        my ($template_name, $report, $vars, $cvars) = @_;

        return template_response(
            $renderer->( $template_name, $report, $vars, $cvars ),
            disposition => 'attach' );
    };
}


sub render_report {
    my ($request, $report) = @_;

    my $renderer;
    if ($request->{format}) {
        # render as (stand alone) document
        $renderer = $request->report_renderer_doc;
    }
    else {
        # render as UI element
        $renderer = $request->report_renderer_ui;
    }
    return $report->render( renderer => $renderer);
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2006-2018 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
