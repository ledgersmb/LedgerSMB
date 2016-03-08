=head1 NAME

LedgerSMB::Report::Inventory::Adj_Details - Inventory Adjustment
Details report for LedgerSMB

=head1 SYNPOSIS

 my $rpt = LedgerSMB::Report::Inventory::Adj_Details->new(%$request);
 $rpt->run_report;
 $rpt->render($request);

=cut

package LedgerSMB::Report::Inventory::Adj_Details;
use Moose;
use LedgerSMB::Report::Inventory::Search_Adj;
extends 'LedgerSMB::Report';
use LedgerSMB::Form;
use LedgerSMB::IS;
use LedgerSMB::IR;
use LedgerSMB::AA;
use LedgerSMB::App_State;
use LedgerSMB::Setting;

=head1 DESCRIPTION

This report shows the details of an inventory adjustment report.

THIS IS NOT SAFE TO CACHE UNTIL THE FINANCIAL LOGIC IS IN THE NEW FRAMEWORK.

=head1 CRITERIA PROPERTIES

=over

=item id

This is the report id.

=cut

has id => (is => 'ro', isa => 'Int', required => 1);

=back

=head1 PROPERTIES FOR HEADER

=over

=item source

Matches the beginning of the source string on the report source string

=cut

has source => (is => 'rw', isa => 'Maybe[Str]');

=back

=head1 REPORT CONSTANT FUNCTIONS

=over

=item name

=cut

sub name { return LedgerSMB::Report::text('Inventory Adjustment Details') }

=item header_lines

=cut

sub header_lines {
    return [{name => 'source', text => LedgerSMB::Report::text('Source') }];
}

=item columns

=cut

sub columns {
    return [
      {col_id => 'partnumber',
         type => 'href',
    href_base => 'ic.pl?action=edit&id='.
         name => LedgerSMB::Report::text('Part Number') },
      {col_id => 'description',
         type => 'text',
         name => LedgerSMB::Report::text('Description') },
      {col_id => 'counted',
         type => 'text',
         name => LedgerSMB::Report::text('Counted') },
      {col_id => 'expected',
         type => 'text',
         name => LedgerSMB::Report::text('Expected') },
      {col_id => 'variance',
         type => 'text',
         name => LedgerSMB::Report::text('Variance') },
    ];
}

=back

=head2 set_buttons

This sets buttons relevant to approving the adjustments.

=cut

sub set_buttons {
    return [{
       name => 'action',
       type => 'submit',
      value => 'approve',
       text => LedgerSMB::Report::text('Approve'),
      class => 'submit',
    },{
       name => 'action',
       type => 'submit',
      value => 'delete',
       text => LedgerSMB::Report::text('Delete'),
      class => 'submit',
    }];
}

=head1 METHODS

=head2 run_report

=cut

sub run_report {
    my ($self) = @_;
    my ($rpt) = $self->call_dbmethod(funcname => 'inventory_adj__get');
    $self->source($rpt->{source});
    my @rows = $self->call_dbmethod(funcname => 'inventory_adj__details');
    for my $row (@rows){
        $row->{row_id} = $row->{parts_id};
    }
    $self->rows(\@rows);
}

=head2 approve

Approves the report.  This currently goes through the legacy code and is the
point where caching becomes unsafe.

=cut

sub approve {
    my ($self) = @_;
    my $form_ar = bless({rowcount => 1}, 'Form');
    my $form_ap = bless({rowcount => 1}, 'Form');
    my $curr = LedgerSMB::Setting->get('curr');
    ($curr) = split(':', $curr);

    ## Setting up forms
    #
    # ar
    $form_ar->{dbh} = LedgerSMB::App_State::DBH;
    $form_ar->{customer} = '00000';
    $form_ar->{vc} = 'customer';
    $form_ar->get_name( {}, 'customer', 'today', '2' );
    $form_ar->{customer_id} = $form_ar->{'name_list'}->[0]->{id};
    $form_ar->{currency} = $curr;
    $form_ar->{defaultcurrency} = $curr;


    # ap
    $form_ap->{dbh} = LedgerSMB::App_State::DBH;
    $form_ap->{vendor} = '00000';
    $form_ap->{vc} = 'vendor';
    $form_ap->get_name( {}, 'vendor', 'today', '1' );
    $form_ap->{vendor_id} = $form_ap->{'name_list'}->[0]->{id};
    $form_ap->{currency} = $curr;
    $form_ap->{defaultcurrency} = $curr;


    ## Processing reports
    $self->run_report;
    my @rows = @{$self->rows};
    for my $row (@rows){
        next if $row->{variance} == 0;
        if ($row->{variance} < 0){
            my $form = $form_ar;
            my $rc = $form->{rowcount};
            $form->{"qty_$rc"} = -1 * $row->{variance};
            $form->{"id_$rc"} = $row->{parts_id};
            $form->{"description_$rc"} = $row->{description};
            $form->{"discount_$rc"} = '100';
            $form->{"sellprice_$rc"} = $row->{sellprice};
            ++$form->{rowcount};
        } elsif ($row->{variance} > 0){
            my $form = $form_ap;
            my $rc = $form->{rowcount};
            $form->{"qty_$rc"} = $row->{variance};
            $form->{"id_$rc"} = $row->{parts_id};
            $form->{"description_$rc"} = $row->{description};
            $form->{"discount_$rc"} = '100';
            $form->{"sellprice_$rc"} = $row->{lastcost};
            ++$form->{rowcount};

        }
    }
    ## Posting
    IS->post_invoice({}, $form_ar);
    IR->post_invoice({}, $form_ap);
    $self->call_procedure(funcname => 'inventory_report__approve',
       args => [$self->id, $form_ar->{id}, $form_ap->{ap}]
    );
}

=head2 delete

Deletes the inventory report

=cut

sub delete {
    my ($self) = @_;
    $self->call_dbmethod(funcname => 'inventory_report__delete');
}

=head1 SEE ALSO

=over

=item LedgerSMB::Report;

=item LedgerSMB::Report::Inventory::Search_Adj;

=back

=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of the LedgerSMB General Public License version 2 or at your option any
later version.  Please see enclosed LICENSE file for details.

=cut

__PACKAGE__->meta->make_immutable;
1;
