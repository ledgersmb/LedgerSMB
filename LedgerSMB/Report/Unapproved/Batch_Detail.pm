=head1 NAME

LedgerSMB::Report::Unapproved::Batch_Detail - List Vouchers by Batch
in LedgerSMB

=head1 SYNPOSIS

  my $report = LedgerSMB::Report::Unapproved::Batch_Detail->new(
      %$request
  );
  $report->run;
  $report->render($request, $format);

=head1 DESCRIPTION

This provides an ability to search for (and approve or delete) pending
transactions grouped in batches.  This report only handles the vouchers in the
bach themselves. For searching for batches, use
LedgerSMB::Report::Unapproved::Batch_Overview instead.

=head1 INHERITS

=over

=item LedgerSMB::Report;

=back

=cut

package LedgerSMB::Report::Unapproved::Batch_Detail;
use Moose;
use LedgerSMB::DBObject::User;
extends 'LedgerSMB::Report';

use LedgerSMB::Business_Unit_Class;
use LedgerSMB::Business_Unit;
use LedgerSMB::Setting;


=head1 PROPERTIES

=over

=item columns

Read-only accessor, returns a list of columns.

=over

=item select

Select boxes for selecting the returned items.

=item id

ID of transaction

=item batch_class

Text description of batch class

=item transdate

Post date of transaction
use LedgerSMB::Report::Unapproved::Batch_Overview;

=item reference text

Invoice number or GL reference

=item description

Description of transaction

=item amount

Total on voucher.  For AR/AP amount, this is the total of the AR/AP account
before payments.  For payments, receipts, and GL, it is the sum of the credits.

=back

=cut

sub columns {
    return [
    {col_id => 'select',
       name => '',
       type => 'checkbox' },

    {col_id => 'id',
       name => LedgerSMB::Report::text('ID'),
       type => 'text',
     pwidth => 1, },

    {col_id => 'batch_class',
       name => LedgerSMB::Report::text('Batch Class'),
       type => 'text',
     pwidth => 2, },

    {col_id => 'default_date',
       name => LedgerSMB::Report::text('Date'),
       type => 'text',
     pwidth => '4', },

    {col_id => 'Reference',
       name => LedgerSMB::Report::text('Reference'),
       type => 'href',
  href_base => '',
     pwidth => '3', },

    {col_id => 'description',
       name => LedgerSMB::Report::text('Description'),
       type => 'text',
     pwidth => '6', },

    {col_id => 'amount',
       name => LedgerSMB::Report::text('Amount'),
       type => 'text',
      money => 1,
     pwidth => '2', },
    ];

    # TODO:  business_units int[]
}

=item name

Returns the localized template name

=cut

sub name {
    return LedgerSMB::Report::text('Voucher List');
}

=item header_lines

Returns the inputs to display on header.

=cut

sub header_lines {
    return [{name => 'batch_id',
             text => LedgerSMB::Report::text('Batch ID')}, ]
}

=item subtotal_cols

Returns list of columns for subtotals

=cut

sub subtotal_cols {
    return [];
}

=back

=head2 Criteria Properties

Note that in all cases, undef matches everything.

=over

=item batch_id (Int)

ID of batch to list vouchers of.

=cut

has 'batch_id' => (is => 'rw', isa => 'Int');

=back

=head1 METHODS

=over

=item run_report()

Runs the report, and assigns rows to $self->rows.

=cut

sub run_report{
    my ($self) = @_;
    my %lhash = LedgerSMB::DBObject::User->country_codes();
    my ($default_language) = LedgerSMB::Setting->get('default_language');
    my $locales = [ map { { text => $lhash{$_}, value => $_ } }
                    sort {$lhash{$a} cmp $lhash{$b}} keys %lhash
                  ];
    my $printer = [ {text => 'Screen', value => 'zip'},
                    map { {
                         text => $_, value => $LedgerSMB::Sysconfig::printer{$_}
                          } }
                  keys %LedgerSMB::Sysconfig::printer];
    $self->options([{
       name => 'language',
       options => $locales,
       default_value => [$default_language],
    }, {
       name => 'media',
       options => $printer,
    },
    ]);

    $self->buttons([{
                    name  => 'action',
                    type  => 'submit',
                    text  => LedgerSMB::Report::text('Post Batch'),
                    value => 'single_batch_approve',
                    class => 'submit',
                 },{
                    name  => 'action',
                    type  => 'submit',
                    text  => LedgerSMB::Report::text('Delete Batch'),
                    value => 'single_batch_delete',
                    class => 'submit',
                 },{
                    name  => 'action',
                    type  => 'submit',
                    text  => LedgerSMB::Report::text('Delete Vouchers'),
                    value => 'batch_vouchers_delete',
                    class => 'submit',
                },
                {
                    name  => 'action',
                    type  => 'submit',
                    text  => LedgerSMB::Report::text('Unlock Batch'),
                    value => 'single_batch_unlock',
                    class => 'submit',
                },
                {
                    name  => 'action',
                    type  => 'submit',
                    text  => LedgerSMB::Report::text('Print Batch'),
                    value => 'print_batch',
                    class => 'submit',
                }, ]);
    my @rows = $self->call_dbmethod(funcname => 'voucher__list');
    for my $ref (@rows){
        my $script;
        my $class_to_script = {
           '1' => 'ap',
           '2' => 'ar',
           '3' => 'gl',
           '8' => 'is',
           '9' => 'ir',
        };
        $script = $class_to_script->{lc($ref->{batch_class_id})};
        $ref->{reference_href_suffix} = "$script.pl?action=edit&id=$ref->{id}" if $script;
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

1;
