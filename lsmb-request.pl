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

use LedgerSMB::User;
use LedgerSMB;
use LedgerSMB::Locale;
use Data::Dumper;
use LedgerSMB::Log;
use LedgerSMB::CancelFurtherProcessing;
use strict;

my $logger = Log::Log4perl->get_logger('');

$logger->debug("Begin lsmb-request.pl");

# for custom preprocessing logic
eval { require "custom.pl"; };

$logger->debug("lsmb-request.pl: getting request");

my $request = new LedgerSMB;

$logger->debug("lsmb-request.pl: Got request");

$request->{action} = '__default' if (!$request->{action});

$ENV{SCRIPT_NAME} =~ m/([^\/\\]*.pl)\?*.*$/;
my $script = $1;

my $locale;

if ($request->{_user}){
    $locale =  LedgerSMB::Locale->get_handle($request->{_user}->{language});
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

# Prevent flooding the error logs with undestroyed connection warnings
$request->{dbh}->disconnect()
    if defined $request->{dbh};
$logger->debug("End lsmb-request.pl");


sub call_script {
  my $script = shift @_;
  my $request = shift @_;

  try {        
    $request->{script} = $script;
    eval { require "scripts/$script" } 
      || $request->error($locale->text('Unable to open script') . ": scripts/$script : $!");
    $script =~ s/\.pl$//;
    $script = "LedgerSMB::Scripts::$script";
    $request->{_script_handle} = $script;
    $script->can($request->{action}) 
      || $request->error($locale->text("Action Not Defined: ") . $request->{action});
    $script->can( $request->{action} )->($request);
  }
  catch CancelFurtherProcessing with {
    my $ex = shift;
  };
}
1;
