
package LedgerSMB::Report;

=head1 NAME

LedgerSMB::Report - Abstract Base Reporting Class for LedgerSMB

=head1 SYNPOSIS

A minimal report might inherit and use this module as follows:

    package LedgerSMB::Report::MinimalReportExample;
    use Moose;
    use namespace::autoclean;
    extends 'LedgerSMB::Report';

    sub name {
        my ($self) = @_;
        return $self->_locale->text('A Minimal Report Example');
    }

    sub columns {
        my ($self) = @_;
        return [
            {
                col_id => 'food_name',
                type => 'text',
                name => $self->_locale->text('Name')
            },
            {
                col_id => 'food_type',
                type => 'text',
                name => $self->_locale->text('Food Type')
            },
        ];
    }

    sub run_report {
        my ($self) = @_;
        $self->rows([
            {row_id => 1, name => 'apple', food_type => 'fruit'},
            {row_id => 1, name => 'carrot', food_type => 'vegetable'},
        ]);
        return;
    }


A report could then be generated with the following:

    use LedgerSMB::Report::MinimalReportExample;
    my $report = LedgerSMB::Report::MinimalReportExample->new();
    $report->render($request);


=head1 DESCRIPTION

This Perl module provides base utility functions for reporting in LedgerSMB.
It is an abstract class, never having direct instances, but instead being
inherited by other modules.

Subclasses MUST define the following methods:

=over

=item name

Must return the localized report name (usually displayed as a title
for the report).

=item columns

Must return an arrayref comprising hashes defining specifying each column
of the report table.

=item run_report

Must populate the object's C<rows> property with an arrayref containing
each record to display in the report table.

=back

Additionally, subclasses MAY define any of the following:

=over

=item header_lines

Returns an arrayref of the header fields to be displayed on the report.
The array elements must be hashrefs comprising the following keys:

  text - The localized header title
  name - The request parameter/object property name whose value is displayed

I<Report Name> and I<Company Name> are always included in the header lines
shown on a report (they are part of the template) and do not need to be
specified.

An example return value from a C<header_lines()> method might be:

  [
      {
          text => $self->_locale->text('Invoice Number'),
          name => 'invoice_no'
      },
      {
          text => $self->_locale->text('Date'),
          name => 'post_date'
      }
  ]

=item template

Returns the name of the template to be used.  Otherwise the generic
C<UI/reports/display_report> template will be used.

=back

=cut


use List::Util qw{ any };
use LedgerSMB::App_State;
use LedgerSMB::PGNumber;
use LedgerSMB::Template;
use LedgerSMB::Setting;

use Moose;
use namespace::autoclean;
with 'LedgerSMB::PGObject', 'LedgerSMB::I18N';



=head1 PROPERTIES

=head2 cols

This is an array of hashrefs.  Properties for each hashref:

=over

=item col_id

ID of column, alphanumeric, used in names of elements, classes, etc.  Required
for smooth operation.

=item name

Localized name of column for labelling purposes

=item type

Display type for column data.  May be one of:

    * text
    * input_text
    * hidden
    * href
    * input_text
    * radio
    * checkbox
    * boolean_checkmark

=item href_base

Base for href.  Only meaningful if type is href

=item class

CSS class (additional) for the column.

=back

=cut

has 'cols' => (is => 'rw', isa => 'ArrayRef[HashRef[Any]]');

=head2 rows

This is an arrayref of rows.  Each row has fields with keys matching the col_id
fields of the columns above.

=cut

has 'rows' => (is => 'rw', isa => 'ArrayRef[HashRef[Any]]');

=head2 format

This is the format, and must be one used by LedgerSMB::Template. If
undefined, defaults to 'html'.

=cut

has 'format' => (is => 'rw', isa => 'Maybe[Str]');

=head2 order_by

The column to order on.  Used in providing subtotals also.

=cut

has order_by  => (is => 'rw', isa => 'Maybe[Str]');

=head2 old_order_by

Previous order by.  Used internally to determine order direction.

=cut

has old_order_by  => (is => 'rw', isa => 'Maybe[Str]');

=head2 order_dir

Either C<asc>, C<desc>, or undef.  Used to determine next ordering.

=cut

has order_dir  => (is => 'rw', isa => 'Maybe[Str]');

=head2 order_url

Url for order redirection.  Internal only.

=cut

has order_url  => (is => 'rw', isa => 'Maybe[Str]');

=head2 show_subtotals

