
package LedgerSMB::Report::Aging;

=head1 NAME

LedgerSMB::Report::Aging - AR/AP Aging reports for LedgerSMB

=head1 SYNPOSIS

  my $agereport = LedgerSMB::Report::Aging->new(%$request);
  $agereport->render();

=head1 DESCRIPTION

This module provides reports that show how far overdue payments for invoices
are.  This can be useful to help better manage collection of moneys owed, etc.

This module is also capable of printing statements, which are basically aging
reportins aimed at the customer in question.

=cut

use Moose;
use namespace::autoclean;
extends 'LedgerSMB::Report';

use LedgerSMB::Business_Unit_Class;
use LedgerSMB::Business_Unit;
use LedgerSMB::I18N;

use List::Util qw(none sum);


has 'languages' => (is => 'ro',
                    required => 1);

=head1 PROPERTIES

=over

=item columns

Read-only accessor, returns a list of columns.

=over

=item select

=item credit_account

=item language

=item invnumber

=item order

=item transdate

=item duedate

=item c0

=item c30

=item c60

=item c90

=item total

=item one for each business unit class returned

=back

=cut




sub columns {
    my ($self, $request) = @_;
    our @COLUMNS = ();
    my $credit_label;
    my $base_href;
    if ($self->entity_class == 1) {
        $credit_label = $self->Text('Vendor');
        $base_href = 'ap.pl?__action=edit&id='; # for details
    } elsif ($self->entity_class == 2){
        $credit_label = $self->Text('Customer');
        $base_href = 'ar.pl?__action=edit&id='; # for details
    }

    push @COLUMNS,
      {col_id => 'name',
         name => $credit_label,
         type => 'text',
       pwidth => 1, },

      {col_id => 'account_number',
         name => $self->Text('Account'),
         type => 'text',
       pwidth => 1, },

      {col_id => 'language',
         name => $self->Text('Language'),
         type => 'select',
      options => $self->languages,
       pwidth => '0', },

      {col_id => 'select',
         type => 'checkbox',
         name => 'X',
       toggle => 1,
      };

   if ($self->report_type eq 'detail'){
     push @COLUMNS,
          {col_id => 'invnumber',
             name => $self->Text('Invoice'),
             type => 'href',
        href_base => $base_href,
           pwidth => '3', },

          {col_id => 'ordnumber',
             name => $self->Text('Description'),
             type => 'text',
           pwidth => '6', },

          {col_id => 'transdate',
             name => $self->Text('Date'),
             type => 'text',
           pwidth => '1', },

          {col_id => 'duedate',
             name => $self->Text('Due Date'),
             type => 'text',
           pwidth => '2', };
    }

    push @COLUMNS,
    {col_id => 'c0_tc',
       name => $self->Text('Current'),
       type => 'text',
      money => 1,
     pwidth => '2', },

    {col_id => 'c30_tc',
       name => '30',
       type => 'text',
      money => 1,
     pwidth => '3', },

    {col_id => 'c60_tc',
       name => '60',
       type => 'text',
      money => 1,
     pwidth => '3', },

    {col_id => 'c90_tc',
       name => '90',
       type => 'text',
      money => 1,
     pwidth => '3', },

    {col_id => 'total_tc',
       name => $self->Text('Total'),
       type => 'text',
      money => 1,
     pwidth => '3', },

      {col_id => 'curr',
         name => $self->Text('Currency'),
         type => 'text',
       pwidth => '1', };


    return \@COLUMNS;
}

    # TODO:  business_units int[]

=item filter_template

Returns the template name for the filter.

=cut

sub filter_template {
    return 'journal/search';
}

=item name

Returns the localized template name

=cut

sub name {
    my ($self) = @_;
    return $self->Text('Aging Report');
}

=item template

Returns the name of the template to use

=cut

sub template {
    return 'aging_report';
}

=back

=head2 Criteria Properties

Note that in all cases, undef matches everything.

=over

=item report_type

Is 'summary' or 'detail'

=cut

has 'report_type' => (is => 'rw', isa => 'Str');

=item accno

Exact match for the account number for the AR/AP account

=cut

has 'accno'  => (is => 'rw', isa => 'Maybe[Str]');


=item to_date

Calculate report as on a specific date

=cut

has 'to_date'=> (is => 'rw', isa => 'LedgerSMB::PGDate');

=item entity_class

1 for vendor, 2 for customer

=cut

has 'entity_class' => (is => 'ro', isa => 'Maybe[Int]');

=item entity_id

Customer/Vendor entity id

=cut

has entity_id => (is => 'ro', isa => 'Maybe[Int]');
has name_part => (is => 'ro', isa => 'Maybe[Str]');

=item credit_id

Entity Credit Account id

=cut

has credit_id => (is => 'ro', isa => 'Maybe[Int]');

=item details_filter

=cut

has details_filter => (is => 'ro', isa => 'Maybe[ArrayRef]',
                       predicate => 'has_details_filter');



