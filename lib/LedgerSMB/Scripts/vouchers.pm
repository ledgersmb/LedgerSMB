
package LedgerSMB::Scripts::vouchers;

=head1 NAME

LedgerSMB::Scripts::vouchers - web entry points for voucher/batch workflows

=head1 DESCRIPTION

TODO: This would be a great place to describe the roles and differences
between batches and vouchers...

=head1 SYNPOSIS

 LedgerSMB::Scripts::vouchers::delete_batch($request);

=head1 METHODS

=over

=cut

use strict;
use warnings;

use LedgerSMB::Batch;
use LedgerSMB::Magic qw(BC_AR BC_SALES_INVOICE BC_VENDOR_INVOICE);
use LedgerSMB::Report::Unapproved::Batch_Overview;
use LedgerSMB::Report::Unapproved::Batch_Detail;
use LedgerSMB::Scripts::payment;
use LedgerSMB::Scripts::reports;
use LedgerSMB::Sysconfig;
use LedgerSMB::Template;

use LedgerSMB::old_code qw(dispatch);

use File::Temp;
use HTTP::Status qw( HTTP_OK);


our $VERSION = '0.1';
our $custom_batch_types = {};

{
    local ($!, $@) = (undef, undef);
    my $do_ = 'scripts/custom/vouchers.pl';
    if ( -e $do_ ) {
        unless ( do $do_ ) {
            if ($! or $@) {
                warn "\nFailed to execute $do_ ($!): $@\n";
                die (  "Status: 500 Internal server error (vouchers.pm - first)\n\n" );
            }
        }
    }
};

=item create_batch

Displays the new batch screen.  Required inputs are

=over

=item batch_type

=back

Additionally order_by can be specified for the list of current batches for the
current user.

=cut

sub create_batch {
    my ($request) = @_;
    $request->open_form;
    $request->{hidden} = [
        {name => 'batch_type', value => $request->{batch_type}},
        {name => 'form_id',   value => $request->{form_id}},
        {name => 'overpayment', value => $request->{overpayment}},
    ];

    my $batch = LedgerSMB::Batch->new({base => $request});
    $batch->{class_id} = $batch->get_class_id($batch->{batch_type});
    $batch->get_new_info;

    $batch->get_search_results({mini => 1});

    my $template = LedgerSMB::Template->new(
        user =>$request->{_user},
        locale => $request->{_locale},
        path => 'UI',
        template => 'create_batch',
        format => 'HTML'
    );
    return $template->render({ request => $request,
                                        batch => $batch });
}

=item create_vouchers

Closes the form in the db, and if unsuccessful displays the batch info again.

If successful at closing the form, it saves the batch to the db and redirects to
add_vouchers().

=cut

sub create_vouchers {
    my ($request) = shift @_;
    my $batch = LedgerSMB::Batch->new({base => $request});
    $batch->{batch_class} = $request->{batch_type};
    if ($request->close_form){
        $batch->create;
        return add_vouchers($batch);
    } else {
        $request->{notice} =
            $request->{_locale}->text('Error creating batch.  Please try again.');
        return create_batch($request);
    }
}

=item add_vouchers

Redirects to a script to add vouchers for the type.  batch_type must be set.

=cut

sub _add_vouchers_old {
    my ($request, $entry) = @_;

    return dispatch($entry->{script},
                    $entry->{function},
                    $request);
}

sub add_vouchers {
    my ($request) = shift @_;

    my $batch = LedgerSMB::Batch->new({base => $request});
    our $vouchers_dispatch =
    {
        ap         => {script => 'ap.pl', function => 'add'},
        ar         => {script => 'ar.pl', function => 'add'},
        gl         => {script => 'gl.pl', function => 'add'},
     sales_invoice => {script => 'is.pl', function => 'add'},
    vendor_invoice => {script => 'ir.pl', function => 'add'},
        receipt    => {script => undef,
                 function => sub {
                my ($request) = @_;
                $request->{account_class} = 2;
                return LedgerSMB::Scripts::payment::payments($request);
                }},
        payment   => {script => undef,
                 function => sub {
                my ($request) = @_;
                $request->{account_class} = 1;
                return LedgerSMB::Scripts::payment::payments($request);
                }},
        payment_reversal => {
                      script => undef,
                    function => sub {
                my ($request) = @_;
                $request->{account_class} = 1;
                                if ($request->{overpayment}){
                                    $request->{report_name} = 'overpayments';
                                    return LedgerSMB::Scripts::reports::start_report($request);
                                } else {
                    return LedgerSMB::Scripts::payment::get_search_criteria($request, $custom_batch_types);
                                }
                }},
        receipt_reversal => {
                      script => undef,
                    function => sub {
                my ($request) = @_;
                $request->{account_class} = 2;
                                if ($request->{overpayment}){
                                    $request->{report_name} = 'overpayments';
                                    return LedgerSMB::Scripts::reports::start_report($request);
                                } else {
                       return LedgerSMB::Scripts::payment::get_search_criteria($request, $custom_batch_types);
                                }

                     }},
    };

    $request->{batch_id} = $batch->{id};
    $request->{approved} = 0;
    $request->{transdate} = $request->{batch_date};
    delete $request->{id};

    my $entry = $vouchers_dispatch->{$request->{batch_type}};
    return _add_vouchers_old($request, $entry)
        if defined $entry->{script};

    return $vouchers_dispatch->{$request->{batch_type}}{function}($request);
}

