=head1 NAME

LedgerSMB::Scripts::transtemplate - Transaction Template Workflows for LedgerSMB

=head1 SYNPOSIS

 LedgerSMB::Scripts::transtemplate::view($request);

=cut

package LedgerSMB::Scripts::transtemplate;

use strict;
use warnings;

use LedgerSMB::DBObject::TransTemplate;
use LedgerSMB::Report::Listings::TemplateTrans;
use LedgerSMB::Template;

use Try::Tiny;

our $VERSION = '0.1';

=head1 ROUTINES

=over

=item view

Views the transaction template.  Requires that id be set.

=cut

sub view {
    my $request = shift @_;
    use LedgerSMB::Form;
    our $template_dispatch =
    {
        '1'         => {script => 'bin/gl.pl',
                       function => sub {$lsmb_legacy::form->{title} = 'Add';
                                        lsmb_legacy::update()}},
        '2'         => {script => 'bin/ar.pl',
                       function => sub {$lsmb_legacy::form->{title} = 'Add';
                                        lsmb_legacy::update()}},
        '3'         => {script => 'bin/ap.pl',
                       function => sub {$lsmb_legacy::form->{title} = 'Add';
                                        lsmb_legacy::update()}},
    };

    my $transtemplate =
        LedgerSMB::DBObject::TransTemplate->new({base => $request});
    $transtemplate->get;
    my $journal_type = $transtemplate->{journal};
    my $script = $template_dispatch->{$journal_type}->{script};
    die "No dispatch entry for type $transtemplate->{$journal_type}"
        unless $script;
    if ($script =~ /^bin/){
        if (my $cpid = fork()) {
            wait;
            return;
        }
        else {
            # We need a 'try' block here to prevent errors being thrown in
            # the inner block from escaping out of the block and missing
            # the 'exit' below.
            try {
                $lsmb_legacy::form = new Form;
                $lsmb_legacy::locale = LedgerSMB::App_State::Locale();
                $lsmb_legacy::form->{dbh} = $request->{dbh};
                $lsmb_legacy::locale = $request->{_locale};
                %lsmb_legacy::myconfig = ();
                %lsmb_legacy::myconfig = %{$request->{_user}};
                $lsmb_legacy::form->{stylesheet} =
                    $lsmb_legacy::myconfig{stylesheet};
                $lsmb_legacy::form->{script} = $script;
                $lsmb_legacy::form->{script} =~ s/(bin|scripts)\///;
                delete $lsmb_legacy::form->{id};

                convert_to_form($transtemplate, $lsmb_legacy::form,
                                $journal_type);
                {
                    no strict;
                    no warnings 'redefine';

                    do $script;
                }
                $template_dispatch->{$journal_type}->{function}($lsmb_legacy::form);
            };
            exit;
        }
    } elsif ($script =~ /scripts/) {
        die "No provision for dispatching to scripts in /scripts";
    }


}

=item convert_to_form

largely private function designed to convert the request object to a Form
object for old code.

=cut

sub convert_to_form{
    my ($trans, $form, $type) = @_;
    my %myconfig;
    $form->{session_id} = $trans->{session_id};
    if ($type eq 1){
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
            my $act = $trans->get_account_info($row->{account_id});
            $form->{"accno_$form->{rowcount}"} =
                       "$act->{accno}--$act->{description}";
            ++$form->{rowcount};
        }
    } else { #ar or ap
        my $meta_number = $trans->{credit_data}->{meta_number};
        $form->{reverse} = 0;
        if ($type eq 2){
            $form->{customer} = $meta_number;
        } else {
            $form->{vendor} = $meta_number;
        }
        $form->{rowcount} = 1;
        for my $row (@{$trans->{line_items}}){
            $form->{"amount_$form->{rowcount}"} = $row->{amount};
        }
    }
    delete $form->{id};
}

=item list

Lists all transaction templates

=cut

sub list {
    my ($request) = @_;
    LedgerSMB::Report::Listings::TemplateTrans->new(%$request)->render($request);
}

=item delete

Delete transaction templates

=cut

sub delete {
    my ($request) = @_;
    my $templates = LedgerSMB::DBObject::TransTemplate->new;

    for my $row ( 1 .. $request->{rowcount_} ) {
        $templates->delete($request->{"row_select_$row"})
            if $request->{"row_select_$row"};
        delete $request->{"row_select_$row"};
    }
    LedgerSMB::Report::Listings::TemplateTrans->new(%$request)->render($request);
}

=back

=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of the LedgerSMB General Public License version 2 or at your option any
later version.  Please see enclosed LICENSE file for details.

=cut

1;
