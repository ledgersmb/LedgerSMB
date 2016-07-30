package LedgerSMB::PSGI;

=head1 NAME

LedgerSMB::PSGI - PSGI application routines for LedgerSMB

=head1 SYNOPSIS

 use LedgerSMB::PSGI;
 my $app = LedgerSMB::PSGI->get_app();

=cut

use strict;
use warnings;
our $VERSION = '1.5';

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

local $@; # localizes just for initial load.
eval { require LedgerSMB::Template::LaTeX; };
$ENV{GATEWAY_INTERFACE}="cgi/1.1";

my $logger;

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


=item new_app

Returns a 'PSGI app' which handles requests for the 'new code' entry points
in LedgerSMB::Scripts::*

=cut


sub new_app {
   return CGI::Emulate::PSGI->handler(
        sub {
           my $uri = $ENV{REQUEST_URI};
           $ENV{SCRIPT_NAME} = $uri;
           my $script = $uri;
           $ENV{SCRIPT_NAME} =~ s/\?.*//;
           $script =~ s/.*[\\\/]([^\\\/\?=]+\.pl).*/$1/;

           _run_new($script);
       });
}

sub _run_old {
    if (my $cpid = fork()){
       wait;
    } else {
       do 'bin/old-handler.pl';
       exit;
    }
}

######## SECTION OF HELPERS FROM lsmb_request.pl
# Could use some cleanup but I think we want it eventually to just go away.

sub _get_script {
    my ($locale, $request) = @_;

    $ENV{SCRIPT_NAME} =~ m/([^\/\\]*.pl)\?*.*$/;
    my $script = $1;
    $logger->debug("\$ENV{SCRIPT_NAME}=$ENV{SCRIPT_NAME} "
                   . "\$request->{action}=$request->{action} "
                   . "\$script=$script");

    if (!$script){
        $request->error($locale->text('No workflow script specified'));
    }

    return $script;
}

sub _get_locale {
    my ($request) = @_;
    my $locale;

    if ($request->{_user}){
        $LedgerSMB::App_State::User = $request->{_user};
        $locale =  LedgerSMB::Locale->get_handle($request->{_user}->{language});
        $LedgerSMB::App_State::Locale = $locale;
    } else {
        $locale =
            LedgerSMB::Locale->get_handle( $LedgerSMB::Sysconfig::language );
        $request->error( __FILE__ . ':' . __LINE__ .
                         ": Locale ($LedgerSMB::Sysconfig::language) "
                         . "not loaded: $!\n"
            ) unless $locale;
        $LedgerSMB::App_State::Locale = $locale;
    }

    return $locale;
}


sub _app_initialize {
    LedgerSMB::App_State->cleanup();

    Log::Log4perl::init(\$LedgerSMB::Sysconfig::log4perl_config);
    $logger = Log::Log4perl->get_logger('LedgerSMB::Handler');
    $logger->debug("Begin");
}

sub _request_instantiate {
    $logger->debug("getting new LedgerSMB");

    my $request = new LedgerSMB;

    $logger->debug("Got \$request=$request");
    $logger->trace("\$request=".Data::Dumper::Dumper($request));

    $request->{action} = '__default' if (!$request->{action});

    return $request;
}


sub _call_script {
  my $script = shift @_;
  my $request = shift @_;
  my $locale = shift @_;

  try {
    $request->{script} = $script;
    $script =~ s/\.pl$//;
    $script = "LedgerSMB::Scripts::$script";
    $request->{_script_handle} = $script;

    eval "require $script;"
      || die $locale->text('Unable to open script') .
                          ": $script : $!: $@";

    my @no_db_actions =
        $script->can('no_db_actions')->()
        if $script->can('no_db_actions');
    my $no_db = 0;

    foreach my $action (@no_db_actions) {
        $no_db = 1
            if $action eq $request->{action};
    }

    if (! ($no_db || $script->can('no_db'))) {
        $request->_db_init();
        $request->initialize_with_db();
    }

    $script->can($request->{action})
      || die $locale->text("Action Not Defined: ") . $request->{action};

    $script->can( $request->{action} )->($request);
    $request->{dbh}->commit if defined $request->{dbh};
    LedgerSMB::App_State->cleanup();
  }
  catch {
      # We have an exception here because otherwise we always get an exception
      # when output terminates.  A mere 'die' will no longer trigger an
      # automatic error, but die 'foo' will map to $request->error('foo')
      # -- CT
     $LedgerSMB::App_State::DBH->rollback if ($LedgerSMB::App_State::DBH and $_ eq 'Died');
     LedgerSMB::App_State->cleanup();
     $request->_error($_) unless $_ =~ /^Died at/;
  };
}

sub _request_cleanup {
    my ($request) = @_;

# Prevent flooding the error logs with undestroyed connection warnings
    $request->{dbh}->disconnect()
        if defined $request->{dbh};
    $logger->debug("End");
}

#### END HELPERS SECTION

sub _run_new {
    my ($script) = @_;
    if (-f 'bin/lsmb-request.pl'){
        try {

            $ENV{SCRIPT_NAME} =~ m/([^\/\\]*.pl)\?*.*$/;
            my $script = $1;
            $script = '' unless defined $script;
            _app_initialize();

            my $request = _request_instantiate();

            my $locale = _get_locale($request);
            $request->{_locale} = $locale;

            $script = _get_script($locale, $request);

            $logger->debug("calling $script");
            LedgerSMB::App_State::DBH->commit() if LedgerSMB::App_State::DBH;
            _call_script( $script, $request, $locale);
            $logger->debug("after calling script=$script action=$request->{action} "
                  . "\$request->{dbh}=$request->{dbh}");


            _request_cleanup();



        }
        catch {
            # simple 'die' statements are request terminations
            # so we don't want to cause a 500 ISE to be returned
            die $_
                unless $_ =~ /^Died at/;
        }
    }
}

=back

=cut

1;
