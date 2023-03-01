
package LedgerSMB::Scripts::report_aging;

=head1 NAME

LedgerSMB::Scripts::report_aging - Aging Reports and Statements for LedgerSMB

=head1 DESCRIPTION

This module provides AR/AP aging reports and statements for LedgerSMB.

=head1 METHODS

=cut

use strict;
use warnings;

use HTTP::Status qw( HTTP_OK HTTP_SEE_OTHER );
use Workflow::Context;

use LedgerSMB::Business_Unit;
use LedgerSMB::Entity;
use LedgerSMB::Entity::Company;
use LedgerSMB::Entity::Contact;
use LedgerSMB::Entity::Credit_Account;
use LedgerSMB::Entity::Location;
use LedgerSMB::Legacy_Util;
use LedgerSMB::Magic qw(CC_EMAIL_TO CC_EMAIL_CC CC_EMAIL_BCC
    CC_BILLING_EMAIL_TO CC_BILLING_EMAIL_CC CC_BILLING_EMAIL_BCC);
use LedgerSMB::Report::Aging;
use LedgerSMB::Scripts::reports;
use LedgerSMB::Template;
use LedgerSMB::Template::Sink::Email;
use LedgerSMB::Template::Sink::Printer;
use LedgerSMB::Template::Sink::Screen;

our $VERSION = '1.0';

=pod

=over

=item run_report

Runs the report and displays it

=cut

