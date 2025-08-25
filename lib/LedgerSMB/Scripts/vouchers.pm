
package LedgerSMB::Scripts::vouchers;

=head1 NAME

LedgerSMB::Scripts::vouchers - web entry points for voucher/batch workflows

=head1 DESCRIPTION

TODO: This would be a great place to describe the roles and differences
between batches and vouchers...

=head1 SYNPOSIS

 LedgerSMB::Scripts::vouchers::delete_batch($request);

=head1 METHODS

=cut

use strict;
use warnings;

use LedgerSMB::Batch;
use LedgerSMB::Magic qw(BC_AR BC_SALES_INVOICE BC_VENDOR_INVOICE);
use LedgerSMB::Report::Unapproved::Batch_Overview;
use LedgerSMB::Report::Unapproved::Batch_Detail;
use LedgerSMB::Scripts::payment;
use LedgerSMB::Scripts::reports;

use LedgerSMB::old_code qw(dispatch);

use Archive::Zip qw(:CONSTANTS :ERROR_CODES);
use File::Temp qw/ :seekable /;
use HTTP::Status qw( HTTP_OK);


our $VERSION = '0.1';
our $custom_batch_types = {};


=head2 create_batch($request)

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

    my $batch = LedgerSMB::Batch->new(%$request);
    $batch->{class_id} = $batch->get_class_id($batch->{batch_type});
    $batch->get_new_info;

    $batch->get_search_results({mini => 1});

    my $template = $request->{_wire}->get('ui');
    return $template->render($request, 'create_batch',
                             { request => $request,
                               batch => $batch });
}

=head2 create_vouchers($request)

Creates a new voucher batch, then forwards to C<add_vouchers> to begin
selection of transactions to add to the new batch.

Only proceeds if the form is successfully closed. Otherwise displays the
batch info screen again.

C<$request> is a L<LedgerSMB> object reference.

The request must contain:

=over

=item * dbh

=item * batch_number [stored as the batch control_code]

=item * batch_class  [ar|ap|gl... etc]

=item * batch_date

=item * description

=back

If a new batch is successfully created, C<batch_id> is added to the request.

=cut

sub create_vouchers {
    my ($request) = shift @_;

    unless ($request->close_form) {
        $request->{notice} = $request->{_locale}->text(
            'Error creating batch.  Please try again.'
        );
        return create_batch($request);
    }

    my $batch_data = {
        dbh => $request->{dbh},
        batch_number => $request->{batch_number},
        batch_class => $request->{batch_type},
        batch_date => $request->{batch_date},
        description => $request->{description},
    };
    my $batch = LedgerSMB::Batch->new(%$batch_data);

    $request->{batch_id} = $batch->create;
    return add_vouchers($request);
}

sub _add_vouchers_old {
    my ($request, $entry) = @_;

    $request->{approved} = 0;
    $request->{transdate} = $request->{batch_date};

    return dispatch($entry->{script},
                    $entry->{function},
                    $request->{_user},
                    $request);
}

=head2 add_vouchers($request)

Add vouchers to a batch. Forwards the request to the appropriate
filtering screen according to the type of batch.

C<$request> is a L<LedgerSMB> object reference, which must contain:

=over

=item * dbh

=item * batch_type

Must be one of:
C<ap>, C<ar>, C<gl>, C<sales_invoice>, C<vendor_invoice>, C<receipt>,
C<payment>, C<payment_reversal>, C<receipt_reversal>.

=item * batch_id

=back

C<account_class> is added to the request when C<batch_type> is one of:
C<receipt>, C<payment>, C<payment_reversal>, C<receipt_reversal>.

=cut

sub add_vouchers {
    my ($request) = shift @_;

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
                                    $request->{post_date} = $request->{batch_date};
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
                                    $request->{post_date} = $request->{batch_date};
                                    return LedgerSMB::Scripts::reports::start_report($request);
                                } else {
                       return LedgerSMB::Scripts::payment::get_search_criteria($request, $custom_batch_types);
                                }

                     }},
    };

    my $entry = $vouchers_dispatch->{$request->{batch_type}};
    return _add_vouchers_old($request, $entry)
        if defined $entry->{script};

    return $vouchers_dispatch->{$request->{batch_type}}{function}($request);
}

=head2 list_batches

This endpoint searches for batches and displays the results, by passing the
request to L<LedgerSMB::Report::Unapproved::Batch_Overview>.

The following request parameters are accepted and are optional:

    * class_id
    * description
    * amount_lt
    * amount_gt
    * approved