=item list_batches

This function displays the search results.

No inputs are required, but amount_lt and amount_gt can specify range
Also description can be a partial match.

empty specifies only voucherless batches

approved (true or false) specifies whether the batch has been approved

class_id and created_by are exact matches

=cut

sub list_batches {
    my ($request) = @_;
    $request->open_form;
    return LedgerSMB::Report::Unapproved::Batch_Overview->new(
                 %$request)->render($request);
}

=item get_batch

Requires that batch_id is set.

Displays all vouchers from the batch by type, and includes amount.

=cut

sub get_batch {
    my ($request)  = @_;
    $request->open_form;

    $request->{hiddens} = { batch_id => $request->{batch_id} };

    return LedgerSMB::Report::Unapproved::Batch_Detail->new(
                 %$request)->render($request);
}

=item single_batch_approve

Approves the single batch on the details screen.  Batch_id must be set.

=cut

sub single_batch_approve {
    my ($request) = @_;
    delete $request->{language}; # only applicable for printing of batches
    if ($request->close_form){
        my $batch = LedgerSMB::Batch->new(base => $request);
        $batch->post;
        return list_batches($request);
    } else {
        return get_batch($request);
    }
}

=item single_batch_delete

Deletes the single batch on the details screen.  Batch_id must be set.

=cut

sub single_batch_delete {
    my ($request) = @_;
    delete $request->{language}; # only applicable for printing of batches
    if ($request->close_form){
        my $batch = LedgerSMB::Batch->new(base => $request);
        $batch->delete;
        return list_batches($request);
    } else {
        return get_batch($request);
    }
}

=item single_batch_unlock

Unlocks the single batch on the details screen.  Batch_id must be set.

=cut

sub single_batch_unlock {
    my ($request) = @_;
    delete $request->{language}; # only applicable for printing of batches
    if ($request->close_form){
        my $batch = LedgerSMB::Batch->new(base => $request);
        $batch->unlock;
        $request->{report_name} = 'unapproved';
        $request->{search_type} = 'batches';
        return LedgerSMB::Scripts::reports::start_report($request);
    } else {
        return get_batch($request);
    }
}

=item batch_voucher_delete

Deletes selected vouchers.

=cut

sub batch_voucher_delete {
    my ($request) = @_;
    delete $request->{language}; # only applicable for printing of batches
    if ($request->close_form){
        my $batch = LedgerSMB::Batch->new(base => $request);
        for my $count (1 .. $request->{rowcount_}){
            my $voucher_id = $request->{"select_$count"};
            next unless $voucher_id;
            $batch->delete_voucher($voucher_id);
        }
    }
    return get_batch($request);
}

=item batch_approve

Approves all selected batches.

=cut

sub batch_approve {
    my ($request) = @_;
    delete $request->{language}; # only applicable for printing of batches
    if (!$request->close_form){
        list_batches($request);
    }

    my $batch = LedgerSMB::Batch->new(base => $request);
    for my $count (1 .. $batch->{rowcount_}){
        next unless $batch->{'select_' . $count};
        $batch->{batch_id} = $batch->{"row_$count"};
        $batch->post;
    }
    $request->{report_name} = 'unapproved';
    $request->{search_type} = 'batches';
    return LedgerSMB::Scripts::reports::start_report($request);
}

=item batch_unlock

Unlocks selected batches

=cut

sub batch_unlock {
    my ($request) = @_;
    delete $request->{language}; # only applicable for printing of batches
    my $batch = LedgerSMB::Batch->new(base => $request);
    if ($request->{batch_id}){
       $batch->unlock($request->{batch_id});
    } else {
        for my $count (1 .. $batch->{rowcount_}){
            next unless $batch->{'select_' . $count};
            $batch->{batch_id} = $batch->{"row_$count"};
            $batch->unlock($request->{"row_$count"});
        }
    }
    $request->{report_name} = 'unapproved';
    $request->{search_type} = 'batches';
    return LedgerSMB::Scripts::reports::start_report($request);
}

=item batch_delete

Deletes selected batches

=cut

sub batch_delete {
    my ($request)  = @_;
    delete $request->{language}; # only applicable for printing of batches
    if (!$request->close_form){
        return list_batches($request);
    }

    my $batch = LedgerSMB::Batch->new(base => $request);
    for my $count (1 .. $batch->{rowcount_}){
        next unless $batch->{'select_' . $count};
        $batch->{batch_id} = $batch->{"row_$count"};
        $batch->delete;
    }
    $request->{report_name} = 'unapproved';
    $request->{search_type} = 'batches';
    return LedgerSMB::Scripts::reports::start_report($request);
}

=item reverse_overpayment

