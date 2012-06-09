=head1 NAME
LedgerSMB::Scripts::vouchers

=head1 SYNPOSIS
Voucher workflow scripts.

#      --CT
=head1 METHODS

=over

=cut

#!/usr/bin/perl


package LedgerSMB::Scripts::vouchers;
our $VERSION = '0.1';

use LedgerSMB::Batch;
use LedgerSMB::Template;
use LedgerSMB::DBObject::Report::Unapproved::Batch_Overview;
use strict;


our $custom_batch_types = {};

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
    $template->render($batch);
}

=item create-vouchers

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
        ap         => {script => 'bin/ap.pl', function => sub {add()}},
        ar         => {script => 'bin/ar.pl', function => sub {add()}},
        gl         => {script => 'bin/gl.pl', function => sub {add()}},
     sales_invoice => {script => 'bin/is.pl', function => sub {add()}},
    vendor_invoice => {script => 'bin/ir.pl', function => sub {add()}},
        receipt    => {script => 'scripts/payment.pl', 
	             function => sub {
				my ($request) = @_;
				$request->{account_class} = 2;
				LedgerSMB::Scripts::payment::payments($request);
				}},
        payment   => {script => 'scripts/payment.pl', 
	             function => sub {
				my ($request) = @_;
				$request->{account_class} = 1;
				LedgerSMB::Scripts::payment::payments($request);
				}},
        payment_reversal => {
                      script => 'scripts/payment.pl',
                    function => sub {
				my ($request) = @_;
				$request->{account_class} = 1;
				LedgerSMB::Scripts::payment::get_search_criteria($request, $custom_batch_types);
				}},
        receipt_reversal => {
                      script => 'scripts/payment.pl',
                    function => sub {
				my ($request) = @_;
				$request->{account_class} = 2;
				LedgerSMB::Scripts::payment::get_search_criteria($request, $custom_batch_types);
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

    } elsif ($script =~ /scripts/) {
	# Maybe we should move this to a require statement?  --CT
         { do $script } 

    }

    $vouchers_dispatch->{$request->{batch_type}}{function}($request);
}

=item search_batch

Displays the search criteria screen.  No inputs required.

=cut

sub search_batch {
    my ($request) = @_;
    my $batch_request = LedgerSMB::Batch->new(base => $request);
    $batch_request->get_search_criteria($custom_batch_types);
    my $template = LedgerSMB::Template->new(
        user     => $request->{_user},
        locale   => $request->{_locale},
        path     => 'UI/batch',
        template => 'filter',
        format   => 'HTML', 
    );
    $template->render($batch_request);
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
    my $report = LedgerSMB::DBObject::Report::Unapproved::Batch_Overview->new(
                 %$request);
    $report->run_report;
    $report->render($request);
        
}

=item get_batch

Requires that batch_id is set.

Displays all vouchers from the batch by type, and includes amount.

=cut