These may be used to filter the search results. If omitted or set to
C<undef>, they have no effect on the returned results.

See L<LedgerSMB::Report::Unapproved::Batch_Overview> for full details
of these parameters.

=cut

sub list_batches {
    my ($request) = @_;
    $request->open_form;
    return $request->render_report(
        LedgerSMB::Report::Unapproved::Batch_Overview->new(approved => 0,
                                                           %$request,
                                                           formatter_options => $request->formatter_options
        ));
}

=head2 get_batch

Requires that batch_id is set.

Displays all vouchers from the batch by type, and includes amount.

=cut

sub get_batch {
    my ($request)  = @_;
    my $setting =  $request->setting;
    $request->open_form;

    $request->{hiddens} = { batch_id => $request->{batch_id} };

    return $request->render_report(
        LedgerSMB::Report::Unapproved::Batch_Detail->new(
            default_language => $setting->get('default_language'),
            language         => $request->{_user}->{language},
            languages        => $request->enabled_languages,
            %$request,
            formatter_options => $request->formatter_options
        ));
}

=head2 single_batch_approve

Approves the single batch on the details screen.  Batch_id must be set.

=cut

sub single_batch_approve {
    my ($request) = @_;
    delete $request->{language}; # only applicable for printing of batches
    if ($request->close_form){
        my $batch = LedgerSMB::Batch->new(%$request);
        $batch->get;
        $batch->post;
        return list_batches($request);
    } else {
        return get_batch($request);
    }
}

=head2 single_batch_delete

Deletes the single batch on the details screen.  Batch_id must be set.

=cut

sub single_batch_delete {
    my ($request) = @_;
    delete $request->{language}; # only applicable for printing of batches
    if ($request->close_form){
        my $batch = LedgerSMB::Batch->new(%$request);
        $batch->delete;
        return list_batches($request);
    } else {
        return get_batch($request);
    }
}

=head2 single_batch_unlock

Unlocks the single batch on the details screen.  Batch_id must be set.

=cut

sub single_batch_unlock {
    my ($request) = @_;
    delete $request->{language}; # only applicable for printing of batches
    if ($request->close_form){
        my $batch = LedgerSMB::Batch->new(%$request);
        $batch->unlock;
        $request->{report_name} = 'unapproved';
        $request->{search_type} = 'batches';
        return LedgerSMB::Scripts::reports::start_report($request);
    } else {
        return get_batch($request);
    }
}

=head2 batch_vouchers_delete

Deletes selected vouchers.

=cut

sub batch_vouchers_delete {
    my ($request) = @_;
    delete $request->{language}; # only applicable for printing of batches
    if ($request->close_form){
        my $batch = LedgerSMB::Batch->new(%$request);
        for my $count (1 .. $request->{rowcount_}){
            next unless $request->{"select_$count"};
            $batch->delete_voucher($request->{"row_$count"});
        }
    }
    else {
        die 'invalid form token';
    }
    return get_batch($request);
}

=head2 batch_approve

Approves all selected batches.

=cut

sub batch_approve {
    my ($request) = @_;
    delete $request->{language}; # only applicable for printing of batches
    if (!$request->close_form){
        list_batches($request);
    }

    my $batch = LedgerSMB::Batch->new(%$request);
    for my $count (1 .. $batch->{rowcount_}){
        next unless $batch->{'select_' . $count};
        $batch->{batch_id} = $batch->{"row_$count"};
        $batch->get;
        $batch->post;
    }
    $request->{report_name} = 'batches';
    return LedgerSMB::Scripts::reports::start_report($request);
}

=head2 batch_unlock

Unlocks selected batches

=cut

sub batch_unlock {
    my ($request) = @_;
    delete $request->{language}; # only applicable for printing of batches
    my $batch = LedgerSMB::Batch->new(%$request);
    if ($request->{batch_id}){
       $batch->unlock($request->{batch_id});
    } else {
        for my $count (1 .. $batch->{rowcount_}){
            next unless $batch->{'select_' . $count};
            $batch->{batch_id} = $batch->{"row_$count"};
            $batch->unlock($request->{"row_$count"});
        }
    }
    $request->{report_name} = 'batches';
    return LedgerSMB::Scripts::reports::start_report($request);
}

=head2 batch_delete

Deletes selected batches

=cut

