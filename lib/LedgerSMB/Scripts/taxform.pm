
package LedgerSMB::Scripts::taxform;

=head1 NAME

LedgerSMB::Scripts::taxform - LedgerSMB handler for reports on tax forms.

=head1 DESCRIPTION

Implement the ability to do end-of-year reporting on vendors as to how
much was recorded as reportable.

1) A summary report vs a detail report. 2) On the summary report, clicking
through brings you to a detail report for that vendor. 3) On the detail
report, clicking through brings you to the contact/account or invoice
information depending on what one clicks.

=head1 METHODS

=cut

use strict;
use warnings;

use HTTP::Status qw( HTTP_OK );

use LedgerSMB::Form;
use LedgerSMB::Report::Taxform::Summary;
use LedgerSMB::Report::Taxform::Details;
use LedgerSMB::Report::Taxform::List;
use LedgerSMB::Template;

our $VERSION = '1.0';


=pod

=over

=item report

Display the filter screen.

=cut

sub report {
    use LedgerSMB::Scripts::reports;
    my ($request) = @_;
    $request->{report_name} = 'taxforms';

    $request->{forms} = [
        $request->call_procedure(funcname => 'tax_form__list_all')
        ];
    return LedgerSMB::Scripts::reports::start_report($request);
}

=pod

=item add_taxform

Display the "add taxform" screen.

=cut

sub _taxform_screen
{
    my ($request) = @_;
    $request->{countries} = $request->enabled_countries;
    $request->{default_country} =
        $request->setting->get('default_country');

    my $template = $request->{_wire}->get('ui');
    return $template->render($request, 'taxform/add_taxform', $request);
}

sub add_taxform {
    return _taxform_screen(@_);
}

=item edit

This retrieves and edits a tax form.  Requires that id be set.

=cut

sub edit {
    my ($request) = @_;
    my ($tf) =
        $request->call_procedure(
            funcname => 'tax_form__get', args => [$request->{id}]);
    $request->{$_} = $tf->{$_} for keys %$tf;
    return _taxform_screen($request);
}

=item generate_report

Generates the summary or detail report.   Query inputs (required unless
otherwise specified:

=over

=item begin
Begin date

=item end
End date

=item taxform_id
ID of tax form

=item meta_number (optional)
Vendor or customer account number.  If set, triggers detailed report instead
of summary for all customers/vendors associated with the tax form.

=back

In the future the actual report routines will be wrapped in a taxform_report
package.

=cut

sub generate_report {
    my ($request) = @_;
    die $request->{_locale}->text('No tax form selected')
        unless $request->{tax_form_id};

    my ($tf) =
        $request->call_procedure(
            funcname => 'tax_form__get', args => [$request->{tax_form_id}]);

    my $params = {
        from_date   => $request->parse_date( $request->{from_date} ),
        to_date     => $request->parse_date( $request->{to_date} ),
        tax_form_id => $request->{tax_form_id},
        is_accrual  => $tf->{is_accrual},
        media       => 'screen',
    };
    my @options = (
        {
            name     => 'form_name',
            required => 1,
            options  => [
                {},
                { text => '1099-INT',  value => '1099-INT' },
                { text => '1099-MISC', value => '1099-MISC' },
                ]
        }
    );
    my $report;
    if ($request->{meta_number}){
        $report = LedgerSMB::Report::Taxform::Details->new(
            %$request,
            %$params,
            options => \@options,
            formatter_options => $request->formatter_options,
            );
    } else {
        $report = LedgerSMB::Report::Taxform::Summary->new(
            %$request,
            %$params,
            options => \@options,
            formatter_options => $request->formatter_options,
            );
    }
    $request->{hiddens} = $params;
    return $request->render_report($report);
}

=item save

Saves a tax form, returns to edit screen.

=cut


sub save
{
    my ($request) = @_;

    $request->call_procedure(
        funcname => 'tax_form__save',
        args     => [
            $request->{id},
            $request->{country_id},
            $request->{form_name},
            $request->{default_reportable},
            $request->{is_accrual}
        ]);

    return edit($request);
}

=item print

Prints the tax forms, using the 1099 templates.

=cut

sub print {
    my ($request) = @_;
    my ($taxform) = $request->call_procedure(
        funcname => 'tax_form__get',
        args     => [ $request->{tax_form_id} ]);
    $request->{taxform_name} = $taxform->{form_name};
    $request->{format} = 'PDF';
    my $report = LedgerSMB::Report::Taxform::Summary->new(
        %$request,
        formatter_options => $request->formatter_options,
        from_date  => $request->parse_date( $request->{from_date} ),
        to_date  => $request->parse_date( $request->{to_date} ),
        );
    $report->run_report($request);
    if ($request->{meta_number}){
       my @rows = $report->rows;
       my $inc = 0;
       for (@rows){
           delete $rows[$inc] unless $_->{meta_number} eq $request->{meta_number};
           ++$inc;
       }
       $report->rows(\@rows);
    }
    $request->{results} = $report->rows;

    # Business settings for 1099
    #
    my $cc = $request->{_company_config};
    $request->{SETTINGS}          = $cc;

    my $template = LedgerSMB::Template->new( # printed document
        user     => $request->{_user},
        locale   => $request->{_locale},
        path     => 'DB',
        template => $request->{form_name},
        formatter_options => $request->formatter_options,
        format_plugin   =>
           $request->{_wire}->get( 'output_formatter' )->get( $request->{format}),
    );
    $template->render({ %$request, SETTINGS => $cc });

    my $body = $template->{output};
    utf8::encode($body) if utf8::is_utf8($body);  ## no critic
    my $filename = 'summary_report-' . $request->{tax_form_id} .
        '.' . lc($request->{format});
    return
        [ HTTP_OK,
          [
           'Content-Type' => $template->{mimetype},
           'Content-Disposition' => qq{attachment; filename="$filename"},
          ],
          [ $body ] ];
}

=item list_all

Lists all tax forms.

=cut

sub list_all {
    my $request= shift;
    return $request->render_report(
        LedgerSMB::Report::Taxform::List->new(
            %$request,
            formatter_options => $request->formatter_options
        ));
}

=back


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2010-2022 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