bool, determines whether to show subtotals.

=cut

has show_subtotals => (is => 'rw', isa => 'Bool');

=head2 manual_totals

Defaults to false.  Shows totals for all numeric (but not int) columns.
Typically this would be set to true in the run_report function if manual
totals are used.

=cut

has manual_totals => (is => 'rw', isa => 'Bool');

=head2 buttons

Buttons to show at the bottom of the screen when rendering as HTML. The
default is to display no buttons. Reports can override this by providing
a C<set_buttons> method.

Each array element from the C<buttons> property is used to initialise a
LedgerSMB C<button> template block. See its documentation for a description
of the various options.

On the UI, pressing a button triggers a new screen to load, via the same
module used to generate the report. The button's C<value> property specifies
the class method to be called.

Example:

    sub set_buttons {
        my $self = shift;
        return [
            {
                name => 'action',
                text => $self->_locale->text('Update'),
                value => 'update_widget',
            },
            {
                name => 'action',
                text => $self->_locale->text('Copy'),
                value => 'copy_widget',
            },
        ];
    }

=cut

has buttons => (
    is => 'rw',
    isa => 'ArrayRef[Any]',
    lazy => 1,
    builder => 'set_buttons',
);

=head2 options

List of select boxes for options for buttons.

=cut

has options => (is => 'rw', isa => 'ArrayRef[Any]',
                default => sub {[]} );

=head2 _locale

Locale to be used for the translation/localization of the report.

=cut

has _locale => (is => 'ro',
                default => sub { return $LedgerSMB::App_State::Locale; } );


=head1 METHODS

=head2 set_buttons

Returns the default empty set of buttons. Can be overridden by individual
reports.

=cut

sub set_buttons {
    return [];
}


=head2 _exclude_from_totals

Returns a hashref with the keys pointing to true values for column id's that
should not appear on the total row.

This is useful in avoiding a running total column from being added together and
a meaningless sum displayed on the totals row.

=cut

sub _exclude_from_totals {
    return {};
}


=head2 render

This takes no arguments and simply renders the report as is.

=cut

sub render {
    my $self = shift;
    my $request = shift;

    return $self->_render($request, renderer => 'render');
}


# PRIVATE METHODS

# _output_name
#
# Returns a base file name (without extension) for the current report.
# Used where output is to a file or attachment.

sub _output_name {
    my $self = shift;
    my $request = shift;

    return undef
        unless $request->{format};

    $self->format('html')
        unless defined $self->format;

    my $name = $self->name || '';
    $name =~ s/ /_/g;

    $name = $name . '_' . $self->from_date->to_output
            if $self->can('from_date')
               and defined $self->from_date
               and defined $self->from_date->to_output;
    $name = $name . '-' . $self->to_date->to_output
            if $self->can('to_date')
               and defined $self->to_date
               and defined $self->to_date->to_output;

    return $name;
}

# _render
#
# Render the report.