sub batch_delete {
    my ($request)  = @_;
    delete $request->{language}; # only applicable for printing of batches
    if (!$request->close_form){
        return list_batches($request);
    }

    foreach my $count (1 .. $request->{rowcount_}){
        if ($request->{"select_$count"}) {
            my $batch = LedgerSMB::Batch->new(
                dbh => $request->{dbh},
                batch_id => $request->{"row_$count"},
            );
            $batch->delete;
        }
    }

    $request->{report_name} = 'batches';
    return LedgerSMB::Scripts::reports::start_report($request);
}

=head2 reverse_overpayment

Adds overpayment reversal vouchers to a batch

=cut

sub reverse_overpayment {
    my ($request) = @_;
    delete $request->{language}; # remove language; setting meant for printing
    my $batch = LedgerSMB::Batch->new(%$request);
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
           $lsmb_legacy::form->{ARAP} = 'AR'; ## no critic
           $lsmb_legacy::form->{arap} = 'ar'; ## no critic
           $lsmb_legacy::form->{vc} = 'customer'; ## no critic
           $lsmb_legacy::form->{id} = $voucher->{transaction_id} ## no critic
                if ref $voucher;
           $lsmb_legacy::form->{formname} = 'ar_transaction'; ## no critic

           lsmb_legacy::create_links(); ## no critic
           $lsmb_legacy::form->{media} = $request->{media}; ## no critic
           lsmb_legacy::print(); ## no critic
       }
    },
    BC_SALES_INVOICE() => {
        script => 'is.pl',
        entrypoint => sub {
            my ($voucher, $request) = @_;
            $lsmb_legacy::form->{formname} = 'invoice'; ## no critic
            $lsmb_legacy::form->{id} = ## no critic
                $voucher->{transaction_id}
                               if ref $voucher;

            lsmb_legacy::create_links(); ## no critic
            $lsmb_legacy::form->{media} = $request->{media}; ## no critic
            lsmb_legacy::print(); ## no critic
        }
    },
   BC_VENDOR_INVOICE() => {
       script => 'is.pl',
       entrypoint => sub {
           my ($voucher, $request) = @_;
           $lsmb_legacy::form->{formname} = 'product_receipt'; ## no critic
           $lsmb_legacy::form->{id} = $voucher->{transaction_id} ## no critic
                if ref $voucher;

           lsmb_legacy::create_links(); ## no critic
           lsmb_legacy::print(); ## no critic
       }
    },
    );

=head2 print_batch

Prints vouchers of a given batch.  Currently payments, receipts, ap transactions
and gl transactions are not printed.

=cut

sub print_batch {
    my ($request) = @_;
    my $report = LedgerSMB::Report::Unapproved::Batch_Detail->new(
        %$request,
        formatter_options => $request->formatter_options,
        language          => $request->{_user}->{language},
        languages         => $request->enabled_languages,
        );
    $request->{format} = 'pdf';
    $request->{media} = 'zip';

    # Make sure we have a temporary directory which gets cleaned up
    # after exiting this routine
    my $dir = File::Temp->newdir( CLEANUP => 1 );
    my $dirname = $dir->dirname;

    # zipdir gets consumed by io.pl and arapprn.pl
    $request->{zipdir} = $dirname;

    $report->run_report($request);

    my @files =
        map {
            my $entry = $print_dispatch{lc($_->{batch_class_id})};
            if ($entry) {
                dispatch(
                    $entry->{script},
                    $entry->{entrypoint},
                    $request->{_user},
                    { %$request },
                    # entrypoint's arguments:
                    $_,
                    $request
                );
            }
            $entry ? 1 : ();
        }
        @{$report->rows};

    if (@files) {
        my $zip = Archive::Zip->new;
        unless ( $zip->addTree("$dirname/.", '') == AZ_OK ) {
            die 'Unable to add vouchers from temporary directory to zip file';
        };
        my $fh = File::Temp->new( CLEANUP => 1 );
        unless ( $zip->writeToFileHandle( $fh, 1 ) == AZ_OK ) {
            die 'Unable to write voucher zip output to temporary file';
        }
        $fh->seek( 0, 0 );

        return sub {
            my $responder = shift;
            $responder->(
                [
                 HTTP_OK,
                 [
                  'Content-Type' => 'application/zip',
                  'Content-Disposition' =>
                      'attachment; filename="batch-'
                      . $request->{batch_id} . '.zip"',
                 ],
                 $fh   # the file-handle
                ]);
        };
    }
    else {
        return $request->render_report($report);
    }
}

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

Copyright (C) 2009-2022 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
