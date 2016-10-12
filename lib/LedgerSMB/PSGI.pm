package LedgerSMB::PSGI;

=head1 NAME

LedgerSMB::PSGI - PSGI application routines for LedgerSMB

=head1 SYNOPSIS

 use LedgerSMB::PSGI;
 my $app = LedgerSMB::PSGI->get_app();

=cut

use strict;
use warnings;

# Preloads
use LedgerSMB;
use LedgerSMB::Form;
use LedgerSMB::Sysconfig;
use LedgerSMB::Template;
use LedgerSMB::Template::HTML;
use LedgerSMB::Locale;
use LedgerSMB::File;
use LedgerSMB::Scripts::login;
use LedgerSMB::PGObject;
use Try::Tiny;

use CGI::Emulate::PSGI;
use Module::Runtime qw/ use_module /;
# use Carp::Always;

local $@; # localizes just for initial load.
eval { require LedgerSMB::Template::LaTeX; };
$ENV{GATEWAY_INTERFACE}="cgi/1.1";

=head1 FUNCTIONS

=over

=item rest_app

Returns a 'PSGI app' which handles GET/POST requests for the RESTful services

=cut

sub rest_app {
   return CGI::Emulate::PSGI->handler(
     sub {
       do 'bin/rest-handler.pl';
    });
}

=item old_app

Returns a 'PSGI app' which handles requests for the 'old-code' scripts in bin/

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

    return [ 500,
             [ 'Content-Type' => 'text/html' ],
             [ '<html><body><h1>No workflow script specified!</h1></body></html>' ]
        ]
                 unless $script;

    return [ 500,
             [ 'Content-Type' => 'text/html; charset=utf-8' ],
             [ "<html><body><h1>Unable to open script $script : $! : $@</h1></body></html>" ]
        ]
        unless use_module($script);

    my $action = $script->can($request->{action});
    return [ 500,
             [ 'Content-Type' => 'text/html; charset=utf-8' ],
             [ "<html><body><h1>Action Not Defined: $request->{action}</h1></body></html>" ]
        ]
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
        eval {
            LedgerSMB::App_State->cleanup();
        };
        if ($error !~ /^Died at/) {
            ($status, $headers, $body) =
                 ( 500,
                   [ 'Content-Type' => 'text/html; charset=utf-8' ],
                   [ qq|<html>
<body><h2 class="error">Error!</h2> <p><b>$_</b></p>
<p>dbversion: $request->{dbversion}, company: $request->{company}</p>
</body>
</html>
| ]
                 );
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
       do 'bin/old-handler.pl';
       exit;
    }
}

=back

=cut

1;
