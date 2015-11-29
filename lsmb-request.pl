
sub get_script {
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

sub get_locale {
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
$ENV{SCRIPT_NAME} =~ m/([^\/\\]*.pl)\?*.*$/;
my $script = $1;
$script = '' unless defined $script;


sub app_initialize {
    LedgerSMB::App_State->cleanup();

    Log::Log4perl::init(\$LedgerSMB::Sysconfig::log4perl_config);
    $logger = Log::Log4perl->get_logger('LedgerSMB::Handler');
    $logger->debug("Begin");

}


sub request_instantiate {
    my $request;

    $logger->debug("getting new LedgerSMB");

    my $request = new LedgerSMB;

    $logger->debug("Got \$request=$request");
    $logger->trace("\$request=".Data::Dumper::Dumper($request));

    $request->{action} = '__default' if (!$request->{action});

    return $request;
}

#   warn $script, $requestl

sub call_script {
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

sub request_cleanup {
    my ($request) = @_;

# Prevent flooding the error logs with undestroyed connection warnings
    $request->{dbh}->disconnect()
        if defined $request->{dbh};
    $logger->debug("End");
}


&app_initialize();

my $request = request_instantiate();

my $locale = get_locale($request);
$request->{_locale} = $locale;



my $script = get_script($locale, $request);

$logger->debug("calling $script");
LedgerSMB::App_State::DBH->commit() if LedgerSMB::App_State::DBH;
&call_script( $script, $request, $locale);
$logger->debug("after calling script=$script action=$request->{action} "
               . "\$request->{dbh}=$request->{dbh}");


&request_cleanup();



1;