sub _render {
    my ($self, $request) = @_;
    my $template;
    my %args = ( @_ );

    my $testref = $self->rows;
    $self->run_report if !defined $testref;
    # This is a hook for other modules to use to override the default
    # template --CT
    local $@ = undef;
    eval {$template = $self->template};
    $template ||= 'Reports/display_report';

    # Sorting and Subtotal logic
    my $url = $request->get_relative_url();
    $self->order_dir('asc') if defined $self->order_by;
    if (defined $self->old_order_by and ($self->order_by eq $self->old_order_by)){
        if (lc($self->order_dir) eq 'asc'){
            $self->order_dir('desc');
        } else {
            $self->order_dir('asc');
        }
    }
    $url =~ s/&?order_by=[^\&]*//g if $url;
    $url =~ s/&?order_dir=[^\&]*//g if $url;
    $self->order_url($url);
    $self->order_url(
        "$url&old_order_by=".$self->order_by.'&order_dir='.$self->order_dir
    ) if $self->order_by;

    my $rows = $self->rows;
    @$rows = sort {
                   my $srt_a = $a->{$self->order_by};
                   my $srt_b = $b->{$self->order_by};

                   local $@ = undef;
                   $srt_a = $srt_a->to_sort
                       if eval { $srt_a->can('to_sort') };
                   $srt_b = $srt_b->to_sort
                       if eval { $srt_b->can('to_sort') };

                   no warnings 'numeric'; ## no critic ( ProhibitNoWarnings )
                   $srt_a <=> $srt_b or $srt_a cmp $srt_b;
              } @$rows
      if $self->order_by;
    if ($self->order_dir && $self->order_by
        && lc($self->order_dir) eq 'desc') {
        @$rows = reverse @$rows;
    }
    $self->rows($rows);
    my $total_row = {html_class => 'listtotal', NOINPUT => 1};
    my $col_val = undef;
    my $old_subtotal = {};
    my @newrows;
    my $exclude = $self->_exclude_from_totals;
    for my $r (@{$self->rows}){
        for my $k (keys %$r){
            next if $exclude->{$k};

            local $@ = undef;
            if (eval { $r->{$k}->isa('LedgerSMB::PGNumber') }){
                $total_row->{$k} ||= LedgerSMB::PGNumber->from_input('0');
                $total_row->{$k}->badd($r->{$k});
            }
        }
        if ($self->show_subtotals and defined $col_val and
            ($col_val ne $r->{$self->order_by})
         ){
            my $subtotals = {html_class => 'listsubtotal', NOINPUT => 1};
            for my $k (keys %$total_row){
                $subtotals->{$k} = $total_row->{$k}->copy
                        unless $subtotals->{k};
                $subtotals->{$k}->bsub($old_subtotal->{$k})
                        if ref $old_subtotal->{$k};
            }
            push @newrows, $subtotals;
         }
         push @newrows, $r;
    }
    push @newrows, $total_row unless $self->manual_totals;
    $self->rows(\@newrows);
    # Rendering

    $self->format('html') unless defined $self->format;
    my $columns = $self->show_cols($request);

    for my $col (@$columns){
        if ($col->{money}) {
            $col->{class} = 'money';
            for my $row(@{$self->rows}){
                local $@ = undef;
                if ( eval {$row->{$col->{col_id}}->can('to_output')}){
                    $row->{$col->{col_id}} =
                        $row->{$col->{col_id}}->to_output(money => 1);
                }
            }
        }
    }

    # needed to get aroud escaping of header line names
    # i.e. ignore_yearends -> ignore\_yearends
    # in latex
    my $replace_hnames = sub {
        my $lines = shift;
        return unless $lines;
        my @newlines = map { { name => $_->{name} } } @{$self->header_lines};
        return [map { +{ %$_, %{shift @newlines} } } @$lines ];
    };
    $template = LedgerSMB::Template->new(
        user => $LedgerSMB::App_State::User,
        locale => $self->locale,
        path => 'UI',
        output_options => {
            filename => $self->_output_name($request),
        },
        template => $template,
        format => uc($request->{format} || 'HTML'),
    );
    my $render = $template->can($args{renderer});
    return &$render($template,
                      {report => $self,
                 company_name => LedgerSMB::Setting->get('company_name'),
              company_address => LedgerSMB::Setting->get('company_address'),
                      request => $request,
                    new_heads => $replace_hnames,
                         name => $self->name,
                       hlines => $self->header_lines,
                      columns => $columns,
                    order_url => $self->order_url,
                      buttons => $self->buttons,
                      options => $self->options,
                         rows => $self->rows});
}

=head2 show_cols

Returns a list of columns based on selected ones from the report

=cut

sub show_cols {
    my ($self, $request) = @_;
    my @retval;
    for my $ref (@{$self->columns($request)}){
        if ($request->{"col_$ref->{col_id}"}){
            push @retval, $ref;
        }
        if ($ref->{col_id} =~ /bc_\d+/){
            push @retval, $ref if $request->{'col_business_units'};
        }
    }
    if (scalar @retval == 0){
       @retval = @{$self->columns};
    }
    return \@retval;
}

=head2 header_lines

Default method that specifies no header lines. Can be overridden by
individual reports.

=cut

sub header_lines {
    return [];
}


=head2 process_bclasses($ref)

This function processes a ref for a hashref key of business_units, which holds
an array of arrays of (class_id, bu_id) and adds keys in the form of
bc_$class_id holding the $bu_id fields.

=cut

sub process_bclasses {
    my ($self, $ref) = @_;
    for my $bu (@{$ref->{business_units}}){
     if($bu->[1]){#avoid message:Use of uninitialized value in hash element
        push @{$ref->{$bu->[0]}}, $bu->[1]
                 unless any { /$bu->[1]/ } @{$ref->{$bu->[0]}};
     }
    }
    return;
}


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012-2018 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

__PACKAGE__->meta->make_immutable;

1;
