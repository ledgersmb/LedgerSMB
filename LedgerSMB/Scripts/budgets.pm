=head1 NAME
LedgerSMB::Scripts::budgets

=cut

package LedgerSMB::Scripts::budgets;
use strict;

=head1 SYNOPSYS
Budget workflow scripts.

=head1 REQUIRES

=over

=item LedgerSMB::DBObject::Budget
=item LedgerSMB::DBObject::Budget_Report

=cut

use LedgerSMB::DBObject::Budget;
use LedgerSMB::DBObject::Budget_Report;
use LedgerSMB::DBObject::Business_Unit;
use LedgerSMB::DBObject::Business_Unit_Class;

=head1 METHODS

=over

=item variance_report
Requires id field to be set.

=cut

sub variance_report {
    my ($request) = @_;
    my $report = LedgerSMB::DBObject::Budget_Report->new({base => $request});
    my @rows = $report->run_report();
    my @cols = qw(accno account_label budget_description budget_amount 
               used_amount variance);
    my $heading = {
          budget_description => $request->{_locale}->text('Description'),
                       accno => $request->{_locale}->text('Account Number'),
               account_label => $request->{_locale}->text('Account Label'),
               budget_amount => $request->{_locale}->text('Amount Budgetted'),
                 used_amount => $request->{_locale}->text('- Used'),
                    variance => $request->{_locale}->text('= Variance'),
    };
    my $template = LedgerSMB::Template->new(
        user     => $request->{_user},
        locale   => $request->{_locale},
        path     => 'UI',
        template => 'form-dynatable',
        format   => ($report->{format}) ? $report->{format} : 'HTML',
    );
    $template->render({
           form => $report,
        columns => \@cols,
           rows => \@rows,
        heading => $heading,
    });

}

=item new_budget 
No inputs provided.  LedgerSMB::DBObject::Budget properties can be used to set
defaults however.

=cut

sub new_budget {
    my ($request) = @_;
    my $budget = LedgerSMB::DBObject::Budget->from_input($request);
    _render_screen($budget);
}


# Private method _render_screen
# used by new_budget, view_budget, and update
# Prepares and renders screen with budget info.

sub _render_screen {
    my ($budget) = @_;
    my $additional_rows = 5;
    $additional_rows +=20 unless $budget->{rowcount};
    $additional_rows = 0 if $budget->{id};
    $budget->{class_id} = 0 unless $budget->{class_id};
    $budget->{control_code} = '' unless $budget->{control_code};
    my $buc = LedgerSMB::DBObject::Business_Unit_Class->new(%$budget);
    my $bu = LedgerSMB::DBObject::Business_Unit->new(%$budget);
    @{$budget->{bu_classes}} = $buc->list(1, 'gl');
    for my $bc (@{$budget->{bu_classes}}){
        @{$budget->{b_units}->{$bc->{id}}}
            = $bu->list($bc->{id}, undef, 0, undef);
        for my $bu (@{$budget->{b_units}->{$bc->{id}}}){
            $bu->{text} = $bu->control_code . ' -- '. $bu->description;
        }
    }
    $budget->{rowcount} ||= 0;
    for (1 .. $additional_rows) {
        push @{$budget->{display_rows}}, 
             {accnoset => 0, index => $_ + $budget->{rowcount}};
        ++$budget->{rowcount};
    }
    $budget->error('Invalid object') 
         unless $budget->isa('LedgerSMB::DBObject::Budget');
    # The button logic is kinda complicated here.  The basic idea is that there
    # are three stages in the handling of the budget:  Initial entry, review and
    # approval, and review with the possibility of obsolescence.
    #
    # In the initial entry, there is no budget yet.  Therefore id is not set.
    # One can update the screen and save, but nothing else.
    #
    # Once id is set, if the budget has not been approved, it can be approved or
    # rejected.  Rejecting deletes the budgets in the current implementation,
    # but other options are possible as customizations.
    #
    # Once the budget is approved, it can no longer be deleted.  If
    # circumstances change, however, it can still be marked obsolete.  Obsolete
    # budgets are available for review, but one would not generally run variance
    # reports against them.
    if (!$budget->{id}){
       $budget->{buttons} = [
             {   name => 'action',
                 text => $budget->{_locale}->text('Update'),
                 type => 'submit',
                value => 'update',
                class => 'submit',
             },
             {   name => 'action',
                 text => $budget->{_locale}->text('Save'),
                 type => 'submit',
                value => 'save',
                class => 'submit',
             },
       ];
     } elsif (!$budget->{approved_by}){
         $budget->{buttons} = [
             {   name => 'action',
                 text => $budget->{_locale}->text('Approve'),
                 type => 'submit',
                value => 'approve',
                class => 'submit',
             },
             {   name => 'action',
                 text => $budget->{_locale}->text('Reject'),
                 type => 'submit',
                value => 'reject',
                class => 'submit',
             },
         ];
     } else {
         $budget->{buttons} = [
             {   name => 'action',
                 text => $budget->{_locale}->text('Obsolete'),
                 type => 'submit',
                value => 'obsolete',
                class => 'submit',
             },
        ];
    }
    my $template = LedgerSMB::Template->new(
        user     => $budget->{_user},
        locale   => $budget->{_locale},
        path     => 'UI/budgetting',
        template => 'budget_entry',
        format   => 'HTML'
    );
    $budget->{hiddens} = {
           rowcount => $budget->{rowcount},
                 id => $budget->{id},
    };
    $template->render($budget);
}

