=head1 NAME

LedgerSMB::DBObject::Report - Base Reporting Functionality for LedgerSMB

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

=head1 INHERITS

=over

=item LedgerSMB::DBObject_Moose

=back

=cut

package LedgerSMB::DBObject::Report;
use Moose;
extends 'LedgerSMB::DBObject_Moose';
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

=back

=head1 METHODS

=over

=item render

This takes no arguments and simply renders the report as is.

=cut

sub render {
    my ($self, $request) = @_;
    my $template;

    # This is a hook for other modules to use to override the default
    # template --CT
    eval {$template = $self->template};
    $template ||= 'Reports/display_report';

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
    }
    if (scalar @retval == 0){
       @retval = @{$self->columns};
    }
    return \@retval;
}

=back

=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of the LedgerSMB General Public License version 2 or at your option any
later version.  Please see enclosed LICENSE file for details.

=cut

__PACKAGE__->meta->make_immutable;
return 1;
