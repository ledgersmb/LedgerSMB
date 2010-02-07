
package LedgerSMB::Scripts::drafts;
our $VERSION = '0.1';

use LedgerSMB::DBObject::Draft;
use LedgerSMB::Template;
use strict;

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

sub list_drafts_draft_approve {
    my ($request) = @_;
    if (!$request->close_form){
        list_drafts($request);
        exit;
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

sub list_drafts_draft_delete {
    my ($request) = @_;
    if (!$request->close_form){
        list_drafts($request);
        exit;
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

sub list_drafts {
    my ($request) = @_;
    my $draft= LedgerSMB::DBObject::Draft->new(base => $request);
    $draft->close_form;
    $draft->open_form;
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

    my %column_heading = (
        'select'          => $draft->{_locale}->text('Select'),
        amount => {
             text => $draft->{_locale}->text('AR/AP/GL Total'),
             href => "$search_href&order_by=amount"
        },
        description       => {
             text => $draft->{_locale}->text('Description'),
             href => "$search_href&order_by=description"
        },
        id                => {
             text => $draft->{_locale}->text('ID'),
             href => "$search_href&order_by=id"
        },
        reference         => {
             text => $draft->{_locale}->text('Reference'),
             href => "$search_href&order_by=reference"
        },
        transdate          => {
             text => $draft->{_locale}->text('Date'),
             href => "$search_href&order_by=transdate"
        },
    );
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

    $template->render({ 
	form    => $draft,
	columns => \@columns,
	heading => \%column_heading,
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



sub delete_drafts {
    my ($request) = @_;
}
