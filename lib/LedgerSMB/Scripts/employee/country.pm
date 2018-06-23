
package LedgerSMB::Scripts::employee::country;

=head1 NAME

LedgerSMB::Scripts::employee::country - Country info for employee management

=head1 DESCRIPTION

none really.  This just allows viewing of certain info,

=head1 METHODS

This module doesn't declare any methods.

=head1 VARIABLES

=over

=item country_divs

This is a hashref where country_id => arrayref of hashrefs, where that hashref
has the following keys:

=over

=item div_title

=item file

=item save_sproc

=back

=cut

use strict;
use warnings;

our %country_divs = (

       '232' => [ { div_title => 'W4', # UNITED STATES
                         file => 'country_us_w4',
                   save_sproc => 'employee_us__save_w4' }],
);

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012-2018 The LedgerSMB Core Team

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
