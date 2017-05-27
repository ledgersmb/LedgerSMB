package LedgerSMB::PSGI;

=head1 NAME

LedgerSMB::PSGI - PSGI application routines for LedgerSMB

=head1 SYNOPSIS

 use LedgerSMB::PSGI;
 my $app = LedgerSMB::PSGI->get_app();

=cut

use strict;
use warnings;

use LedgerSMB;
use LedgerSMB::App_State;
use LedgerSMB::Auth;

use CGI::Emulate::PSGI;
use Module::Runtime qw/ use_module /;
use Try::Tiny;

# To build the URL space
use Plack::Builder;
use Plack::Request;
use Plack::App::File;
use Plack::Middleware::ConditionalGET;
use Plack::Builder::Conditionals;


local $@; # localizes just for initial load.
eval { require LedgerSMB::Template::LaTeX; };

=head1 FUNCTIONS

=over

=item old_app

Returns a 'PSGI app' which handles requests for the 'old-code' scripts in old/bin/

=cut

sub old_app {
    return CGI::Emulate::PSGI->handler(
        sub {
            my $uri = $ENV{REQUEST_URI};
            $uri =~ s/\?.*//;
            $ENV{SCRIPT_NAME} = $uri;

            _run_old();
        });
}


=item psgi_app

Implements a PSGI application for the purpose of calling the entry-points
in LedgerSMB::Scripts::*.

=cut

sub _internal_server_error {
    my ($msg, $title, $company, $dbversion) = @_;

    $title //= 'Error!';
    my @body_lines = ( '<html><body>',
                       qq|<h2 class="error">Error!</h2>|,
                       "<p><b>$msg</b></p>" );
    push @body_lines, "<p>dbversion: $dbversion, company: $company</p>"
        if $company || $dbversion;

    push @body_lines, '</body></html>';

    return [ 500,
             [ 'Content-Type' => 'text/html; charset=UTF-8' ],
             \@body_lines ];
}


sub psgi_app {
    my $env = shift;

    my $auth = LedgerSMB::Auth::factory($env);
    my $script_name = $env->{SCRIPT_NAME};
    $script_name =~ m/([^\/\\\?]*)\.pl$/;
    my $module = "LedgerSMB::Scripts::$1";
    my $script = "$1.pl";

    my $psgi_req = Plack::Request->new($env);
    my $request = LedgerSMB->new($psgi_req->parameters, $script,
                                 $env->{QUERY_STRING},
                                 $psgi_req->uploads, $psgi_req->cookies,
                                 $auth);
    $request->{action} ||= '__default';
    my $locale = $request->{_locale};
    $LedgerSMB::App_State::Locale = $locale;

    $request->{_script_handle} = $module;

    return _internal_server_error('No workflow module specified!')
        unless $module;

    return _internal_server_error("Unable to open module $module : $! : $@")
        unless use_module($module);

    my $action = $module->can($request->{action});
    return _internal_server_error("Action Not Defined: $request->{action}")
        unless $action;

    my ($status, $headers, $body);
    try {
        my $clear_session_actions =
            $module->can('clear_session_actions');

        if ($clear_session_actions
            && grep { $_ eq $request->{action} }
                    $clear_session_actions->() ) {
            $request->clear_session;
        }
        if (! $module->can('no_db')) {
            my $no_db = $module->can('no_db_actions');

            if (!$no_db
                || ( $no_db && ! grep { $_ eq $request->{action} } $no_db->())) {
                if (! $request->_db_init()) {
                    ($status, $headers, $body) =
                        ( 401,
                          [ 'Content-Type' => 'text/plain; charset=utf-8',
                            'WWW-Authenticate' => 'Basic realm=LedgerSMB' ],
                          [ 'Please enter your credentials' ]
                        );
                    return; # exit 'try' scope
                }
                if (! $request->verify_session()) {
                    ($status, $headers, $body) =
                        ( 303, # Found, GET other
                          [ 'Location' => 'login.pl?action=logout&reason=timeout' ],
                          [] );
                    return; # exit 'try' scope
                }
                $request->initialize_with_db();
            }
        }

        $LedgerSMB::App_State::DBH = $request->{dbh};
        ($status, $headers, $body) = @{&$action($request)};

        $request->{dbh}->commit if defined $request->{dbh};
        LedgerSMB::App_State->cleanup();
    }
    catch {
        my $error = $_;
        eval {
            $LedgerSMB::App_State::DBH->rollback
                if ($LedgerSMB::App_State::DBH && $_ eq 'Died');
        };
        eval { LedgerSMB::App_State->cleanup(); };
        if ($error !~ /^Died at/) {
            ($status, $headers, $body) =
                @{_internal_server_error($_, 'Error!',
                                         $request->{dbversion},
                                         $request->{company})};
        }
    };


    my $path = $env->{SCRIPT_NAME};
    $path =~ s|[^/]*$||g;
    my $secure = ($env->{SERVER_PROTOCOL} eq 'https') ? '; Secure' : '';
    push @$headers,
         ( 'Set-Cookie' =>
           qq|$request->{'request.download-cookie'}=downloaded; path=$path$secure| )
        if $request->{'request.download-cookie'};
    push @$headers,
         ( 'Set-Cookie' =>
           qq|$request->{_new_session_cookie_value}; path=$path$secure| )
        if $request->{_new_session_cookie_value};
    return [ $status, $headers, $body ];
}

sub _run_old {
    if (my $cpid = fork()){
       wait;
    } else {
       do 'old/bin/old-handler.pl';
       exit;
    }
    return;
}

=item setup_url_space(development => $boolean, coverage => $boolean)

Sets up the URL space for the PSGI app, pointing various URLs at the
appropriate PSGI handlers/apps.

=cut

sub setup_url_space {
    my %args = @_;
    my $coverage = $args{coverage};
    my $development = $args{development};
    my $old_app = old_app();
    my $psgi_app = \&psgi_app;

    return builder {
        enable match_if path(qr!.+\.(css|js|png|ico|jp(e)?g|gif)$!),
            'ConditionalGET';

        enable 'Plack::Middleware::Pod',
             path => qr{^/pod/},
             root => './',
             pod_view => 'Pod::POM::View::HTMl' # the default
                 if $development;

        # not using @LedgerSMB::Sysconfig::scripts: it has not only entry-points
        mount "/$_.pl" => $old_app
            for ('aa', 'am', 'ap', 'ar', 'gl', 'ic', 'ir', 'is', 'oe', 'pe');

        mount "/$_" => $psgi_app
            for  (@LedgerSMB::Sysconfig::newscripts);

        mount '/stop.pl' => sub { exit; }
            if $coverage;

        enable sub {
            my $app = shift;

            return sub {
                my $env = shift;

                return [ 302,
                         [ Location => '/login.pl' ],
                         [ '' ] ]
                             if $env->{PATH_INFO} eq '/';

                return $app->($env);
            }
        };

        mount '/' => Plack::App::File->new( root => 'UI' )->to_app;
    };

}




=back

=cut

1;
