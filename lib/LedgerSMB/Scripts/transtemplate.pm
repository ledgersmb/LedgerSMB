
package LedgerSMB::Scripts::transtemplate;

=head1 NAME

LedgerSMB::Scripts::transtemplate - Transaction Template Workflows for LedgerSMB

=head1 DESCRIPTION

Entry points for managing transaction templates.

=head1 SYNPOSIS

 LedgerSMB::Scripts::transtemplate::view($request);

=head1 METHODS

This module doesn't specify any methods.

=cut

use strict;
use warnings;

use LedgerSMB::Report::Listings::TemplateTrans;

use LedgerSMB::old_code qw(dispatch);

our $VERSION = '0.1';

=head1 ROUTINES

=over

=item view

Views the transaction template.  Requires that id be set.

=cut

sub _run_update {
    my ($transtemplate, $journal_type) = @_;

    convert_to_form($transtemplate, $lsmb_legacy::form, ## no critic
                    $journal_type);
    $lsmb_legacy::form->{title} = 'Add'; ## no critic

    return lsmb_legacy::update(); ## no critic
}

sub view {
    my $request = shift @_;
    our $template_dispatch =
    {
        '1' => {script => 'gl.pl', function => \&_run_update },
#        '2' => {script => 'ar.pl', function => \&_run_update },
#        '3' => {script => 'ap.pl', function => \&_run_update },
    };

    my ($transtemplate) =
        $request->call_procedure(
            funcname => 'journal__get_entry',
            args     => [ $request->{id} ]);
    $transtemplate->{line_items} = [
        $request->call_procedure(
            funcname => 'journal__lines',
            args     => [ $request->{id} ])
        ];

    my $journal_type = $transtemplate->{journal};
    my $entry = $template_dispatch->{$journal_type};
    my $script = $entry->{script};
    die "No dispatch entry for type $transtemplate->{$journal_type}"
        unless $script;

    return dispatch($script, $entry->{function},
                    $request->{_user},
                    { %$request, script => $script },
                    # $entry->{function}'s arguments:
                    $transtemplate, $journal_type);
}

=item convert_to_form

largely private function designed to convert the request object to a Form
object for old code.

=cut

sub convert_to_form{
    my ($trans, $form, $type) = @_;
    my %myconfig;
    $form->{session_id} = $trans->{session_id};
    if ($type == 1){
        $form->{reference} = $trans->{reference};
        $form->{description} = $trans->{description};
        $form->{rowcount} = 0;
        if (!$form->{reference}){
             $form->{reference} = $form->update_defaults(\%myconfig,'glnumber');
        }
        for my $row (@{$trans->{line_items}}){
            if ($row->{amount} < 0){
                $form->{"debit_$form->{rowcount}"} = $row->{amount} * -1;
            } else {
                $form->{"credit_$form->{rowcount}"} = $row->{amount};
            }
            my ($act) = $form->call_procedure(
                funcname => 'account_get', args => [ $row->{account_id} ]);
            $form->{"accno_$form->{rowcount}"} =
                       "$act->{accno}--$act->{description}";
            ++$form->{rowcount};
        }
    } else { #ar or ap
        my $meta_number = $trans->{credit_data}->{meta_number};
        my $ARAP;

        $form->{reverse} = 0;
        $form->{currency} = $trans->{currency};
        if ($type == 2){
            $form->{customer} = $meta_number;
            $ARAP = 'AR';
        } else {
            $form->{vendor} = $meta_number;
            $ARAP = 'AP';
        }

        $form->{rowcount} = 1;
        for my $row (@{$trans->{line_items}}){
            $form->{"amount_$form->{rowcount}"} = $row->{amount_tc};
            my $account = $trans->get_account_info($row->{account_id});
            $form->{"${ARAP}_amount_1"} = "$account->{accno}--$account->{description}";
            $form->{rowcount}++;
        }
    }
    return delete $form->{id};
}

=item list

Lists all transaction templates

=cut

sub list {
    my ($request) = @_;
    return $request->render_report(
        LedgerSMB::Report::Listings::TemplateTrans->new(
            %$request,
            formatter_options => $request->formatter_options
        ));
}

=item delete

Delete transaction templates

=cut

sub delete {
    my ($request) = @_;

    for my $row ( 1 .. $request->{rowcount_} ) {
        next unless $request->{"row_select_$row"};

        $request->call_procedure(
            funcname => 'journal__delete',
            args     => [ $request->{"row_select_$row"} ]);
        delete $request->{"row_select_$row"};
    }
    return $request->render_report(
        LedgerSMB::Report::Listings::TemplateTrans->new(
            %$request,
            formatter_options => $request->formatter_options
        ));
}

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
