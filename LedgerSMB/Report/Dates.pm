=head1 NAME

LedgerSMB::Report::Dates - Date properties for reports in LedgerSMB

=head1 SYNOPSIS

 with 'LedgerSMB::Report::Dates'

=cut

package LedgerSMB::Report::Dates;
use Moose::Role;
use LedgerSMB::MooseTypes;

=head1 DESCRIPTION

This handles standard date controls in reports.  It just adds properties to 
relevant Moose objects.

=head1 PROPERTIES ADDED

=over

=item from_date

=cut 

has from_date => (is => 'ro', isa => 'LedgerSMB::Moose::Date', coerce => 1);

=item to_date

=cut 

has to_date => (is => 'ro', isa => 'LedgerSMB::Moose::Date', coerce => 1);

=item ...

=head1 COPYRIGHT

=cut

1;
