
package LedgerSMB::Scripts::report_aging;

=head1 NAME

LedgerSMB::Scripts::report_aging - Aging Reports and Statements for LedgerSMB

=head1 DESCRIPTION

This module provides AR/AP aging reports and statements for LedgerSMB.

=head1 METHODS

=cut

use LedgerSMB::Template;
use LedgerSMB::Business_Unit;
use LedgerSMB::Legacy_Util;
use LedgerSMB::Report::Aging;
use LedgerSMB::Scripts::reports;
use LedgerSMB::Setting;
use strict;
use warnings;

our $VERSION = '1.0';

=pod

=over

=item run_report

Runs the report and displays it

=cut

sub run_report{
    my ($request) = @_;

    _strip_specials($request);
    $request->{business_units} = [];
    for my $count (1 .. ($request->{bc_count} // 0)){
         push @{$request->{business_units}}, $request->{"business_unit_$count"}
               if $request->{"business_unit_$count"};
    }
    my $report = LedgerSMB::Report::Aging->new(%$request);
    $report->run_report;
    return $report->render($request);
}


=item select_all

Runs a report again, selecting all items

=cut

sub select_all {
    return run_report(@_);
}

=item generate_statement

This generates a statement and sends it off to the printer, the screen, or
email.

=cut

sub generate_statement {
    my ($request) = @_;
    use LedgerSMB::Entity::Company;
    use LedgerSMB::Entity::Credit_Account;
    use LedgerSMB::Entity::Location;
    use LedgerSMB::Entity::Contact;
    _strip_specials($request);

    my $rtype = $request->{report_type}; # in case we need it later
    $request->{report_type} = 'detail'; # needed to generate statement

    my @statements;
    my $old_meta = $request->{meta_number};

    # The reason to work backwards here is that if we are sending emails out, we
    # can hide form submission info and not lose track of where we are.  This
    # will need additional documentation, however.  --CT
    while ($request->{rowcount} > 0){
        my $rc = $request->{rowcount};
        --$request->{rowcount};
        next unless $request->{"select_$rc"};
        my ($meta_number, $entity_id) = split /:/, $request->{"select_$rc"};
        my $company = LedgerSMB::Entity::get($entity_id);
        my $credit_act =
              LedgerSMB::Entity::Credit_Account->get_by_meta_number(
                 $meta_number, $request->{entity_class}
        );
        my ($location) = LedgerSMB::Entity::Location->get_active(
             $request, {entity_id => $entity_id,
                        credit_id => $credit_act->{id},
                       only_class => 1}
        );
        ($location) = LedgerSMB::Entity::Location->get_active(
             $request, {entity_id => $entity_id,
                        credit_id => $credit_act->{id}
                       }
            ) unless defined $location; # select any address if no billing
        my @contact_info = LedgerSMB::Entity::Contact->list(
                 {entity_id => $entity_id, credit_id => $credit_act->{id} }
        );
        $request->{entity_id} = $entity_id;
        my $aging_report = LedgerSMB::Report::Aging->new(%$request);
        $aging_report->run_report;
        my $statement = {
              aging => $aging_report,
             entity => $company,
            address => $location,
           contacts => \@contact_info
        };
        push @statements, $statement;
        last if $request->{media} eq 'email';
    }
    $request->{report_type} = $rtype;
    $request->{meta_number} = $old_meta;
    my $template = LedgerSMB::Template->new(
        path => 'DB',
        locale => $LedgerSMB::App_Date::Locale,
        template => $request->{print_template},
        #language => $language->{language_code}, #TODO
        format => uc $request->{print_format},
        method => $request->{media},
        output_options => {
          filename => 'aging-report.' . lc($request->{print_format})
        }
    );
    if ($request->{media} eq 'email'){

       #TODO -- mailer stuff
       return;

    } elsif ($request->{media} eq 'screen'){
        return $template->render({statements => \@statements});
    } else {
        LedgerSMB::Legacy_Util::render_template($template, {
             statements => \@statements });
        $request->{module_name}='gl';
        $request->{report_type}='aging';
        return LedgerSMB::Scripts::reports::start_report($request);
    }
    # Unreachable
}

sub _strip_specials {
    my $request = shift;
    delete $request->{$_} for (qw(buttons rows _DBH options locale));
    delete $request->{category} if (exists $request->{category} and $request->{category} eq 'X');
    return;
}

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of te GNU General Public License version 2 or at your option any later
version.  Please see included LICENSE.txt for more info.

=cut

1;
