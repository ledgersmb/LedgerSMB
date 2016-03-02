=head1 NAME

LedgerSMB::Report - Base Reporting Functionality for LedgerSMB

=head1 SYNPOSIS

This Perl module provides base utility functions for reporting in LedgerSMB.
This is intended to be an abstract class, never having direct instances, but
instead inherited out to other modules.

=head1 DESCRIPTION

LedgerSMB::DBObject::Report provides basic utility functions for reporting in
LedgerSMB.  It is an abstract class.  Individual report types MUST inherit this
out.

Subclasses MUST define the following subroutines:

=over

=item get_columns

This MUST return a list of hashrefs for the columns per the dynatable block.

=back

Additionally, subclasses MAY define any of the following:

=over

=item template

Returns the name of the template to be used.  Otherwise a generic
UI/reports/display_report template will be used.

=back

=cut

package LedgerSMB::Report;
use Moose;
with 'LedgerSMB::PGObject', 'LedgerSMB::I18N';
use LedgerSMB::Setting;

use LedgerSMB::Template;
use LedgerSMB::App_State;

=head1 PROPERTIES

=over

=item cols

This is an array of hashrefs.  Properties for each hashref:

=over

=item col_id

ID of column, alphanumeric, used in names of elements, classes, etc.  Required
for smooth operation.

=item name

Localized name of column for labelling purposes

=item type

Display type of info.  May be text, href, input_text, checkbox, or radio.  For a
report, it will typically be text or href.

=item href_base

Base for href.  Only meaningful if type is href

=item class

CSS class (additional) for the column.

=back

=cut

has 'cols' => (is => 'rw', isa => 'ArrayRef[HashRef[Any]]');

=item rows

This is an arrayref of rows.  Each row has fields with keys equal to the col_id
fields of the columns above.

=cut

has 'rows' => (is => 'rw', isa => 'ArrayRef[HashRef[Any]]');

=item format

This is the format, and must be one used by LedgerSMB::Template.  Options
expected for 1.4 out of the box include csv, pdf, ps, xls, and ods.  Other
formats could be supported in the future.  If undefined, defaults html.

=cut

has 'format' => (is => 'rw', isa => 'Maybe[Str]');

=item order_by

The column to order on.  used in providing subtotals also.

=cut

has order_by  => (is => 'rw', isa => 'Maybe[Str]');

=item old_order_by

Previous order by.  Used internally to determine order direction.

=cut

has old_order_by  => (is => 'rw', isa => 'Maybe[Str]');

=item order_dir

either asc, desc, or undef.  used to determine next ordering.

=cut

has order_dir  => (is => 'rw', isa => 'Maybe[Str]');

=item order_url

Url for order redirection.  Interal only.

=cut

has order_url  => (is => 'rw', isa => 'Maybe[Str]');

=item show_subtotals

bool, determines whether to show subtotals.

=cut

has show_subtotals => (is => 'rw', isa => 'Bool');

=item manual_totals

Defaults to false.  Shows totals for all numeric (but not int) columns.
Typically this would be set to true in the run_report function if manual
totals are used.

=cut

has manual_totals => (is => 'rw', isa => 'Bool');

=item buttons

Buttons to show at the bottom of the screen

=cut

has buttons => (is => 'rw', isa => 'ArrayRef[Any]',
                lazy => 1, builder => 'set_buttons');

=item options

List of select boxes for options for buttons.

=cut

has options => (is => 'rw', isa => 'ArrayRef[Any]',
                default => sub {[]} );

=item _locale

Locale to be used for the translation/localization of the report

=cut

has _locale => (is => 'ro',
                default => sub { return $LedgerSMB::App_State::Locale; } );

=back

=head1 METHODS

=over

=item set_buttons

This returns an empty arrayref here but can be overridden by individual
reports.

=cut

sub set_buttons {
    return [];
}

=item _exclude_from_totals

Returns a hashref with the keys pointing to true values for column id's that
should not appear on the total row.

This is useful in avoiding a running total column from being added together and
a meaningless sum displayed on the totals row.

=cut

sub _exclude_from_totals {
    return {};
}


=item render

This takes no arguments and simply renders the report as is.

=cut

