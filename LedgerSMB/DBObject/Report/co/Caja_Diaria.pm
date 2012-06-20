=head1 NAME

LedgerSMB::DBObject::Report::co::Caja_Diaria - Caja Diaria Reports (Colombia)

=head1 SYNPOSIS

  my $cdreport = LedgerSMB::DBObject::Report::co::Caja_Diaria->new(%$request);
  $cdreport->run;
  $cdreport->render($request, $format);

=head1 DESCRIPTION

This module provides Caja Diaria eports for LedgerSMB to Colombian standards.
These reports provide an overview of cash activity to a set of accounts for a
specific period.

=head1 INHERITS

=over

=item LedgerSMB::DBObject::Report;

=back

=cut

package LedgerSMB::DBObject::Report::co::Caja_Diaria;
use Moose;
extends 'LedgerSMB::DBObject::Report';

use LedgerSMB::App_State;

my $locale = $LedgerSMB::App_State::Locale;
my $doctypes = {};

=head1 PROPERTIES

=over

=item columns

Read-only accessor, returns a list of columns.

=over

=item accno

Account Number

=item description

Account name

=item document_type

=item debits

=item credits

=back

=cut

our @COLUMNS = (
    {col_id => 'accno',
       name => $locale->text('Account'),
       type => 'href',
     pwidth => 3,
  href_base => '', },

    {col_id => 'description',
       name => $locale->text('Description'),
       type => 'text',
     pwidth => '12', },

    {col_id => 'document_type',
       name => $locale->text('Document'),
       type => 'text',
     pwidth => '3', },

    {col_id => 'debits',
       name => $locale->text('Debit'),
       type => 'text',
     pwidth => '4', },

    {col_id => 'credits',
       name => $locale->text('Credit'),
       type => 'text',
     pwidth => '4', },

);

sub columns {
    return \@COLUMNS;
}


=item filter_template

Returns the template name for the filter.

=cut

sub filter_template {
    return 'Reports/co/cj_filter';
}

=item name

Returns the localized template name

=cut

sub name {
    return $locale->text('Caja Diaria');
}

=item header_lines

Returns the inputs to display on header.

=cut

sub header_lines {
    return [{name => 'date_from',
             text => $locale->text('Start Date')},
            {name => 'date_to',
             text => $locale->text('End Date')},
            {name => 'accno',
             text => $locale->text('Account Number Start')},
            {name => 'reference',
             text => $locale->text('Account Number End')},]
}

=back

=head2 Criteria Properties

Note that in all cases, undef matches everything.

=over

=item date_from (text)

start date for the report

=cut

has 'date_from' => (is => 'rw', isa => 'Maybe[LedgerSMB::PGDate]');

=item date_to

End date for the report

=cut

has 'date_to'  => (is => 'rw', isa => 'Maybe[LedgerSMB::PGDate]');


=item from_accno

=cut

has 'from_accno' => (is => 'rw', isa => 'Maybe[Str]');

=item to_accno


=cut

has 'to_accno' => (is => 'rw', isa => 'Maybe[Str]');

=back

=head1 METHODS

=over

=item prepare_criteria($request)

Instantiates the PGDate and PGNumber inputs.

=cut

sub prepare_criteria{
    my ($self, $request) = @_;
    $request->{date_from} = LedgerSMB::PGDate->from_input(
                               $request->{date_from}
    );
    $request->{date_to} = LedgerSMB::PGDate->from_input($request->{date_to});
}

=item run_report()

Runs the report, and assigns rows to $self->rows.

=cut

sub run_report{
    my ($self) = @_;
    my @rows = $self->exec_method({funcname => 'report__cash_summary'});
    for my $ref(@rows){
        $ref->{document_type} = $doctypes->{$ref->{document_type}} 
                if $doctypes->{$ref->{document_type}};
    }
    $self->rows(\@rows);
}

=back

=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used following
the terms of the GNU General Public License version 2 or at your option any
later version.  Please see included LICENSE.TXT for details.

=cut

__PACKAGE__->meta->make_immutable;
return 1;
