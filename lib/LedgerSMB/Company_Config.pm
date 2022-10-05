
package LedgerSMB::Company_Config;

=head1 NAME

LedgerSMB::Company_Config - Company-specific Configuration for LedgerSMB.

=head1 DESCRIPTION

This module stores the various company-specific configuration details for
LedgerSMB

=head1 METHODS

=over

=item initialize($dbh)

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

# Used in LedgerSMB::PGNumber (for 'decimal_places')
our $settings = {};

sub initialize{
    my ($dbh) = @_;

    my $sth = $dbh->prepare(
        q{SELECT n.setting_key, s.value
        FROM unnest(?::text[]) n(setting_key), setting_get(setting_key) s})
        or die $dbh->errstr;
    $sth->execute(\@company_settings)
        or die $sth->errstr;

    my $results = $sth->fetchall_arrayref({});
    die $sth->errstr if $sth->err; # defined and != 0 and ne ''

    $settings = {
        map { $_->{setting_key} => $_->{value} }
        @$results
    };
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
