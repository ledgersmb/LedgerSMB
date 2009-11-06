#!/usr/bin/perl

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
use LedgerSMB::Template;
use LedgerSMB::DBObject::TaxForm;
use LedgerSMB::DBObject::Date;
use LedgerSMB::Template;
use LedgerSMB::Form;

=pod

=over

=item __default

Display the filter screen by default.

=back

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

=over

=item add_taxform

Display the "add taxform" view.

=back

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

sub generate_report
{
    my ($request) = @_;
    
    if ($request->{meta_number})
    {
      my @call_args = ($request->{'tax_form_id'}, $request->{begin_month}.' '.$request->{begin_day}.' '.$request->{begin_year}, $request->{end_month}.' '.$request->{end_day}.' '.$request->{end_year}, $request->{meta_number});
      my @results = $request->call_procedure(procname => 'tax_form_details_report', args => \@call_args, );
      for my $r (@results){
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
          template => 'taxform/details_report',
          format => 'HTML'
      );
      $template->render($request);
    } else {
      my @call_args = ($request->{'tax_form_id'}, $request->{begin_month}.' '.$request->{begin_day}.' '.$request->{begin_year}, $request->{end_month}.' '.$request->{end_day}.' '.$request->{end_year});
      my @results = $request->call_procedure(procname => 'tax_form_summary_report', args => \@call_args, );
      for my $r (@results){
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
          template => 'taxform/summary_report',
          format => 'HTML'
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

=head1 Copyright (C) 2007 The LedgerSMB Core Team

Licensed under the GNU General Public License version 2 or later (at your 
option).  For more information please see the included LICENSE and COPYRIGHT 
files.

=cut

eval { do "scripts/custom/taxform.pl"};
1;
