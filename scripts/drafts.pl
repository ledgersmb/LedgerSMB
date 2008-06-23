
package LedgerSMB::Scripts::vouchers;
our $VERSION = '0.1';

use LedgerSMB::DBObject::Draft;
use LedgerSMB::Template;
use strict;

sub search {
    my ($request) = @_;
    my $template = LedgerSMB::Template->new(
        user =>$request->{_user}, 
        locale => $request->{_locale},
        path => 'UI',
        template => 'batch/search_transactions',
        format => 'HTML'
    );
    $template->render($request);
}

sub list_drafts {
    my ($request) = @_;
    my $draft= LedgerSMB::Draft->new(base => $request);
    my @search_results = $draft->search;
    $draft->{script} = "drafts.pl";

    my @columns = 
        qw(select id transdate reference description, amount);

    my $base_href = "drafts.pl";
    my $search_href = "$base_href?action=list_transactions";
    my $draft_href= "$base_href?action=get_transaction";

    for my $key (
       qw(class_id approved created_by description amount_gt amount_lt)
    ){
       $search_href .= "&$key=$draft->{key}";
    }

    my %column_heading = (
        'select'          => $draft->{_locale}->text('Select'),
        transaction_total => {
             text => $draft->{_locale}->text('AR/AP/GL Total'),
             href => "$search_href&order_by=transaction_total"
        },
        payment_total     => { 
             text => $draft->{_locale}->text('Paid/Received Total'),
             href => "$search_href&order_by=payment_total"
        },
        description       => {
             text => $draft->{_locale}->text('Description'),
             href => "$search_href&order_by=description"
        },
        control_code      => {
             text => $draft->{_locale}->text('Batch Number'),
             href => "$search_href&order_by=control_code"
        },
        id                => {
             text => $draft->{_locale}->text('ID'),
             href => "$search_href&order_by=control_code"
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
            transaction_total => $draft->format_amount(
                                     amount => $result->{transaction_total}
				),
            payment_total     => $draft->format_amount (
                                     amount => $result->{payment_total}
                                ),
            description => $result->{description},
            control_code => {
                             text  => $result->{control_code},
                             href  => "$draft_href&draft_id=$result->{id}",

            },
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