sub run_report{
    my ($request) = @_;

    $request->{business_units} = [];
    for my $count (1 .. ($request->{bc_count} // 0)){
         push @{$request->{business_units}}, $request->{"business_unit_$count"}
               if $request->{"business_unit_$count"};
    }
    return $request->render_report(
        LedgerSMB::Report::Aging->new(
            %$request,
            language => $request->{_user}->{language},
            languages => $request->enabled_languages
        ));
}


sub _billing_mail_addresses {
    my ($contacts) = @_;

    my (@to, @cc, @bcc);
    # Select billing or regular addresses from the ECA
    for my $class (CC_BILLING_EMAIL_TO, CC_EMAIL_TO) {
        last if @to;
        @to = map { $_->contact }
        grep {
            $_->class_id == $class and $_->credit_id
        } $contacts->@*;
    }
    for my $class (CC_BILLING_EMAIL_CC, CC_EMAIL_CC) {
        last if @cc;
        @cc = map { $_->contact }
        grep {
            $_->class_id == $class and $_->credit_id
        } $contacts->@*;
    }
    for my $class (CC_BILLING_EMAIL_BCC, CC_EMAIL_BCC) {
        last if @bcc;
        @bcc = map { $_->contact }
        grep {
            $_->class_id == $class and $_->credit_id
        } $contacts->@*;
    }
    # Select billing or regular addresses from the entity
    for my $class (CC_BILLING_EMAIL_TO, CC_EMAIL_TO) {
        last if @to;
        @to = map { $_->contact }
        grep {
            $_->class_id == $class and not $_->credit_id
        } $contacts->@*;
    }
    for my $class (CC_BILLING_EMAIL_CC, CC_EMAIL_CC) {
        last if @cc;
        @cc = map { $_->contact }
        grep {
            $_->class_id == $class and not $_->credit_id
        } $contacts->@*;
    }
    for my $class (CC_BILLING_EMAIL_BCC, CC_EMAIL_BCC) {
        last if @bcc;
        @bcc = map { $_->contact }
        grep {
            $_->class_id == $class and not $_->credit_id
        } $contacts->@*;
    }

    return (to => \@to, cc => \@cc, bcc => \@bcc);
}

sub _render_statement_batch {
    my ($request, $wf) = @_;
    my $locale = $request->{_locale};
    my $results = $wf->context->param( 'results' );
    if (scalar($results->@*) == 1) {
        my ($result) = $results->@*;

        return [ HTTP_SEE_OTHER,
                 [ Location => 'email.pl?action=render&id=' . $result->{id} ],
                 [ '' ] ];
    }

    my $wf_id = $wf->id;
    my @columns = (
        {
            col_id    => 'id',
            name      => $locale->text('ID'),
            type      => 'href',
            href_base => "email.pl?action=render&callback=report_aging.pl%3Faction%3Drender_statement_batch%26workflow_id%3D$wf_id&id=",
        },
        {
            col_id => 'name',
            name   => $locale->text('Entity'),
            type   => 'text',
        },
        {
            col_id => 'credit_account',
            name   => $locale->text('Account'),
            type   => 'text',
        },
        {
            col_id => 'status',
            name   => $locale->text('Status'),
            type   => 'text',
        },
        );

    my @buttons = ();

    if (grep { $_ eq 'cancel' } $wf->get_current_actions) {
        push @buttons, {
            name => 'action',
            type => 'submit',
            text => $locale->text('Cancel'),
            value => 'cancel',
        };
    }

    if (grep { $_ eq 'complete' } $wf->get_current_actions) {
        push @buttons, {
            name => 'action',
            type => 'submit',
            text => $locale->text('Complete'),
            value => 'mark_complete',
        };
    }

    my $template = $request->{_wire}->get('ui');
    my $rows = [ $results->@* ];
    for my $row ($rows->@*) {
        $row->{id_href_suffix} = $row->{id};
        my $nested_wf = $request->{_wire}->get('workflows')
            ->fetch_workflow( 'Email' => $row->{id} );
        $row->{status} = $nested_wf->state;
    }
    return $template->render(
        $request,
        'Reports/aging_batch',
        {
            buttons => \@buttons,
            callback => 'report_aging.pl?action=render_statement_batch&workflow_id=' . $request->{workflow_id},
            columns => \@columns,
            HIDDENS => {
                workflow_id => $wf_id,
            },
            SCRIPT  => $request->{script},
            FORM_ID => $request->{form_id},
            hlines => [
                {
                    text => $locale->text('Status'),
                    value => $wf->state,
                },
            ],
            rows    => $rows,
            name    => $locale->text('E-mail aging reminder status'),
        });
}

=item cancel

Cancels the batch processing by cancelling all non-terminated
sub-workflows and renders an overview page.

=cut

sub cancel {
    my ($request) = @_;
    my $wf = $request->{_wire}->get('workflows')->fetch_workflow(
        'Aging statement batch' => $request->{workflow_id}
        );

    for my $result ($wf->context->param( 'results' )->@*) {
        my $nested_wf = $request->{_wire}->get('workflows')
            ->fetch_workflow('Email' => $result->{id});

        if ($nested_wf and
            grep { $_ eq 'Cancel' } $nested_wf->get_current_actions
            ) {
            $nested_wf->execute_action( 'cancel' );
        }
    }

    $wf->execute_action( 'cancel' );
    return _render_statement_batch( $request, $wf );
}

=item mark_complete

Marks the batch processing completed and renders an overview page.

=cut

sub mark_complete {
    my ($request) = @_;
    my $wf = $request->{_wire}->get('workflows')->fetch_workflow(
        'Aging statement batch' => $request->{workflow_id}
        );

    $wf->execute_action( 'complete' );
    return _render_statement_batch( $request, $wf );
}

=item render_statement_batch

This shows an overview of the batch of (e-mail) workflows associated with
aging statements.

=cut

sub render_statement_batch {
    my ($request) = @_;
    my $wf = $request->{_wire}->get('workflows')->fetch_workflow(
        'Aging statement batch' => $request->{workflow_id}
        );

    return _render_statement_batch( $request, $wf );
}

=item generate_statement

This generates a statement and sends it off to the printer, the screen, or
email.

=cut

sub generate_statement {
    my ($request) = @_;

    my $rtype = $request->{report_type}; # in case we need it later
    $request->{report_type} = 'detail'; # needed to generate statement

    my @statements;
    my %filters;
    my %languages;
    while ($request->{rowcount} > 0) {
        my $rc = $request->{rowcount};
        --$request->{rowcount};
        my $row_id = $request->{"select_$rc"};
        next unless $row_id;

        my ($meta_number, $entity_id, $id) = split /:/, $row_id;
        my $eca = "$meta_number:$entity_id";
        $languages{$eca} //= $request->{"language_${row_id}"};
        if (defined $id) {
            $filters{$eca} //= [];
            push $filters{$eca}->@*, $id;
        }
        else {
            $filters{$eca} = 1;
        }
    }

    for my $eca (keys %filters) {
        my ($meta_number, $entity_id) = split /:/, $eca;
        my $company = LedgerSMB::Entity::get($entity_id);
        my $credit_act =
            LedgerSMB::Entity::Credit_Account->new(
                dbh => $request->{dbh},
                entity_class => $request->{entity_class})
            ->get_by_meta_number($meta_number);
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
        my $aging_report = LedgerSMB::Report::Aging->new(
            %$request,
            (ref $filters{$eca}) ? (details_filter => $filters{$eca}) : (),
            languages => $request->enabled_languages,
            entity_id => $entity_id,
            credit_id => $credit_act->id
            );
        $aging_report->run_report($request);
        my $statement = {
              aging => $aging_report,
             entity => $company,
     credit_account => $credit_act,
            address => $location,
           contacts => \@contact_info,
           language => $languages{$eca}
        };
        push @statements, $statement;
    }

    my $format    = uc $request->{print_format};
    my $extension = lc $request->{print_format};
    my $sink;
    if ($request->{media} eq 'email') {
        $sink = LedgerSMB::Template::Sink::Email->new(
            from => $request->setting->get( 'default_email_from' ),
            cc   => $request->setting->get( 'default_email_cc' ),
            bcc  => $request->setting->get( 'default_email_bcc' ),
            );
    }
    elsif ($request->{media} eq 'screen') {
        $sink = LedgerSMB::Template::Sink::Screen->new(
            archive_name => 'aging-report.zip',
            );
    }
    else {
        my $cmd = $request->{_wire}->get( 'printers' )->get( $request->{media} );
        unless ($cmd) {
            die "No printer configured for '$request->{media}'";
        }
        $sink = LedgerSMB::Template::Sink::Printer->new(
            command => $cmd,
            );
    }

    my @results = ();
    for my $statement (@statements) {
        my $template =
            LedgerSMB::Template->new(
                path            => 'DB',
                dbh             => $request->{dbh},
                locale          => $request->{_locale},
                template        => $request->{print_template},
                language        => $statement->{language},
                method          => $request->{media},
                format_plugin   => ($request->{_wire}->get( 'output_formatter' )
                                    ->get( $request->{print_format})),
                );

        $template->render(
            {
                statements => [ $statement ],
                DBNAME     => $request->{company},
            });

        my $wf = $sink->append(
            $template,
            callback       => 'reports.pl?action=start_report&report_name=aging&module_name=gl&entity_class=2',
            filename       => "aging-report.$extension",
            name           => $statement->{entity}->name,
            credit_account => $statement->{credit_account}->description,
            _billing_mail_addresses($statement->{contacts}),
            );

        if ($wf) {
            push @results, {
                id             => $wf->id,
                name           => $statement->{entity}->name,
                credit_account => $statement->{credit_account}->description,
            };
        }
    }

    if (my $sink_output = $sink->render($request)) {
        return $sink_output;
    }

    my $context = Workflow::Context->new(
        results => \@results
        );
    my $wf = $request->{_wire}->get('workflows')
        ->create_workflow( 'Aging statement batch', $context );
    $request->{workflow_id} = $wf->id;

    return _render_statement_batch($request, $wf);
}

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012-2022 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
