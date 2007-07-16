#!/usr/bin/perl
=head1 NAME
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
use LedgerSMB::Session;
use Data::Dumper;

# for custom preprocessing logic
eval { require "custom.pl"; };

$request = new LedgerSMB;
$request->{action} = '__default' if (!$request->{action});

$0 =~ m/([^\/\\]*.pl)\?*.*$/;
$script = $1;
$locale = LedgerSMB::Locale->get_handle( ${LedgerSMB::Sysconfig::language} )
  or $request->error( __FILE__ . ':' . __LINE__ . ": Locale not loaded: $!\n" );

if (!$script){
	$request->error($locale->text('No workflow script specified'));
}

eval { require "scripts/$script" } 
  || $request->error($locale->text('Unable to open script') . ": $script : $!");

$script =~ s/\.pl$//;
$script = "LedgerSMB::Scripts::$script";
$script->can($request->{action}) 
  || $request->error($locale->text("Action Not Defined: ") . $request->{action});

$script->can($request->{action})->($request);
1;
