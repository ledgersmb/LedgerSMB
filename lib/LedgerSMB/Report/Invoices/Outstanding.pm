=head1 NAME

LedgerSMB::Report::Invoices::Outstanding - Outstanding Invoice Reports for
LedgerSMB

=head1 SYNOPSIS

 my $report = LedgerSMB::Report::Invoices::Outstanding->new(%$request);
 $report->render($request);

=cut

package LedgerSMB::Report::Invoices::Outstanding;
use Moose;
extends 'LedgerSMB::Report';
with 'LedgerSMB::Report::Dates';

=head1 DESCRIPTION

The Outstanding reports provide an ability to track the invoices outstanding at
a given date.  Summary reports return one line per customer or vendor, and
details reports return one line per invoice.

=head1 CRITERIA PROPERTIES

=over

=item is_detailed bool

If set true, return one line per invoice, if false set one line per entity
credit account

=cut

has is_detailed => (is => 'ro', isa => 'Bool', required => 1);

=item entity_class

1 for vendor, 2 for customer

=cut

has entity_class => (is => 'ro', isa => 'Int', required => 1);

=item account_id int

Only show invoices or totals for specified AR/AP account.

=cut

has account_id => (is => 'ro', isa => 'Int', required => 0);

=item entity_name

Show invoices for customers or vendors with a name like this, full text search

=cut

has entity_name => (is => 'ro', isa => 'Str', required => 0);

=item meta_number

Show invoices only for the control code of the entity credit account, search is
based on the beginning of the string.

=cut

has meta_number => (is => 'ro', isa => 'Str', required => 0);

=item employee_id

Only show invoices attached to the specified salespersln

=cut

has employee_id => (is => 'ro', isa => 'Int', required => '0');

=item business_ids

Only show invoices attached to all of these business ids

=cut

has business_ids => (is => 'rw', isa => 'ArrayRef[Int]', required => '0');

=item ship_via

Full text search on shipvia field

=cut

has ship_via => (is => 'ro', isa => 'Str', required => 0);

=item on_hold

Bool match for on-hold invoices.  1 shows only onhold, 0 active, and undef all.

=cut

has on_hold => (is => 'ro', isa => 'Bool', required => 0);

=back

=cut

=head1 INTERNALS

=head2 columns

=over

=item running_number

=item transdate

=item invoice

=item id

=item ordnumber

=item ponumber

=item meta_number

=item entity_name

=item amount

=item tax

=item total

=item paid

=item due

=item curr

=item last_paydate

=item due_date

=item notes

=item till

=item employee_name

=item manager_name

=item shipping_point

=item ship_via

=back

=cut

