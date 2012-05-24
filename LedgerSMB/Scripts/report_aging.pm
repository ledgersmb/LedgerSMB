=head1 NAME

LedgerSMB::Scripts::report_aging - Aging Reports and Statements for LedgerSMB

=head1 SYNOPSIS

This module provides AR/AP aging reports and statements for LedgerSMB.

=head1 METHODS

=cut

package LedgerSMB::Scripts::report_aging;
our $VERSION = '1.0';

use LedgerSMB;
use LedgerSMB::Template;
use LedgerSMB::DBObject::Business_Unit;
use LedgerSMB::DBObject::Report::Aging;
use strict;

=pod

=item run_report

Runs the report and displays it

=cut

sub run_report{
    my ($request) = @_;

    delete $request->{category} if ($request->{category} = 'X');
    $request->{business_units} = [];
    for my $count (1 .. $request->{bc_count}){
         push @{$request->{business_units}}, $request->{"business_unit_$count"}
               if $request->{"business_unit_$count"};
    }
    LedgerSMB::DBObject::Report::Aging->prepare_criteria($request);
    my $report = LedgerSMB::DBObject::Report::Aging->new(%$request);
    $report->run_report;
    $report->render($request);
}


=item select_all

Runs a report again, selecting all items

=cut

sub select_all {
    run_report(@_);
}

=item THE FOLLOWING ARE TODO

=item retrieve_statement

=item print_statement

=item email_screen

=item email_statement
