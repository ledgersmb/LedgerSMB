=head1 NAME

LedgerSMB::Payroll::Income_Types - Income Types Searches for LedgerSMB

=head1 SYNPOSIS

 LedgerSMB::Payroll::Income_Types->new(%$request)->render(%$request);

=cut

package LedgerSMB::Report::Payroll::Income_Types;
use Moose;
extends 'LedgerSMB::Report';

=head1 DESCRIPTION

This module provides for searching for income types.

=head1 CONSTANT METHODS

=over

=item columns

=cut

sub columns {
    return [
        { col_id => 'country_name',
            name => LedgerSMB::Report::text('Country'),
            type => 'text',
        },
        { col_id => 'income_class',
            name => LedgerSMB::Report::text('Income Class'),
            type => 'text' },
        { col_id => 'label',
            name => LedgerSMB::Report::text('Label'),
            type => 'href',
       href_base => 'payrol.pl?action=edit&id=' },
    ];
}

=item header_lines

=cut

sub header_lines {
    return [];
}

=item name

=cut

sub name { return LedgerSMB::Report::text('Income Types') }

=back

=head1 CRITERIA PROPERTIES

=over

=item country_id int

Exact match on country id

=cut

has country_id => (is => 'ro', isa => 'Int', required => '0');

=item label string

Matches the beginning of the label

=cut

has label => (is => 'ro', isa => 'Str', required => '0');

=item pic_id int

Exact match on payroll income class id

=cut

has pic_id => (is => 'ro', isa => 'Int', required => '0');


=item account_id int

Exact match of the account id

=cut

has account_id => (is => 'ro', isa => 'Int', required => '0');


=item unit string

Exact match on unit

=cut

has unit => (is => 'ro', isa => 'Str', required => '0');

=back

=head1 METHODS

=over

=item run_report

=cut

sub run_report {
    my ($self) = $_;
    my @rows = $self->call_dbmethod(funcname => 'payroll_income_type__search');
    $_->{row_id} = $_->{id} for @rows;
    $self->rows(@rows);
}

=back

=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used following
the terms of the GNU General Public License version 2 or at your option any
later version.  Please see included LICENSE.TXT for details.

=cut

__PACKAGE__->meta->make_immutable;

1;
