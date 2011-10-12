=pod

=head1 NAME

LedgerSMB:Scripts::drafts, LedgerSMB workflow scripts for managing drafts

=head1 SYNOPSIS

This module contains the workflows for managing unapproved, unbatched financial 
transactions.  This does not contain facities for creating such transactions, 
only searching for them, and posting them to the books or deleting those
which have not been approved yet.
    
=head1 METHODS
        
=over   
        
=cut


package LedgerSMB::Scripts::drafts;
our $VERSION = '0.1';

use LedgerSMB::DBObject::Draft;
use LedgerSMB::Template;
use strict;

=item search

Displays the search filter screen.  No inputs required.

The following inputs are optional and become defaults for the search criteria:

type:  either 'ar', 'ap', or 'gl'
with_accno: Draft transaction against a specific account.
from_date:  Earliest date for match
to_date: Latest date for match
amount_le: total less than or equal to
amount_ge: total greater than or equal to

=cut

sub search {
    my ($request) = @_;
    $request->{class_types} = [
	{text => $request->{_locale}->text('AR'),  value => 'ar'},
	{text => $request->{_locale}->text('AP'),  value => 'ap'},
	{text => $request->{_locale}->text('GL'),  value => 'gl'},
    ];
    my $template = LedgerSMB::Template->new(
        user =>$request->{_user}, 
        locale => $request->{_locale},
        path => 'UI',
        template => 'batch/search_transactions',
        format => 'HTML'
    );
    $template->render($request);
}

=item list_drafts_draft_approve

Required hash entries (global):

rowcount: number of total drafts in the list

Required hash entries:
row_$runningnumber: transaction id of the draft on that row.
draft_$id:  true if selected.


Approves selected drafts.  If close_form fails, does nothing and lists
drafts again.  

=cut


sub list_drafts_draft_approve {
    my ($request) = @_;
    if (!$request->close_form){
        list_drafts($request);
        $request->finalize_request();
    }
    my $draft= LedgerSMB::DBObject::Draft->new(base => $request);
    for my $row (1 .. $draft->{rowcount}){
        if ($draft->{"draft_" .$draft->{"row_$row"}}){
             $draft->{id} = $draft->{"row_$row"};
             $draft->approve;
        }
    }
    search($request);
}


=item list_drafts_draft_delete

Required hash entries (global):

rowcount: number of total drafts in the list

Required hash entries:
row_$runningnumber: transaction id of the draft on that row.
draft_$id:  true if selected.


Deletes selected drafts.  If close_form fails, does nothing and lists
drafts again.  

=cut

sub list_drafts_draft_delete {
    my ($request) = @_;
    if (!$request->close_form){
        list_drafts($request);
        $request->finalize_request();
    }
    my $draft= LedgerSMB::DBObject::Draft->new(base => $request);
    for my $row (1 .. $draft->{rowcount}){
        if ($draft->{"draft_" .$draft->{"row_$row"}}){
             $draft->{id} = $draft->{"row_$row"};
             $draft->delete;
        }
    }
    search($request);
}

=item list_drafts

Searches for drafts and lists those matching criteria:

Required hash variables:

type:  either 'ar', 'ap', or 'gl'


The following inputs are optional and used for filter criteria

with_accno: Draft transaction against a specific account.
from_date:  Earliest date for match
to_date: Latest date for match
amount_le: total less than or equal to
amount_ge: total greater than or equal to

=cut

sub list_drafts {
    my ($request) = @_;
    $request->{action} = 'list_drafts';
    my $draft= LedgerSMB::DBObject::Draft->new(base => $request);
    $draft->close_form;
    $draft->open_form({commit => 1});
    my $callback = 'drafts.pl?action=list_drafts';
    for (qw(type reference amount_gy amount_lt)){
        if (defined $draft->{$_}){
            $callback .= "&$_=$draft->{$_}";
        }
    }
    if ($draft->{order_by}){
        $draft->set_ordering(
		{method => 'draft__search', 
		 column => $draft->{order_by}}
        );
    }
    my @search_results = $draft->search;
    $draft->{script} = "drafts.pl";
    $draft->{callback} = $draft->escape(string => $callback);
    my @columns = 
        qw(select id transdate reference description amount);

    my $base_href = "drafts.pl";
    my $search_href = "$base_href?action=list_drafts";
    my $draft_href= "$base_href?action=get_transaction";

    for my $key (
       qw(type approved created_by description amount_gt amount_lt)
    ){
       $search_href .= "&$key=$draft->{$key}";
    }

    my $column_names = {
        'select' => 'Select',
         amount =>  'AR/AP/GL Total',
         description => 'Description',
         id => 'ID',
         reference => 'Reference',
         transdate => 'Date'
    };
    my $sort_href = "$search_href&order_by";
    my @sort_columns = qw(id transdate reference description amount);
    
    my $count = 0;
    my @rows;
    for my $result (@search_results){
        ++$count;
        $draft->{"row_$count"} = $result->{id};
        push @rows, {
            'select'          => {
                                 input => {
                                           type  => 'checkbox',
                                           value => 1,
                                           name  => "draft_$result->{id}"
                                 }
            },
            amount => $draft->format_amount(
                                     amount => $result->{amount}
				),
            reference => { 
                  text => $result->{reference},
                  href => "$request->{type}.pl?action=edit&id=$result->{id}" .
				"&callback=$draft->{callback}",
            },
            description => $result->{description},
            transdate => $result->{transdate},
            id => $result->{id},
        };
    }
    $draft->{rowcount} = $count;
    my $template = LedgerSMB::Template->new(
        user     => $request->{_user},
        locale   => $request->{_locale},
        path     => 'UI',
        template => 'form-dynatable',
        format   => ($draft->{format}) ? $draft->{format} : 'HTML', 
    );

    my $hiddens = $draft->take_top_level();
    $draft->{rowcount} = "$count";
    delete $draft->{search_results};

    my $column_heading = $template->column_heading($column_names,
        {href => $sort_href, columns => \@sort_columns}
    );

    $template->render({ 
	form    => $draft,
	columns => \@columns,
	heading => $column_heading,
        rows    => \@rows,
        hiddens => $hiddens,
        buttons => [{
                    name  => 'action',
                    type  => 'submit',
                    text  => $request->{_locale}->text('Post'),
                    value => 'draft_approve',
                    class => 'submit',
		},{
                    name  => 'action',
                    type  => 'submit',
                    text  => $request->{_locale}->text('Delete'),
                    value => 'draft_delete',
                    class => 'submit',
               }]
    });
}

=back

=head1 COPYRIGHT

Copyright (C) 2009 LedgerSMB Core Team.  This file is licensed under the GNU 
General Public License version 2, or at your option any later version.  Please
see the included License.txt for details.

=cut


1;
