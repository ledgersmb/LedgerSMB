=head1 NAME

LedgerSMB::Company_Config    Company-specific Configuration for LedgerSMB

=head1 SYNOPSIS

This module stores the various company-specific configuration details for
LedgerSMB

=head1 METHODS

=over 

=item initialize()

Initializes the $settings hashref.

=back

=head1 DATA

All data is contained in the LedgerSMB::Company_Config::settings hashref.  
These are defined by looking at the @company_settings list in the current 
namespace (scope of which is 'my') and setting keys as expected.

=head1 Copyright (C) 2006, The LedgerSMB core team.

=cut

package LedgerSMB::Company_Config;
use strict;
use base qw(LedgerSMB);
use LedgerSMB::Setting;

my @company_settings = qw(templates businessnumber weightunit curr
                          default_email_from default_email_to
                          default_email_bcc  default_email_cc
                          separate_duties);

our $VERSION = 0.1;
our $settings = {};

sub initialize{
   my ($self) = @_;
   for my $k (keys %$settings){
       delete $settings->{$k};
   }
   for my $setting (@company_settings){
       my ($ref) = LedgerSMB::call_procedure($self, procname => 'setting_get', 
                  args => [$setting]);
       if ($ref->{setting_key} eq 'curr'){
          $settings->{$setting} = split /:/, $ref->{value};
       } else {
          $settings->{$setting} = $ref->{value};
       }
   }
}