Adds overpayment reversal vouchers to a batch

=cut

sub reverse_overpayment {
    my ($request) = @_;
    delete $request->{language}; # remove language; setting meant for printing
    my $batch = LedgerSMB::Batch->new(base => $request);
    $batch->get;
    my $a_class;
    for my $count (1 .. $request->{rowcount_}){
        my $id = $request->{"id_$count"};
        $batch->call_procedure(funcname => 'overpayment__reverse',
           args => [$id, $batch->{post_date}, $batch->{id}, $a_class,
                 $request->{cash_accno}, $request->{exchangerate},
                 $request->{curr}]
        ) if $id;
    }
    return LedgerSMB::Scripts::reports::search_overpayments($request);
}

my %print_dispatch = (
   BC_AR() => {
       script => 'ar.pl',
       entrypoint => sub {
           my ($voucher, $request) = @_;
           $lsmb_legacy::form->{ARAP} = 'AR';
           $lsmb_legacy::form->{arap} = 'ar';
           $lsmb_legacy::form->{vc} = 'customer';
           $lsmb_legacy::form->{id} = $voucher->{transaction_id}
                if ref $voucher;
           $lsmb_legacy::form->{formname} = 'ar_transaction';

           lsmb_legacy::create_links();
           $lsmb_legacy::form->{media} = $request->{media};
           lsmb_legacy::print();
       }
    },
    BC_SALES_INVOICE() => {
        script => 'is.pl',
        entrypoint => sub {
            my ($voucher, $request) = @_;
            $lsmb_legacy::form->{formname} = 'invoice';
            $lsmb_legacy::form->{id} = $voucher->{transaction_id}
                               if ref $voucher;

            lsmb_legacy::create_links();
            $lsmb_legacy::form->{media} = $request->{media};
            lsmb_legacy::print();
        }
    },
   BC_VENDOR_INVOICE() => {
       script => 'is.pl',
       entrypoint => sub {
           my ($voucher, $request) = @_;
           $lsmb_legacy::form->{formname} = 'product_receipt';
           $lsmb_legacy::form->{id} = $voucher->{transaction_id}
                if ref $voucher;

           lsmb_legacy::create_links();
           lsmb_legacy::print();
       }
    },
    );

=item print_batch

Prints vouchers of a given batch.  Currently payments, receipts, ap transactions
and gl transactions are not printed.

=cut

sub print_batch {
    my ($request) = @_;
    my $report = LedgerSMB::Report::Unapproved::Batch_Detail->new(%$request);
    $request->{format} = 'pdf';
    $request->{media} = 'zip';

    # Make sure we have a temporary directory which gets cleaned up
    # after exiting this routine
    my $dir = File::Temp->newdir( CLEANUP => 1);
    my $dirname = $dir->dirname;

    # zipdir gets consumed by io.pl and arapprn.pl
    $request->{zipdir} = $dirname;

    $report->run_report;

    my @files =
        map {
            my $entry = $print_dispatch{lc($_->{batch_class_id})};
            if ($entry) {
                dispatch(
                    $entry->{script},
                    $entry->{entrypoint},
                    { %$request },
                    # entrypoint's arguments:
                    $_,
                    $request
                );
                return 1;
            }
            return ();
        }
        @{$report->rows};

    if (@files) {
        my $zipcmd = $LedgerSMB::Sysconfig::zip;
        $zipcmd =~ s/\%dir/$dirname/g;
        `$zipcmd`;

        my $file_path = "$dirname.zip";

        return sub {
            my $responder = shift;

            open my $zip, '<:bytes', $file_path
                or die "Failed to open temporary zip file $file_path : $!";

            $responder->(
                [
                 HTTP_OK,
                 [
                  'Content-Type' => 'application/zip',
                  'Content-Disposition' =>
                      'attachment; filename="batch-'
                      . $request->{batch_id} . '.zip"',
                 ],
                 $zip   # the file-handle
                ]);

            close $zip
                or warn "Failed to close temporary zip file $file_path : $!";
            unlink $file_path
                or warn "Failed to unlink temporary zip file $file_path : $!";
        };
    }
    else {
        return $report->render($request);
    }
}

{
    local ($!, $@) = (undef, undef);
    my $do_ = 'scripts/custom/vouchers.pl';
    if ( -e $do_ ) {
        unless ( do $do_ ) {
            if ($! or $@) {
                warn "\nFailed to execute $do_ ($!): $@\n";
                die (  "Status: 500 Internal server error (vouchers.pm - end)\n\n" );
            }
        }
    }
};


=back

=head1 CUSTOM BATCH TYPES
 custom_batch_types hash provides hooks for handling additional batch types
 beyond the default types.  Entries can be added in a custom file.
 Each entry is a hash, keyed by name, with the following keys:

=over

=item map_to int

maps to another type, not needed for new types in batch_class table

=item select_method

maps to the selection stored proc

=back

  for example:
  $custom_batch_types->{ap_sample} =
      {map_to       => 1,
      select_method => 'custom_sample_ap_select'};

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2009-2018 The LedgerSMB Core Team

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
