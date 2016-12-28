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

use CGI::Emulate::PSGI;
use Module::Runtime qw/ use_module /;
use Try::Tiny;

# To build the URL space
use Plack::Builder;
use Plack::App::File;
use Plack::Middleware::Redirect;
use Plack::Middleware::ConditionalGET;
use Plack::Builder::Conditionals;


local $@; # localizes just for initial load.
eval { require LedgerSMB::Template::LaTeX; };

# Some old code depends on this variable having been defined
$ENV{GATEWAY_INTERFACE}="cgi/1.1";

=head1 FUNCTIONS

=over

=item rest_app

Returns a 'PSGI app' which handles GET/POST requests for the RESTful services

=cut

sub rest_app {
   return CGI::Emulate::PSGI->handler(
     sub {
       do 'old/bin/rest-handler.pl';
    });
}

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

    # Taken from CGI::Emulate::PSGI
    #no warnings;
    local *STDIN = $env->{'psgi.input'};
    my $environment = {
        GATEWAY_INTERFACE => 'CGI/1.1',
        HTTPS => ( ( $env->{'psgi.url_scheme'} eq 'https' ) ? 'ON' : 'OFF' ),
        SERVER_SOFTWARE => "CGI-Emulate-PSGI",
        REMOTE_ADDR     => '127.0.0.1',
        REMOTE_HOST     => 'localhost',
        REMOTE_PORT     => int( rand(64000) + 1000 ),    # not in RFC 3875
        ( map { $_ => $env->{$_} }
          grep { !/^psgix?\./ && $_ ne "HTTP_PROXY" } keys %$env )
    };
    # End of CGI::Emulate::PSGI

    local %ENV = ( %ENV, %$environment );

    my $request = LedgerSMB->new();
    $request->{action} ||= '__default';
    my $locale = $request->{_locale};
    $LedgerSMB::App_State::Locale = $locale;

    $ENV{SCRIPT_NAME} =~ m/([^\/\\\?]*)\.pl$/;
    my $script = "LedgerSMB::Scripts::$1";
    $request->{_script_handle} = $script;

    return _internal_server_error('No workflow script specified!')
        unless $script;

    return _internal_server_error("Unable to open script $script : $! : $@")
        unless use_module($script);

    my $action = $script->can($request->{action});
    return _internal_server_error("Action Not Defined: $request->{action}")
        unless $action;

    my ($status, $headers, $body);
    try {
        if (! $script->can('no_db')) {
            my $no_db = $script->can('no_db_actions');

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

    push @$headers, ( 'Set-Cookie' =>
                      $request->{'request.download-cookie'} . '=downloaded' )
        if $request->{'request.download-cookie'};
    push @$headers, ( 'Set-Cookie' =>
                      $request->{_new_session_cookie_value} )
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

    builder {
        enable 'Redirect', url_patterns => [
            qr/^\/?$/ => ['/login.pl',302]
            ];

        enable match_if path(qr!.+\.(css|js|png|ico|jp(e)?g|gif)$!),
            'ConditionalGET';

        enable 'Plack::Middleware::Pod',
             path => qr{^/pod/},
             root => './',
             pod_view => 'Pod::POM::View::HTMl' # the default
                 if $development;

        mount '/rest/' => rest_app();

        # not using @LedgerSMB::Sysconfig::scripts: it has not only entry-points
        mount "/$_.pl" => $old_app
            for ('aa', 'am', 'ap', 'ar', 'gl', 'ic', 'ir', 'is', 'oe', 'pe');

        mount "/$_" => $psgi_app
            for  (@LedgerSMB::Sysconfig::newscripts);

        mount '/stop.pl' => sub { exit; }
            if $coverage;

        mount '/' => Plack::App::File->new( root => 'UI' )->to_app;
    };
}




=back

=cut

1;
