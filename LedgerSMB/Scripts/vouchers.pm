=head1 NAME
LedgerSMB::Scripts::vouchers

=head1 SYNPOSIS

 LedgerSMB::Scripts::vouchers::delete_batch($request);

=head1 METHODS

=over

=cut

package LedgerSMB::Scripts::vouchers;

use LedgerSMB::Batch;
use LedgerSMB::Template;
use LedgerSMB::Report::Unapproved::Batch_Overview;
use LedgerSMB::Report::Unapproved::Batch_Detail;
use LedgerSMB::Scripts::payment;
use LedgerSMB::Scripts::reports;
use CGI::Simple;

use strict;
use warnings;

our $VERSION = '0.1';
our $custom_batch_types = {};

###TODO-LOCALIZE-DOLLAR-AT
eval { do "scripts/custom/vouchers.pl"};

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
        {name => "batch_type", value => $request->{batch_type}},
        {name => "form_id",   value => $request->{form_id}},
        {name => 'overpayment', value => $request->{overpayment}},
    ];

    my $batch = LedgerSMB::Batch->new({base => $request});
    $batch->{class_id} = $batch->get_class_id($batch->{batch_type});
    $batch->get_new_info;

    if ($batch->{order_by}) {
        $batch->set_ordering({
                method => $batch->get_search_method({mini => 1}),
                column => $batch->{order_by}
        });
    }

    $batch->get_search_results({mini => 1});

    my $template = LedgerSMB::Template->new(
        user =>$request->{_user},
        locale => $request->{_locale},
        path => 'UI',
        template => 'create_batch',
        format => 'HTML'
    );
    $template->render({ request => $request,
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
        add_vouchers($batch);
    } else {
        $request->{notice} =
            $request->{_locale}->text("Error creating batch.  Please try again.");
        create_batch($request);
    }
}

=item add_vouchers

Redirects to a script to add vouchers for the type.  batch_type must be set.

=cut

