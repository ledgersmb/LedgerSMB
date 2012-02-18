=head1 NAME
#!/usr/bin/perl
The LedgerSMB Request Handler

=head1 SYNOPSYS
This file receives the web request, instantiates the proper objects, and passes
execution off to the appropriate workflow scripts.  This is for use with new 
code only and should not be used with old SQL-Ledger(TM) code as it is 
architecturally dissimilar.

=head1 COPYRIGHT

Copyright (C) 2007 The LedgerSMB Core Team

This file is licensed under the GNU General Public License (GPL)  version 2 or 
at your option any later version.  A copy of the GNU GPL has been included with
this software.

=cut

package LedgerSMB::Handler;

use LedgerSMB::Sysconfig;
use Digest::MD5;
use Error qw(:try);

$| = 1;

binmode (STDIN, ':utf8');
binmode (STDOUT, ':utf8');
use LedgerSMB::User;
use LedgerSMB::App_State;
use LedgerSMB;
use LedgerSMB::Locale;
use Data::Dumper;
use LedgerSMB::Log;
use LedgerSMB::CancelFurtherProcessing;
use strict;

my $logger = Log::Log4perl->get_logger('LedgerSMB::Handler');

$logger->debug("Begin");

# for custom preprocessing logic
eval { require "custom.pl"; };

$logger->debug("getting new LedgerSMB");

my $request = new LedgerSMB;

$logger->debug("Got \$request=$request");
$logger->trace("\$request=".Data::Dumper::Dumper($request));

$request->{action} = '__default' if (!$request->{action});

$ENV{SCRIPT_NAME} =~ m/([^\/\\]*.pl)\?*.*$/;
my $script = $1;
$logger->debug("\$ENV{SCRIPT_NAME}=$ENV{SCRIPT_NAME} \$request->{action}=$request->{action} \$script=$script");

my $locale;

if ($request->{_user}){
    $LedgerSMB::App_State::User = $request->{_user};
    $locale =  LedgerSMB::Locale->get_handle($request->{_user}->{language});
    $LedgerSMB::App_State::Locale = $locale;
} else {
    $locale = LedgerSMB::Locale->get_handle( ${LedgerSMB::Sysconfig::language} )
       or $request->error( __FILE__ . ':' . __LINE__ . ": Locale not loaded: $!\n" );
}

if (!$script){
	$request->error($locale->text('No workflow script specified'));
}

$request->{_locale} = $locale;

$logger->debug("calling $script");

&call_script( $script, $request );
$logger->debug("after calling script=$script action=$request->{action} \$request->{dbh}=$request->{dbh}");

# Prevent flooding the error logs with undestroyed connection warnings
$request->{dbh}->disconnect()
    if defined $request->{dbh};
$logger->debug("End");


sub call_script {
  my $script = shift @_;
  my $request = shift @_;

  try {        
    $request->{script} = $script;
    my $scriptmod = "$script";
    $scriptmod =~ s/\.pl$//;
    my $eval_string = "require LedgerSMB::Scripts::$scriptmod;";
    #eval { require LedgerSMB::Scripts::$scriptmod; } 
    eval $eval_string
      || $request->error($locale->text('Unable to open script') . 
                          ": $scriptmod : $!"
          );
    $script =~ s/\.pl$//;
    $script = "LedgerSMB::Scripts::$script";
    $request->{_script_handle} = $script;
    $script->can($request->{action}) 
      || $request->error($locale->text("Action Not Defined: ") . $request->{action});
    $script->can( $request->{action} )->($request);
  }
  catch CancelFurtherProcessing with {
    my $ex = shift;
    $logger->debug("CancelFurtherProcessing \$ex=$ex");
  };
}
1;