has c0total => (is => 'rw', init_arg => undef);
has c30total => (is => 'rw', init_arg => undef);
has c60total => (is => 'rw', init_arg => undef);
has c90total => (is => 'rw', init_arg => undef);
has total => (is => 'rw', init_arg => undef);

has '+show_totals' => (default => 0);

=back

=head1 METHODS

=over

=item run_report()

Runs the report, and assigns rows to $self->rows.

=cut

sub run_report{
    my ($self) = @_;
    my @rows = $self->call_dbmethod(funcname => 'report__invoice_aging_' .
                                                $self->report_type);
    my @result;
    my %account_rowspan;
    my %curr_rowspan;
    my $curr_subtotals = {
        c0 => 0, c30 => 0, c60 => 0, c90 => 0, total => 0,
        c0_tc => 0, c30_tc => 0, c60_tc => 0, c90_tc => 0, total_tc => 0
    };
    my $last_curr_sec = '';
    my $last_sec = '';
    for my $row (@rows) {
        next if ($self->has_details_filter
                 and none { $_ == $row->{id} } $self->details_filter->@*);
        if ($self->report_type eq 'detail') {
            my $sec = "$row->{account_number}:$row->{entity_id}";
            my $curr_sec = "$sec:$row->{curr}";
            if ($last_curr_sec ne $curr_sec) {
                if ($last_curr_sec) {
                    $account_rowspan{$last_sec} //= 0;
                    $account_rowspan{$last_sec}++;

                    # $curr_rowspan{$last_curr_sec} //= 0;
                    # $curr_rowspan{$last_curr_sec}++;
                    push @result, $curr_subtotals;
                }
                $curr_subtotals = {
                    c0 => 0, c30 => 0, c60 => 0, c90 => 0, total => 0,
                    c0_tc => 0, c30_tc => 0, c60_tc => 0, c90_tc => 0, total_tc => 0,
                    invnumber => '',
                    invnumber_NOHREF => 1,
                    html_class => 'listsubtotal',
                    $row->%{qw( account_number entity_id curr )},
                };
            }

            $account_rowspan{$sec} //= 0;
            $account_rowspan{$sec}++;

            # $curr_rowspan{$curr_sec} //= 0;
            # $curr_rowspan{$curr_sec}++;

            $row->{row_id} = "$sec:$row->{id}";
            $last_curr_sec = $curr_sec;
            $last_sec = $sec;
        } else {
            $row->{row_id} = "$row->{account_number}:$row->{entity_id}";
        }

        $row->{language} //= $self->language;
        $row->{total} = sum map { $row->{$_} } qw/ c0 c30 c60 c90 /;
        $row->{total_tc} = sum map { $row->{"${_}_tc"} } qw/ c0 c30 c60 c90 /;

        $curr_subtotals->{$_} += $row->{$_} for (qw/ c0 c30 c60 c90 total /);
        $curr_subtotals->{"${_}_tc"} += $row->{"${_}_tc"} for (qw/ c0 c30 c60 c90 total /);
        $self->c0total($self->c0total + $row->{c0});
        $self->c30total($self->c30total + $row->{c30});
        $self->c60total($self->c60total + $row->{c60});
        $self->c90total($self->c90total + $row->{c90});

        $self->total($self->total + $row->{total});

        push @result, $row;
    }
    if ($last_curr_sec) {
        $account_rowspan{$last_sec} //= 0;
        $account_rowspan{$last_sec}++;

        # $curr_rowspan{$last_curr_sec} //= 0;
        # $curr_rowspan{$last_curr_sec}++;
        push @result, $curr_subtotals;
    }
    else {
        $curr_subtotals->@{qw( html_class )} = ('listtotal');
        push @result, $curr_subtotals;
    }
    if (%account_rowspan) {
        for my $row (@result) {
            my $sec = "$row->{account_number}:$row->{entity_id}";
            my $account_span = $account_rowspan{$sec} // 0;
            if ($account_span > 1) {
                $row->{language_ROWSPAN} = $account_span;
                $row->{name_ROWSPAN} = $row->{language_ROWSPAN};
                $row->{account_number_ROWSPAN} = $row->{language_ROWSPAN};
                $account_rowspan{$sec} *= -1;
            }
            elsif ($account_rowspan{$sec} < 0) {
                $row->{language_ROWSPANNED} = 1;
                $row->{name_ROWSPANNED} = 1;
                $row->{account_number_ROWSPANNED} = 1;
            }

            my $curr_span = $curr_rowspan{"$sec:$row->{curr}"} // 0;
            if ($curr_span > 1) {
                $row->{curr_ROWSPAN} = $curr_span;
                $curr_rowspan{"$sec:$row->{curr}"} *= -1;
            }
            elsif ($curr_span < 0) {
                $row->{curr_ROWSPANNED} = 1;
            }
        }
    }
    return $self->rows(\@result);
}

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012-2024 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

__PACKAGE__->meta->make_immutable;

1;