sub add_vouchers {
    #  This function is not safe for caching as long as the scripts are in bin.
    #  This is because these scripts import all functions into the *current*
    #  namespace.  People using fastcgi and modperl should *not* cache this
    #  module at the moment. -- CT
    #  Also-- request is in 'our' scope here due to the redirect logic.
    our ($request) = shift @_;
    use LedgerSMB::Form;
    my $batch = LedgerSMB::Batch->new({base => $request});
    our $vouchers_dispatch =
    {
        ap         => {script => 'bin/ap.pl', function => sub {lsmb_legacy::add()}},
        ar         => {script => 'bin/ar.pl', function => sub {lsmb_legacy::add()}},
        gl         => {script => 'bin/gl.pl', function => sub {lsmb_legacy::add()}},
     sales_invoice => {script => 'bin/is.pl', function => sub {lsmb_legacy::add()}},
    vendor_invoice => {script => 'bin/ir.pl', function => sub {lsmb_legacy::add()}},
        receipt    => {script => undef,
                 function => sub {
                my ($request) = @_;
                $request->{account_class} = 2;
                LedgerSMB::Scripts::payment::payments($request);
                }},
        payment   => {script => undef,
                 function => sub {
                my ($request) = @_;
                $request->{account_class} = 1;
                LedgerSMB::Scripts::payment::payments($request);
                }},
        payment_reversal => {
                      script => undef,
                    function => sub {
                my ($request) = @_;
                $request->{account_class} = 1;
                                if ($request->{overpayment}){
                                    $request->{report_name} = 'overpayments';
                                    LedgerSMB::Scripts::reports::start_report($request);
                                } else {
                    LedgerSMB::Scripts::payment::get_search_criteria($request, $custom_batch_types);
                                }
                }},
        receipt_reversal => {
                      script => undef,
                    function => sub {
                my ($request) = @_;
                $request->{account_class} = 2;
                                if ($request->{overpayment}){
                                    $request->{report_name} = 'overpayments';
                                    LedgerSMB::Scripts::reports::start_report($request);
                                } else {
                       LedgerSMB::Scripts::payment::get_search_criteria($request, $custom_batch_types);
                                }

                     }},
    };

    our $form = new Form;
    our %myconfig = ();
    %myconfig = %{$request->{_user}};
    $form->{stylesheet} = $myconfig{stylesheet};
    our $locale = $request->{_locale};

    for (keys %$request){
        $form->{$_} = $request->{$_};
    }

    $form->{batch_id} = $batch->{id};
    $form->{approved} = 0;
    $form->{transdate} = $request->{batch_date};

    $request->{batch_id} = $batch->{id};
    $request->{approved} = 0;
    $request->{transdate} = $request->{batch_date};


    my $script = $vouchers_dispatch->{$request->{batch_type}}{script};
    $form->{script} = $script;
    $form->{script} =~ s|.*/||;
    delete $form->{id};
    delete $request->{id};
    if ($script =~ /^bin/){

        # Note that the line below is generally considered incredibly bad form.
        # However, the code we are including is going to require it for now.
        # -- CT
        { no strict; no warnings 'redefine'; do $script; }
        lsmb_legacy::locale($locale);
        lsmb_legacy::form($form);
    }

    $vouchers_dispatch->{$request->{batch_type}}{function}($request);
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
    LedgerSMB::Report::Unapproved::Batch_Overview->new(
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

    LedgerSMB::Report::Unapproved::Batch_Detail->new(
                 %$request)->render($request);
}

=item single_batch_approve

Approves the single batch on the details screen.  Batch_id must be set.

=cut

sub single_batch_approve {
    my ($request) = @_;
    if ($request->close_form){
        my $batch = LedgerSMB::Batch->new(base => $request);
        $batch->post;
        list_batches($request);
    } else {
        get_batch($request);
    }
}

=item single_batch_delete

Deletes the single batch on the details screen.  Batch_id must be set.

=cut

sub single_batch_delete {
    my ($request) = @_;
    if ($request->close_form){
        my $batch = LedgerSMB::Batch->new(base => $request);
        $batch->delete;
        list_batches($request);
    } else {
        get_batch($request);
    }
}

=item single_batch_unlock

Unlocks the single batch on the details screen.  Batch_id must be set.

=cut

sub single_batch_unlock {
    my ($request) = @_;
    if ($request->close_form){
        my $batch = LedgerSMB::Batch->new(base => $request);
        $batch->unlock;
        $request->{report_name} = 'unapproved';
        $request->{search_type} = 'batches';
        LedgerSMB::Scripts::reports::start_report($request);
    } else {
        get_batch($request);
    }
}

=item batch_voucher_delete

Deletes selected vouchers.

=cut

sub batch_voucher_delete {
    my ($request) = @_;
    if ($request->close_form){
        my $batch = LedgerSMB::Batch->new(base => $request);
        for my $count (1 .. $request->{rowcount_}){
            my $voucher_id = $request->{"select_$count"};
            next unless $voucher_id;
            $batch->delete_voucher($voucher_id);
        }
    }
    get_batch($request);
}

=item batch_approve

Approves all selected batches.

=cut

sub batch_approve {
    my ($request) = @_;
    my $batch = LedgerSMB::Batch->new(base => $request);
    if (!$batch->close_form){
        list_batches($request);
    }
    for my $count (1 .. $batch->{rowcount_}){
        next unless $batch->{"select_" . $count};
        $batch->{batch_id} = $batch->{"row_$count"};
        $batch->post;
    }
    $request->{report_name} = 'unapproved';
    $request->{search_type} = 'batches';
    LedgerSMB::Scripts::reports::start_report($request);
}

=item batch_unlock

Unlocks selected batches

=cut

sub batch_unlock {
    my ($request) = @_;
    my $batch = LedgerSMB::Batch->new(base => $request);
    if ($request->{batch_id}){
       $batch->unlock($request->{batch_id});
    } else {
        for my $count (1 .. $batch->{rowcount_}){
            next unless $batch->{"select_" . $count};
            $batch->{batch_id} = $batch->{"row_$count"};
            $batch->unlock($request->{"row_$count"});
        }
    }
    $request->{report_name} = 'unapproved';
    $request->{search_type} = 'batches';
    LedgerSMB::Scripts::reports::start_report($request);
}

=item batch_delete

Deletes selected batches

=cut

sub batch_delete {
    my ($request)  = @_;
    my $batch = LedgerSMB::Batch->new(base => $request);
    if (!$batch->close_form){
        return list_batches($request);
    }
    for my $count (1 .. $batch->{rowcount_}){
        next unless $batch->{"select_" . $count};
        $batch->{batch_id} = $batch->{"row_$count"};
        $batch->delete;
    }
    $request->{report_name} = 'unapproved';
    $request->{search_type} = 'batches';
    LedgerSMB::Scripts::reports::start_report($request);
}

=item reverse_overpayment

Adds overpayment reversal vouchers to a batch

=cut

sub reverse_overpayment {
    my ($request) = @_;
    my $batch = LedgerSMB::Batch->new(base => $request);
    $batch->get;
    my $a_class;
    for (1 .. $request->{rowcount_}){
        my $id = $request->{"id_$_"};
        $batch->call_procedure(funcname => 'overpayment__reverse',
           args => [$id, $batch->{post_date}, $batch->{id}, $a_class,
                 $request->{cash_accno}, $request->{exchangerate},
                 $request->{curr}]
         ) if $id;
    }
    LedgerSMB::Scripts::reports::search_overpayments($request);
}

my %print_dispatch = (
   2 => sub {
               my ($voucher, $request) = @_;
               if (my $cpid = fork()){
                  wait;
               } else {
                  do 'bin/ar.pl';
                  require LedgerSMB::Form;
                  %$lsmb_legacy::form = (%$request);
                  bless $lsmb_legacy::form, 'Form';
                  local $LedgerSMB::App_State::DBH = 0;
                  $lsmb_legacy::form->db_init($LedgerSMB::App_State::User);
                  $lsmb_legacy::form->{ARAP} = 'AR';
                  $lsmb_legacy::form->{arap} = 'ar';
                  $lsmb_legacy::form->{vc} = 'customer';
                  $lsmb_legacy::form->{id} = $voucher->{transaction_id}
                               if ref $voucher;
                  $lsmb_legacy::form->{formname} = 'ar_transaction';
                  $lsmb_legacy::locale = $LedgerSMB::App_State::Locale;

                  lsmb_legacy::create_links();
          $lsmb_legacy::form->{media} = $request->{media};

                  lsmb_legacy::print();
                  exit;
               }
               1;
             },
   1 => sub { 0 },
   8 => sub {
               my ($voucher, $request) = @_;
               if (fork){
                  wait;
               } else {
                  do 'bin/is.pl';
                  require LedgerSMB::Form;
                  %$lsmb_legacy::form = (%$request);
                  bless $lsmb_legacy::form, 'Form';
                  local $LedgerSMB::App_State::DBH = 0;
                  $lsmb_legacy::form->db_init($LedgerSMB::App_State::User);
                  $lsmb_legacy::form->{formname} = 'invoice';
                  $lsmb_legacy::form->{id} = $voucher->{transaction_id}
                               if ref $voucher;

                  lsmb_legacy::create_links();

                  lsmb_legacy::print();
                  exit;
               }
               1;
             },
   9 => sub {
               my ($voucher, $request) = @_;
               if (fork){
                  wait;
               } else {
                  do 'bin/is.pl';
                  require LedgerSMB::Form;
                  %$lsmb_legacy::form = (%$request);
                  bless $lsmb_legacy::form, 'Form';
                  local $LedgerSMB::App_State::DBH = 0;
                  $lsmb_legacy::form->db_init($LedgerSMB::App_State::User);
                  $lsmb_legacy::form->db_init($LedgerSMB::App_State::User);
                  $lsmb_legacy::form->{formname} = 'product_receipt';
                  $lsmb_legacy::form->{id} = $voucher->{transaction_id}
                               if ref $voucher;

                  lsmb_legacy::create_links();

                  lsmb_legacy::print();
                  exit;
               }
               1;
             },
   3 => sub { 0 },
   receipt =>  sub { undef }, # todo, new functionality
   payment =>  sub { undef }, # todo, new functionality
);

=item print_batch

Prints vouchers of a given batch.  Currently payments, receipts, ap transactions
and gl transactions are not printed.

=cut

sub print_batch {
    my ($request) = @_;
    my $report = LedgerSMB::Report::Unapproved::Batch_Detail->new(
                 %$request);
    $request->{format} = 'pdf';
    $request->{media} = 'zip';
    my $dirname = "$LedgerSMB::Sysconfig::tempdir/docs-$request->{batch_id}-" . time;
    mkdir $dirname;

    $request->{zipdir} = $dirname;

    $report->run_report;

    my $cgi = CGI::Simple->new;

    my @files =
      map { my $contents;

            $contents = &{$print_dispatch{lc($_->{batch_class_id})}}($_, $request)
                if $print_dispatch{lc($_->{batch_class_id})};
            $contents ? $contents : (); }
      @{$report->rows};

    if (@files) {
       my $zipcmd = $LedgerSMB::Sysconfig::zip;
       $zipcmd =~ s/\%dir/$dirname/g;

       `$zipcmd`;

       binmode (STDOUT, ':bytes');

       print $cgi->header(
          -type       => 'application/zip',
          -status     => '200',
          -charset    => 'utf-8',
          -attachment => "batch-$request->{batch_id}.zip",
       );

       open ZIP, '<', "$request->{zipdir}.zip";
       binmode (ZIP, ':bytes');
       print <ZIP>;
       close ZIP;


    } else {
       $report->render($request);
    }

}

###TODO-LOCALIZE-DOLLAR-AT
eval { do "scripts/custom/vouchers.pl"};
1;

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

=head1 Copyright (C) 2009, The LedgerSMB core team.

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut
