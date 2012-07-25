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
with 'LedgerSMB::DBObject_Moose';
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

=item buttons 

Buttons to show at the bottom of the screen

=cut

has buttons => (is => 'rw', isa => 'ArrayRef[Any]');

=back

=head1 METHODS

=over

=item render

This takes no arguments and simply renders the report as is.

=cut

sub render {
    my ($self, $request) = @_;
    my $template;

    my $testref = $self->rows;
    $self->run_report if !defined $testref;
    # This is a hook for other modules to use to override the default
    # template --CT
    eval {$template = $self->template};
    $template ||= 'Reports/display_report';

    # Sorting and Subtotal logic
    my $url = LedgerSMB::App_State::get_url();
    if ($self->order_by eq $self->old_order_by){
        if (lc($self->order_dir) eq 'asc'){
            $self->order_dir('desc');
        } else {
            $self->order_dir('asc');
        }
    }
    $url =~ s/&?order_by=[^\&]*/$1/g;
    $url =~ s/&?order_dir=[^\&]*/$1/g;
    $self->order_url(
        "$url&old_order_by=".$self->order_by."&order_dir=".$self->order_dir
    );

    my $rows = $self->rows;
    @$rows = sort {$a->{$self->order_by} cmp $b->{$self->order_by}} @$rows
      if $self->order_by;
    if (lc($self->order_dir) eq 'desc' and $self->order_by) {
        @$rows = reverse @$rows;
    }
    $self->rows($rows);
    if ($self->show_subtotals){
        my @newrows;
        my $subtotals = {html_class => 'subtotal'};
        for my $col ({eval $self->subtotal_on}){
           $subtotals->{$col} = 0;
        }
        my $col_val = undef;
        for my $r (@{$self->rows}){
            if (defined $col_val and ($col_val ne $r->{$self->order_by})){
                push @newrows, $subtotals;
                $subtotals = {html_class => 'subtotal'};
                for my $col ({eval $self->subtotal_on}){
                    $subtotals->{$col} = 0;
                }
            }
            for my $col ({eval $self->subtotal_on}){
                $subtotals->{$col} += $r->{$col};
            }
            push @newrows, $r;
        }
   } 
    
    # Rendering

    if (!defined $self->format){
        $self->format('html');
    }
    $template = LedgerSMB::Template->new(
        user => $LedgerSMB::App_State::User,
        locale => $LedgerSMB::App_State::Locale,
        path => 'UI',
        template => $template,
        format => uc($request->{format} || 'HTML'),
    );
    $template->render({report => $self, 
                      request => $request,
                         name => $self->name,
                       hlines => $self->header_lines,
                      columns => $self->show_cols($request), 
                    order_url => $self->order_url,
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
    if ($request->{from_month} and $request->{year}){
        my $interval = $self->get_interval_dates(
                                                  $request->{year}, 
                                                  $request->{from_month}, 
                                                  $request->{interval}
        );
        $request->{from_date} = $interval->{start};
        $request->{to_date} = $interval->{end};
    } else {
        $request->{from_date} = LedgerSMB::PGDate->from_input(
                                   $request->{from_date}
        );
        $request->{date_to} = LedgerSMB::PGDate->from_input(
                                   $request->{date_to}
        );
    }
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
        push @{$ref->{$bu->[0]}}, $bu->[1] 
                 unless grep(/$bu->[1]/, @{$ref->{$bu->[0]}});
    }
}

=back

=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of the LedgerSMB General Public License version 2 or at your option any
later version.  Please see enclosed LICENSE file for details.

=cut

__PACKAGE__->meta->make_immutable;
return 1;