sub columns {
    my $self = shift;
    my $inv_label = LedgerSMB::Report::text('# Invoices');
    my $details_url = LedgerSMB::App_State::get_relative_url();
    $details_url =~ s/is_detailed=0/is_detailed=1/;
    $details_url =~ s/meta_number=[^&]*//;
    my $inv_type = 'href';
    my $inv_href_base = $details_url . '&meta_number=';
    if ($self->is_detailed){
        $inv_label = LedgerSMB::Report::text('Invoice');
        $inv_type = 'href';
    }
    my $entity_label;
    if ($self->entity_class == 1){
       $entity_label = LedgerSMB::Report::text('Vendor');
    } elsif ($self->entity_class == 2){
       $entity_label = LedgerSMB::Report::text('Customer');
    } else {
       die 'invalid entity class';
    }
    return [
        {col_id => 'running_number',
           name => '#',
           type => 'text',
         pwidth => 1, },
        {col_id => 'transdate',
           name => LedgerSMB::Report::text('Date'),
           type => 'text',
         pwidth => 4, },
        {col_id => 'id',
           name => LedgerSMB::Report::text('ID'),
           type => 'text',
         pwidth => 2, },
        {col_id => 'invnumber',
           name => $inv_label,
           type => $inv_type,
         pwidth => 10, },
        {col_id => 'ordnumber',
           name => LedgerSMB::Report::text('Order'),
           type => 'text',
         pwidth => 10, },
        {col_id => 'ponumber',
           name => LedgerSMB::Report::text('PO Number'),
           type => 'text',
         pwidth => 10, },
        {col_id => 'meta_number',
           name => LedgerSMB::Report::text('Account'),
           type => 'text',
         pwidth => 10, },
        {col_id => 'entity_name',
           name => $entity_label,
           type => 'href',
      href_base => 'contact.pl?action=edit&',
         pwidth => 15, },
        {col_id => 'amount',
           name => LedgerSMB::Report::text('Amount'),
           type => 'text',
          money => 1,
         pwidth => 8, },
        {col_id => 'tax',
           name => LedgerSMB::Report::text('Tax'),
           type => 'text',
          money => 1,
         pwidth => 8, },
        {col_id => 'netamount',
           name => LedgerSMB::Report::text('Total'),
           type => 'text',
          money => 1,
         pwidth => 8, },
        {col_id => 'paid',
           name => LedgerSMB::Report::text('Paid'),
           type => 'text',
          money => 1,
         pwidth => 8, },
        {col_id => 'due',
           name => LedgerSMB::Report::text('Amount Due'),
           type => 'text',
          money => 1,
         pwidth => 8, },
        {col_id => 'curr',
           name => LedgerSMB::Report::text('Curr'),
           type => 'text',
         pwidth => 8, },
        {col_id => 'last_paydate',
           name => LedgerSMB::Report::text('Date Paid'),
           type => 'text',
         pwidth => 8, },
        {col_id => 'duedate',
           name => LedgerSMB::Report::text('Due Date'),
           type => 'text',
         pwidth => 8, },
        {col_id => 'notes',
           name => LedgerSMB::Report::text('Notes'),
           type => 'text',
         pwidth => 15, },
        {col_id => 'till',
           name => LedgerSMB::Report::text('Till'),
           type => 'text',
         pwidth => 8, },
        {col_id => 'employee_name',
           name => LedgerSMB::Report::text('Salesperson'),
           type => 'text',
         pwidth => 10, },
        {col_id => 'manager_name',
           name => LedgerSMB::Report::text('Manager'),
           type => 'text',
         pwidth => 10, },
        {col_id => 'shipping_point',
           name => LedgerSMB::Report::text('Shipping Point'),
           type => 'text',
         pwidth => 10, },
        {col_id => 'ship_via',
           name => LedgerSMB::Report::text('Ship Via'),
           type => 'text',
         pwidth => 10, },
    ];
}

=head2 header_lines

# TODO

=cut

sub header_lines {
    return [];
}

=head2 name

Returns either the localized strings for "AR Outstanding" or "AP Outstanding"

=cut

sub name {
    my $self = shift;
    if ($self->entity_class == 1) {
        return LedgerSMB::Report::text('AP Outstanding');
    } elsif ($self->entity_class == 2) {
        return LedgerSMB::Report::text('AR Outstanding');
    }
}

=head1 METHODS

=over

=item run_report

=back

=cut

sub run_report {
    my $self = shift;
    $ENV{LSMB_ALWAYS_MONEY} = 1;
    my $procname = 'report__aa_outstanding';
    if ($self->is_detailed){
       $procname .= '_details';
    }
    my @rows = $self->call_dbmethod(funcname => $procname);
    for my $r(@rows){
        my $script;
        if ($self->entity_class == 2) {
             $script = ($r->{invoice}) ? 'is.pl' : 'ar.pl';
        } else {
             $script = ($r->{invoice}) ? 'ir.pl' : 'ap.pl';
        }
        #tshvr4 avoid 'Use of uninitialized value in concatenation (.) or string at LedgerSMB/Report/Invoices/Outstanding.pm'
        if($r->{id}){
            $r->{invnumber_href_suffix} = "$script?action=edit&id=$r->{id}";
        } else {
            $r->{invnumber_href_suffix} = $r->{meta_number};
        }
        $r->{entity_name_href_suffix} = "entity_class=" . $self->entity_class
                         . "&entity_id=$r->{entity_id}&".
                         "meta_number=$r->{meta_number}";
    }
    $self->rows(\@rows);
}

=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used following
the terms of the GNU General Public License version 2 or at your option any
later version.  Please see included LICENSE.TXT for details.

=cut

__PACKAGE__->meta->make_immutable;

1;
