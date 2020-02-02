
package LedgerSMB::Company_Config;

=head1 NAME

LedgerSMB::Company_Config - Company-specific Configuration for LedgerSMB.

=head1 DESCRIPTION

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

use strict;
use warnings;
use LedgerSMB::Setting;

my @company_settings = qw(templates businessnumber weightunit curr
                          default_email_from default_email_to
                          default_email_bcc  default_email_cc
                          default_language default_country
                          separate_duties company_name company_email
                          company_phone company_fax businessnumber vclimit
                          company_address dojo_theme decimal_places min_empty);

our $VERSION = 1.0;

# Used in old/bin/*.pl
our $settings = {};

sub initialize{
    my ($request) = @_;
    my $s = LedgerSMB::Setting->new(dbh => $request->{dbh});
    $settings = { map {$_ => $s->get($_) } @company_settings };
    $settings->{curr} = [ split (/:/, $settings->{curr}) ];
    $settings->{default_currency} = $settings->{curr}->[0];

   return $settings;
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011-2018 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
