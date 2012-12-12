=head1 NAME

LedgerSMB::Report::Timecards - Time and materials reports for LedgerSMB

=head1 SYNOPSIS

 my $report = LedgerSMB::Report::Timecards->new(%$request);
 $report->render($request);

=head1 DESCRIPTION

This report class provides a way to report on time and materials for projects, 
departments, and the like.  These reports are designed to be useful for payroll
and sales order generation among other things.

=cut

package LedgerSMB::Report::Timecards;
use LedgerSMB::MooseTypes;
use Moose;
extends 'LedgerSMB::Report';
with 'LedgerSMB::Report::Dates';

=head1 CRITERIA PROPERTIES

In addition to the standard date fields, we also have

=over

=item business_unts

This is the set of business units searched for.  Note that unlike other reports,
the fact that timecards are only associated with a single business unit means 
that these are additive.  In other words, if you select a department and a 
project, you will get timecards associated with either the department or the 
project, instead of the intersection of sets (which doesn't exist in this case).

=cut

has business_units => (is => 'rw', isa => 'ArrayRef[Int]', required => 0);

=item partnumber

This is the control code of the labor/overhead, service, or part consumed.

=cut

has partnumber => (is => 'ro', isa => 'Str', required => 0);

=item person_id

This is the id of the person record for the employee entering the timecard.

=cut

has person_id => (is => 'ro', isa => 'Int', required => 0);

=item open

Show open timecards

=cut

has open => (is => 'ro', isa => 'Bool', required => 0);

=item closed

show closed timecards

=cut

has closed => (is => 'ro', isa => 'Bool', required => 0);

=back

=item jctype

Show timecards of the specified type

=cut

has jctype => (is => 'ro', isa => 'Int', required => 0);


=head1 STATIC METHODS

=over

=item columns 

=cut

sub columns {
    return [
    {col_id => 'weekstarting',
       name => LedgerSMB::Report::text('Date'),
       type => 'text',
     pwidth => '2', },
    {col_id => 'business_unit_code',
       name => LedgerSMB::Report::text('Project/Department Number'),
       type => 'text',
     pwidth => '4', },
    {col_id => 'business_unit_description',
       name => LedgerSMB::Report::text('Description'),
       type => 'text',
     pwidth => '4', },
    {col_id => 'id',
       name => LedgerSMB::Report::text('ID'),
       type => 'text',
     pwidth => '1', },
    {col_id => 'partnumber',
       name => LedgerSMB::Report::text('Partnumber'),
       type => 'text',
     pwidth => '4', },
    {col_id => 'description',
       name => LedgerSMB::Report::text('Description'),
       type => 'text',
     pwidth => '4', },
    {col_id => 'day0',
       name => LedgerSMB::Report::text('Sun'),
       type => 'text',
     pwidth => '1', },
    {col_id => 'day1',
       name => LedgerSMB::Report::text('Mon'),
       type => 'text',
     pwidth => '1', },
    {col_id => 'day2',
       name => LedgerSMB::Report::text('Tue'),
       type => 'text',
     pwidth => '1', },
    {col_id => 'day3',
       name => LedgerSMB::Report::text('Wed'),
       type => 'text',
     pwidth => '1', },
    {col_id => 'day4',
       name => LedgerSMB::Report::text('Thu'),
       type => 'text',
     pwidth => '1', },
    {col_id => 'day5',
       name => LedgerSMB::Report::text('Fri'),
       type => 'text',
     pwidth => '1', },
    {col_id => 'day6',
       name => LedgerSMB::Report::text('Sat'),
       type => 'text',
     pwidth => '1', },
    ];
}

=item header_lines

=cut

sub header_lines  {
    return [{ name => 'date_from',
              text => LedgerSMB::Report::text('From Date'), },
            { name => 'date_to',
              text => LedgerSMB::Report::text('To Date'), },
            { name => 'partnumber',
              text => LedgerSMB::Report::text('Partnumber'), },
    ];
}

=item name

=cut

sub name {
    return LedgerSMB::Report::text('Timecards');
}

=back

=head1 METHODS

=over

=item run_report

=cut

sub run_report {
    my ($self) = @_;
    my @rows = $self->exec_method({ funcname => 'timecard__report' });
    for my $row (@rows){
        $row->{"day$row->{dow}"} = $row->{qty};
    }
    $self->rows(@rows);
}

=back

=head1 COPYRIGHT

=cut

__PACKAGE__->meta->make_immutable;
