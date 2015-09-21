=head1 NAME

LedgerSMB::Scripts::employee::country - Country info for employee management

=head1 SYNOPSYS

none really.  This just allows viewing of certain info,

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

package LedgerSMB::Scripts::employee::country;

use strict;
use warnings;

our %country_divs = (

       "232" => [ { div_title => 'W4', # UNITED STATES
                         file => 'country_us_w4',
                   save_sproc => 'employee_us__save_w4' }],
);

=back

=head1 COPYRIGHT

=cut

1;