sub get_batch {
    my ($request)  = @_;
    $request->{action} = 'get_batch';
    my $callback = "vouchers.pl?action=get_batch&batch_id=$request->{batch_id}";
    $callback = $request->escape(string => $callback);
    my $batch = LedgerSMB::Batch->new(base => $request);
    $batch->close_form;
    $batch->open_form;
    $batch->{dbh}->commit;
    $batch->{script} = 'vouchers.pl';
    my $rows = [];

    $batch->{id} ||= $batch->{batch_id};
    # $batch->get;
    my @vouchers = $batch->list_vouchers;
    my $edit_base= "batch_id=$batch->{batch_id}&action=edit&callback=$callback";

    my $base_href = "vouchers.pl?action=get_batch&batch_id=$batch->{batch_id}";

    my @columns = qw(selected id description batch_class reference amount date);
    my $column_names = {
        selected => 'Selected',
        id => 'ID',
        description => 'Description',
        batch_class => 'Class',
        amount => 'Amount',
        reference => 'Source/Reference',
        date => 'Date'
    };
    my $sort_href = "$base_href&order_by";
    my @sort_columns = qw(id description batch_class reference amount date);

    my $classcount;
    my $count = 1;
    for my $row (@vouchers) {
       $classcount = ($classcount + 1) % 2;
       $classcount ||= 0;
       my $escript = undef;
       if ($row->{batch_class} eq 'Receivable'){
           $escript = 'ar.pl';
       } elsif ($row->{batch_class} eq 'Payable'){
           $escript = 'ap.pl';
       } elsif ($row->{batch_class} eq 'GL'){
           $escript = 'gl.pl';
       } 
       if (defined $escript){
           $row->{reference} = { 
                     text => $row->{reference},
                     href => "$escript?id=$row->{transaction_id}&"
                             . $edit_base
                     };
       }
       push @$rows, {
           description => $row->{description},
           id          => $row->{id},
           batch_class => $row->{batch_class},
           amount      => $batch->format_amount(amount => $row->{amount}),
           date        => $row->{transaction_date},
           reference   => $row->{reference},
           i           => "$classcount",
           selected    => {
                           input => {
                                  type  => 'checkbox',
                                  name  => "voucher_$row->{id}",
                                  value => "1"
                                  }
                          }  
       };
       $batch->{"row_$count"} = $row->{id};
       ++$count;
    }

    $batch->{rowcount} = $count;

    $batch->{title} = "Batch ID: $batch->{batch_id}";
    my $template = LedgerSMB::Template->new(
        user     => $request->{_user},
        locale   => $request->{_locale},
        path     => 'UI',
        template => 'form-dynatable',
        format   => ($batch->{format}) ? $batch->{format} : 'HTML', 
    );
    my $hiddens = $batch->take_top_level();
    
    my $column_heading = $template->column_heading($column_names,
        {href => $sort_href, columns => \@sort_columns}
    );
    
    $template->render({ 
	form    => $batch,
	columns => \@columns,
	heading => $column_heading,
        rows    => $rows,
        hiddens => $hiddens,
        buttons => [{
                    name  => 'action',
                    type  => 'submit',
                    text  => $request->{_locale}->text('Post Batch'),
                    value => 'batch_approve',
                    class => 'submit',
		},{
                    name  => 'action',
                    type  => 'submit',
                    text  => $request->{_locale}->text('Delete Batch'),
                    value => 'batch_delete',
                    class => 'submit',
		},{
                    name  => 'action',
                    type  => 'submit',
                    text  => $request->{_locale}->text('Delete Vouchers'),
                    value => 'voucher_delete',
                    class => 'submit',
               }]
    });
        
    
}

# alias for batch_delete, needed for form-dynatable
sub list_batches_batch_delete {
    batch_delete(@_);
}

sub get_batch_batch_delete {
    batch_delete(@_);
}

# alias for batch_post, needed for form-dynatable
sub list_batches_batch_approve {
    batch_approve(@_);
}

=item get_batch_batch_approve

Approves the single batch on the details screen.  Batch_id must be set.,

=cut

sub get_batch_batch_approve {
    my ($request) = @_;
    my $batch = LedgerSMB::Batch->new(base => $request);
    if ($batch->close_form){
        $batch->post;
        search_batch($request);
    }
    else {
        get_batch($request);
    }
}

=item get_batch_voucher_delete

Deletes selected vouchers. 

=cut

sub get_batch_voucher_delete {
    my ($request) = @_;
    my $batch = LedgerSMB::Batch->new(base => $request);
    if (!$batch->close_form){
       get_batch($request); 
       $request->finalize_request();
    }
    for my $count (1 .. $batch->{rowcount}){
        my $voucher_id = $batch->{"row_$count"};
        next unless $batch->{"voucher_$voucher_id"};
        $batch->delete_voucher($voucher_id);
    }
    search_batch($request);
}

=item batch_approve

Approves all selected batches.

=cut

sub batch_approve {
    my ($request) = @_;
    my $batch = LedgerSMB::Batch->new(base => $request);
    if (!$batch->close_form){
        list_batches($request);
        $request->finalize_request();
    }
    for my $count (1 .. $batch->{rowcount}){
        next unless $batch->{"batch_" . $batch->{"row_$count"}};
        $batch->{batch_id} = $batch->{"row_$count"};
        $batch->post;
    }
    search_batch($request);
}

=item batch_delete

Deletes selected batches

=cut

sub batch_delete {
    my ($request)  = @_;
    my $batch = LedgerSMB::Batch->new(base => $request);
    if (!$batch->close_form){
        list_batches($request);
        $request->finalize_request();
    }
    for my $count (1 .. $batch->{rowcount}){
        next unless $batch->{"batch_" . $batch->{"row_$count"}};
        $batch->{batch_id} = $batch->{"row_$count"};
        $batch->delete;
    }
    search_batch($request);
}

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
