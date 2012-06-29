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
our $VERSION = '1.0';

use strict;
use LedgerSMB;
use LedgerSMB::Company_Config;
use LedgerSMB::Template;
use LedgerSMB::DBObject::TaxForm;
use LedgerSMB::DBObject::Date;
use LedgerSMB::Template;
use LedgerSMB::Form;
use LedgerSMB::DBObject::Vendor;

=pod

=over

=item __default

Display the filter screen by default.

=cut

sub __default {
    my ($request) = @_;
    my $template;
    my %hits = ();
    
    $template = LedgerSMB::Template->new(
            path => 'UI/taxform',
            template => 'filter',
	    format => 'HTML',
    );
    
    # Get tax forms.
    my $taxform = LedgerSMB::DBObject::TaxForm->new({base => $request});
    $taxform->get_forms();
    $request->{forms} = $taxform->{forms};
    
    # Lets build filter by period
    my $locale = $request->{_locale};
    my $date = LedgerSMB::DBObject::Date->new({base => $request});
    $date->build_filter_by_period($locale);
    
    $request->{all_years} = $date->{yearsOptions};
    $request->{accountingmonths} = $date->{monthsOptions};
    $request->{days} = $date->{daysOptions};
    
    $template->render($request);
}

=pod

=item add_taxform

Display the "add taxform" screen.

=cut

sub add_taxform 
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
    if (!$request->{format}){
       $request->{format} = 'HTML';
    }

    # Business settings for 1099
    #
    my $cc = $LedgerSMB::Company_Config::settings;
    $request->{company_name}      = $cc->{company_name};
    $request->{company_address}   = $cc->{company_address};
    $request->{company_telephone} = $cc->{company_phone};
    $request->{my_tax_code}       = $cc->{businessnumber};
    # TODO:  Eliminate duplicate code!
    if ($request->{meta_number}) {
      my @call_args = ($request->{'tax_form_id'},
                       $request->{begin_year}.'-'.$request->{begin_month}.'-'.$request->{begin_day}, $request->{end_year}.'-'.$request->{end_month}.'-'.$request->{end_day}, 
                       $request->{meta_number});
                       
      my @results = $request->call_procedure(procname => 'tax_form_details_report', args => \@call_args);
      my $credit_id;
      for my $r (@results){
          $r->{acc_sum} = $request->format_amount({amount => $r->{acc_sum}});
          $r->{invoice_sum} = 
               $request->format_amount({amount => $r->{invoice_sum}});
          ($request->{total_sum}) ? $request->{total_sum} + $r->{total_sum}
                                  : $r->{total_sum};
          $r->{total_sum} = $request->format_amount({amount => $r->{total_sum}});
          $credit_id = $r->{credit_id};
      }
      $request->{total_sum} = $request->format_amount(
                                      {amount => $request->{total_sum}}
      ) || '0';
      #XXX Please note, the line below is a kludge because we don't support
      # generic companies at present on instantiation.  This means I have to 
      # specify that this is either a customer or vendor.  Right now I am 
      # specifying as a vendor.  This should have no effect on subsequent code
      # but if this is somethign we end up depending on, we need to fix it.
      my $company = LedgerSMB::DBObject::Vendor->new(base => $request);
      $company->{id} = $credit_id;
      $company->get_billing_info;
      delete $company->{id}; 
      $request->merge($company);
      $request->{results} = \@results;
      $request->debug({file=>'/tmp/taxformdebug'});
      
      my $template = LedgerSMB::Template->new(
          user => $request->{_user}, 
          locale => $request->{_locale},
          path => 'UI',
          media => 'screen',
          template => 'taxform/details_report',
          format => $request->{format},
      );
      $template->render($request);
    } 
    else {
        
        my @call_args = ($request->{'tax_form_id'}, $request->{begin_year}.'-'.$request->{begin_month}.'-'.$request->{begin_day}, $request->{end_year}.'-'.$request->{end_month}.'-'.$request->{end_day});
        my @results = $request->call_procedure(procname => 'tax_form_summary_report', args => \@call_args);
        for my $r (@results){
            my $company = LedgerSMB::DBObject::Vendor->new(base => $request);
            $company->{id} = $r->{credit_id};
            $company->get_billing_info;
            delete $company->{id};
            for my $k (keys %$company){
                 $r->{$k} = $company->{$k};
            }
 
            $r->{acc_sum} = $request->format_amount({amount => $r->{acc_sum}});
            $r->{invoice_sum} = 
                 $request->format_amount({amount => $r->{invoice_sum}});
            $r->{total_sum} = $request->format_amount({amount => $r->{total_sum}});
        }
        $request->{results} = \@results;
        
        my $template = LedgerSMB::Template->new(
            user => $request->{_user}, 
            locale => $request->{_locale},
            path => 'UI',
            media => 'screen',
            template => 'taxform/summary_report',
            format => $request->{format},
        );
        $template->render($request);
    }
}

sub save
{
    my ($request) = @_;
    my $taxform = LedgerSMB::DBObject::TaxForm->new({base => $request}); 
    
    $taxform->save();
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

=item print

Prints the tax forms, using the 1099 templates.

=cut

sub print {
    my ($request) = @_;
    my $taxform = LedgerSMB::DBObject::TaxForm->new({base => $request});
    my $form_info = $taxform->get($request->{tax_form_id});
    $request->{taxform_name} = $form_info->{form_name};
    $request->{format} = 'PDF';
    generate_report($request);    
}

=item list_all

Lists all tax forms.

=cut

sub list_all {
    my ($request) = @_;

    my $locale = $request->{_locale};
    $request->{title} = $locale->text('Tax Form List');

    my $taxform = LedgerSMB::DBObject::TaxForm->new({base => $request});
    my @rows = $taxform->get_full_list;
    my $template = LedgerSMB::Template->new(
        user => $request->{_user},
        template => 'form-dynatable',
        locale => $request->{_locale},
        path => 'UI',
        format => 'HTML'
    );
    
    my @columns = qw(form_name country_name default_reportable);
    my $heading = {form_name => $locale->text('Tax Form Name'),
                country_name => $locale->text('Country'),
          default_reportable => $locale->text('Default Reportable')};
    for my $r (@rows){
        $r->{form_name} = { text => $r->{form_name},
                            href => "taxform.pl?action=add_taxform&id=$r->{id}".
                                    "&country_id=$r->{country_id}".
                                    "&form_name=$r->{form_name}".
                                 "&default_reportable=$r->{default_reportable}",
                          };
        if ($r->{default_reportable}){
            $r->{default_reportable} = $locale->text('Yes');
        } else {
            $r->{default_reportable} = $locale->text('No');
        }
    }
    $template->render({
        form => $request,
     columns => \@columns,
     heading => $heading,
        rows => \@rows,
    });
}

=back

=head1 Copyright (C) 2010 The LedgerSMB Core Team

Licensed under the GNU General Public License version 2 or later (at your 
option).  For more information please see the included LICENSE and COPYRIGHT 
files.

=cut

eval { do "scripts/custom/taxform.pl"};
1;