sub render {
    my ($self, $request) = @_;
    my $template;


    my $testref = $self->rows;
    $self->run_report($request) if !defined $testref;
    # This is a hook for other modules to use to override the default
    # template --CT
    { # pre-5.14 compatibility block
        local ($@); # pre-5.14, do not die() in this block
        eval {$template = $self->template};
    }
    $template ||= 'Reports/display_report';

    # Sorting and Subtotal logic
    my $url = LedgerSMB::App_State::get_relative_url();
    $self->order_dir('asc') if defined $self->order_by;
    if (defined $self->old_order_by and ($self->order_by eq $self->old_order_by)){
        if (lc($self->order_dir) eq 'asc'){
            $self->order_dir('desc');
        } else {
            $self->order_dir('asc');
        }
    }
    $url =~ s/&?order_by=[^\&]*//g;
    $url =~ s/&?order_dir=[^\&]*//g;
    $self->order_url($url);
    $self->order_url(
        "$url&old_order_by=".$self->order_by."&order_dir=".$self->order_dir
    ) if $self->order_by;

    my $rows = $self->rows;
    @$rows = sort {
                   my $srt_a = $a->{$self->order_by};
                   my $srt_b = $b->{$self->order_by};
                   { # pre-5.14 compatibility block
                       local ($@); # pre-5.14, do not die() in this block
                       $srt_a = $srt_a->to_sort
                           if eval { $srt_a->can('to_sort') };
                       $srt_b = $srt_b->to_sort
                           if eval { $srt_b->can('to_sort') };
                   }
                   no warnings 'numeric';
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
            { # pre-5.14 compatibility block
                local ($@); # pre-5.14, do not die() in this block
                if (eval { $r->{$k}->isa('LedgerSMB::PGNumber') }){
                    $total_row->{$k} ||= LedgerSMB::PGNumber->from_input('0');
                    $total_row->{$k}->badd($r->{$k});
                }
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
    $name = undef unless $request->{format};
    my $columns = $self->show_cols($request);

    for my $col (@$columns){
        if ($col->{money}) {
            $col->{class} = 'money';
            for my $row(@{$self->rows}){
                { # pre-5.14 compatibility block
                    local ($@); # pre-5.14, do not die() in this block
                    if ( eval {$row->{$col->{col_id}}->can('to_output')}){
                        $row->{$col->{col_id}} =
                            $row->{$col->{col_id}}->to_output(money => 1);
                    }
                }
            }
        }
    }

    $template = LedgerSMB::Template->new(
        user => $LedgerSMB::App_State::User,
        locale => $self->locale,
        path => 'UI',
        template => $template,
        output_file => $name,
        format => uc($request->{format} || 'HTML'),
    );
    # needed to get aroud escaping of header line names
    # i.e. ignore_yearends -> ignore\_yearends
    # in latex
    my $replace_hnames = sub {
        my $lines = shift;
        my @newlines = map { { name => $_->{name} } } @{$self->header_lines};
        return [map { { %$_, %{shift @newlines} } } @$lines ];
    };
    $template->render({report => $self,
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

=item show_cols

Returns a list of columns based on selected ones from the report

=cut

sub show_cols {
    my ($self, $request) = @_;
    my @retval;
    for my $ref (@{$self->columns}){
        if ($request->{"col_$ref->{col_id}"}){
            push @retval, $ref;
        }
        if ($ref->{col_id} =~ /bc_\d+/){
            push @retval, $ref if $request->{"col_business_units"};
        }
    }
    if (scalar @retval == 0){
       @retval = @{$self->columns};
    }
    return \@retval;
}

=over

=item none

No start date, end date as first of the month

=item month

Valid for the month selected

=item quarter

Valid for the month selected and the two proceeding ones.

=item year

Valid for a year starting with the month selected.

=back

=cut

sub prepare_input {
    my ($self, $request) = @_;
    # Removing date handling since this is done by
    # LedgerSMB::Report::Dates
    # Question:  Should we move from_amount and to_amount to a role like this
    # instead? --CT
    $request->{from_amount} = LedgerSMB::PGNumber->from_input(
                               $request->{from_amount}
    );
    $request->{to_amount} = LedgerSMB::PGNumber->from_input(
                               $request->{to_amount}
    );
}

=item process_bclasses($ref)

This function processes a ref for a hashref key of business_units, which holds
an array of arrays of (class_id, bu_id) and adds keys in the form of
bc_$class_id holding the $bu_id fields.

=cut
sub process_bclasses {
    my ($self, $ref) = @_;
    for my $bu (@{$ref->{business_units}}){
     if($bu->[1]){#avoid message:Use of uninitialized value in hash element
        push @{$ref->{$bu->[0]}}, $bu->[1]
                 unless grep(/$bu->[1]/, @{$ref->{$bu->[0]}});
     }
    }
}

=back

=head1 WRITING REPORTS

LedgerSMB::Report subclasses are written typically in a few parts:

=over

=item SQL or PL/PGSQL function

=item Criteria Properties

=item Method overrides

=item Main processing function(s)

=back

=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of the LedgerSMB General Public License version 2 or at your option any
later version.  Please see enclosed LICENSE file for details.

=cut

__PACKAGE__->meta->make_immutable;

1;