=item update
Updates the screen.  Part of initial entry workflow only.

=cut

sub update {
    my ($request) = @_;
    for (1 .. $request->{rowcount}){
        push @{$request->{display_rows}}, 
             { account_id => $request->{"account_id_$_"},
               debit => $request->{"debit_$_"},
               credit => $request->{"credit_$_"},
               description => $request->{"description_$_"},
             } if ($request->{"debit_$_"} or $request->{"credit_$_"});
             
    }
    $request->{rowcount} = scalar @{$request->{display_rows}};
    new_budget(@_); 
}

=item view_budget
Reuuires id to be set.  Displays a budget for review.

=cut

sub view_budget {
    my ($request) = @_;
    my $budget = LedgerSMB::DBObject::Budget->new(%$request);
    $budget = $budget->get($request->{id});
    $budget->{display_rows} = [];
    for my $line (@{$budget->{lines}}){
        my $row = {};
        $row->{description} = $line->{description};
        if ($line->{amount} < 0 ) {
            $row->{debit} = $line->{amount} * -1;
        } else {
            $row->{credit} = $line->{amount};
        }
        my ($account) = $budget->call_procedure( 
                          procname => 'account_get',
                              args => [$line->{account_id}]
        );
        $row->{account_id} = "$account->{accno}--$account->{description}";
        push @{$budget->{display_rows}}, $row;
    }
    _render_screen($budget);
}

=item save
LedgerSMB::DBObject::Budget properties required.  Lines represented by
[property]_[line number] notation.

=cut

sub save {
    my ($request) = @_;
    my $budget = LedgerSMB::DBObject::Budget->from_input($request);
    $budget->save();
    view_budget($budget); 
} 

=item approve
Requires id.  Approves the budget.

=cut

sub approve {
    my ($request) = @_;
    my $budget = LedgerSMB::DBObject::Budget->new(%$request);
    $budget->approve;
    view_budget($request);
} 

=item reject
Requires id.  Rejects unapproved budget and deletes it.

=cut

sub reject {
    my ($request) = @_;
    my $budget = LedgerSMB::DBObject::Budget->new(%$request);
    $budget->reject;
    begin_search($request);
} 

=item obsolete
Requires id, Marks budget obsolete.

=cut

sub obsolete {
    my ($request) = @_;
    my $budget = LedgerSMB::DBObject::Budget->new(%$request);
    $budget->obsolete;
    view_budget($request);
} 

=item add_note
Requires id, subject, and note.  Adds a note to the budget.

=cut

sub add_note {
    my ($request) = @_;
    my $budget = LedgerSMB::DBObject::Budget->new(%$request);
    $budget->save_note($request->{subject}, $request->{note});
    view_budget($request);
} 

=item begin_search
No inputs expected or used

=cut

sub begin_search{
    my ($request) = @_;
    $request->{module_name} = 'gl';
    $request->{report_name} = 'budget_search';
    use LedgerSMB::Scripts::reports;
    LedgerSMB::Scripts::reports::start_report($request);
}

=item search
See LedgerSMB::Budget's search routine for expected inputs.

=cut

sub search {
    my ($request)  = @_;
    my $budget = LedgerSMB::DBObject::Budget->new({base => $request});
    my @rows = $budget->search;
    my $cols = ['start_date',
                'end_date',
                'reference',
                'description',
                'entered_by_name',
                'approved_by_name',
                'obsolete_by_name',
                'department_name',
                'project_number',
    ];
    my $heading = {
                      start_date => $budget->{_locale}->text('Start Date'),
                        end_date => $budget->{_locale}->text('End Date'),
                       reference => $budget->{_locale}->text('Reference'),
                     description => $budget->{_locale}->text('Description'),
                 entered_by_name => $budget->{_locale}->text('Entered by'),
                approved_by_name => $budget->{_locale}->text('Approved By'),
                obsolete_by_name => $budget->{_locale}->text('Obsolete By'),
                 department_name => $budget->{_locale}->text('Department'),
                  project_number => $budget->{_locale}->text('Project'),
    };

    my $base_url = 'budgets.pl';

    for my $row (@rows){
           $row->{reference} = { href => $base_url 
                                         . '?action=view_budget'
                                         . '&id=' . $row->{id},
                                 text => $row->{reference},
                               };
           $row->{start_date} = { href => $base_url
                                          . '?action=variance_report'
                                          . '&id=' . $row->{id},
                                   text => $row->{start_date},
                                 };
           $row->{end_date} = { href => $row->{start_date}->{href},
                                text => $row->{end_date}
                              };

    }
    my $template = LedgerSMB::Template->new(
        user     => $request->{_user},
        locale   => $request->{_locale},
        path     => 'UI',
        template => 'form-dynatable',
        format   => ($budget->{format}) ? $budget->{format} : 'HTML',
    );
    $template->render({
           form => $budget,
        columns => $cols,
           rows => \@rows,
        heading => $heading,
    });
}

=back

=head1 SEE ALSO

=over

=item LedgerSMB::DBObject::Budget
=item LedgerSMB::DBObject::Budget_Report

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 LedgerSMB Core Team.  This file is licensed under the GNU 
General Public License version 2, or at your option any later version.  Please
see the included License.txt for details.

=cut

1;
