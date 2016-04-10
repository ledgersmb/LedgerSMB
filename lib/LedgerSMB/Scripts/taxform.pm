=head1 NAME

LedgerSMB::Scripts::taxform - LedgerSMB handler for reports on tax forms.

=head1 SYNOPSIS

Implement the ability to do end-of-year reporting on vendors as to how
much was recorded as reportable.

1) A summary report vs a detail report. 2) On the summary report, clicking
through brings you to a detail report for that vendor. 3) On the detail
report, clicking through brings you to the contact/account or invoice
information depending on what one clicks.

=head1 METHODS

=cut

package LedgerSMB::Scripts::taxform;

use strict;
use warnings;

use LedgerSMB;
use LedgerSMB::Company_Config;
use LedgerSMB::Template;
use LedgerSMB::DBObject::TaxForm;
use LedgerSMB::DBObject::Date;
use LedgerSMB::Template;
use LedgerSMB::Form;
use LedgerSMB::Report::Taxform::Summary;
use LedgerSMB::Report::Taxform::Details;
use LedgerSMB::Report::Taxform::List;

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

    # Get tax forms.
    my $taxform = LedgerSMB::DBObject::TaxForm->new({base => $request});
    $taxform->get_forms();
    $request->{forms} = $taxform->{forms};
    LedgerSMB::Scripts::reports::start_report($request);
}

=pod

=item add_taxform

Display the "add taxform" screen.

=cut

sub _taxform_screen
{
    my ($request) = @_;
    my $taxform = LedgerSMB::DBObject::TaxForm->new({base => $request});

    $taxform->get_metadata();
    my $template = LedgerSMB::Template->new(
        user =>$request->{_user},
        locale => $request->{_locale},
        path => 'UI',
        template => 'taxform/add_taxform',
        format => 'HTML'
    );
    $template->render($taxform);
}

sub add_taxform {
    _taxform_screen(@_);
}

=item edit

This retrieves and edits a tax form.  Requires that id be set.

=cut

sub edit {
    my ($request) = @_;
    my $tf = LedgerSMB::DBObject::TaxForm->get($request->{id});
    $request->merge($tf);
    _taxform_screen($request);
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

sub _generate_report {
    my ($request) = @_;
    my $report;
    if ($request->{meta_number}){
        $report = LedgerSMB::Report::Taxform::Details->new(%$request);
    } else {
        $report = LedgerSMB::Report::Taxform::Summary->new(%$request);
    }
    return $report;
}


sub generate_report {
    my ($request) = @_;
    die $LedgerSMB::App_State::Locale->text('No tax form selected')
        unless $request->{tax_form_id};
    my $report = _generate_report($request);
    $report->render($request);
}

=item save

Saves a tax form, returns to edit screen.

=cut


sub save
{
    my ($request) = @_;
    my $taxform = LedgerSMB::DBObject::TaxForm->new({base => $request});

    $taxform->save();
    edit($taxform);
}

=item print

Prints the tax forms, using the 1099 templates.

=cut

sub print {
    my ($request) = @_;
    my $taxform = LedgerSMB::DBObject::TaxForm->new({base => $request});
    my $form_info = $taxform->get($request->{tax_form_id});
    $request->{taxform_name} = $form_info->{form_name};
    $request->{format} = 'PDF';
    my $report = LedgerSMB::Report::Taxform::Summary->new(%$request);
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

    # Business settings for 1099
    #
    my $cc = $LedgerSMB::Company_Config::settings;
    $request->{company_name}      = $cc->{company_name};
    $request->{company_address}   = $cc->{company_address};
    $request->{company_telephone} = $cc->{company_phone};
    $request->{my_tax_code}       = $cc->{businessnumber};

    my $template = LedgerSMB::Template->new(
          user => $request->{_user},
          locale => $request->{_locale},
          path => 'UI',
          media => 'screen',
          template => 'taxform/summary_report',
          format => 'PDF',
    );
}

=item list_all

Lists all tax forms.

=cut

sub list_all {
    my $request= shift;
    my $report = LedgerSMB::Report::Taxform::List->new(%$request);
    $report->render($request);
}

=back

=head1 Copyright (C) 2010 The LedgerSMB Core Team

Licensed under the GNU General Public License version 2 or later (at your
option).  For more information please see the included LICENSE and COPYRIGHT
files.

=cut

###TODO-LOCALIZE-DOLLAR-AT
eval { do "scripts/custom/taxform.pl"};
1;
