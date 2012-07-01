=head1 NAME

LedgerSMB::Scripts::reports - Common Report workflows 

=head1 SYNOPSIS

This module holds common workflow routines for reports.

=head1 METHODS

=cut

package LedgerSMB::Scripts::reports;
our $VERSION = '1.0';

use LedgerSMB;
use LedgerSMB::Template;
use LedgerSMB::DBObject::Business_Unit;
use LedgerSMB::DBObject::Business_Unit_Class;
use strict;

=pod

=over

=item start_report

This displays the filter screen for the report.  It expects the following 
request properties to be set:

=over

=item report_name

This is the name of the report

=item module_name

Module name for the report.  This is used in retrieving business units.  If not
set, no business units are retrieved.

=back

Other variables that are set will be passed through to the underlying template.

=cut

sub start_report {
    my ($request) = @_;
    if ($request->{module_name}){
        $request->{class_id} = 0 unless $request->{class_id};
        $request->{control_code} = '' unless $request->{control_code};
        my $buc = LedgerSMB::DBObject::Business_Unit_Class->new(%$request);
        my $bu = LedgerSMB::DBObject::Business_Unit->new(%$request);
        @{$request->{bu_classes}} = $buc->list(1, $request->{module_name});
        for my $bc (@{$request->{bu_classes}}){
            @{$request->{b_units}->{$bc->{id}}}
                = $bu->list($bc->{id}, undef, 0, undef);
            for my $bu (@{$request->{b_units}->{$bc->{id}}}){
                $bu->{text} = $bu->control_code . ' -- '. $bu->description;
            }
        }
    }
    @{$request->{entity_classes}} = $request->call_procedure(
                      procname => 'entity__list_classes'
    );
    @{$request->{all_years}} = $request->call_procedure(
              procname => 'date_get_all_years'
    );
    my $months = LedgerSMB::App_State::all_months();
    $request->{all_months} = $months->{dropdown};
    if (!$request->{report_name}){
        die $request->{_locale}->text('No report specified');
    }
    @{$request->{country_list}} = $request->call_procedure( 
                   ocname => 'location_list_country'
    );
    my $template = LedgerSMB::Template->new(
        user => $request->{_user},
        locale => $request->{_locale},
        path => 'UI/Reports/filters',
        template => $request->{report_name},
        format => 'HTML'
    );
    $template->render($request);
}   

=back

=head1 Copyright (C) 2007 The LedgerSMB Core Team

Licensed under the GNU General Public License version 2 or later (at your 
option).  For more information please see the included LICENSE and COPYRIGHT 
files.

=cut

eval { require LedgerSMB::Scripts::custom::reports };
1;
