=head1 NAME

LedgerSMB::Company_Config - Company-specific Configuration for LedgerSMB.

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
use warnings;
use base qw(LedgerSMB);
use LedgerSMB::Setting;
use LedgerSMB::App_State;

my @company_settings = qw(templates businessnumber weightunit curr
                          default_email_from default_email_to
                          default_email_bcc  default_email_cc
                          separate_duties company_name company_email
                          company_phone company_fax businessnumber
                          company_address dojo_theme decimal_places min_empty);

our $VERSION = 1.0;
our $settings = {};

sub initialize{
   my ($self) = @_;
   $settings= {map {$_ => LedgerSMB::Setting->get($_) } @company_settings};
   { no strict 'refs';
   @{$settings->{curr}} = split (/:/, $settings->{curr});
   }
   $LedgerSMB::App_State::Company_Config = $settings;
}

1;
