=head1 NAME
LedgerSMB::Scripts::budgets

=cut

package LedgerSMB::Scripts::budgets;

use strict;
use warnings;

=head1 SYNOPSYS
Budget workflow scripts.

=head1 REQUIRES

=over

=item LedgerSMB::Budget

=back

=cut

use LedgerSMB::Budget;
use LedgerSMB::Business_Unit;
use LedgerSMB::Business_Unit_Class;

=head1 METHODS

=over

=item new_budget
No inputs provided.  LedgerSMB::Budget properties can be used to set
defaults however.

=cut

sub new_budget {
    my ($request) = @_;
    $request->{rowcount} ||= 0;
    my $budget = LedgerSMB::Budget->from_input($request);
    _render_screen($budget);
}


# Private method _render_screen
# used by new_budget, view_budget, and update
# Prepares and renders screen with budget info.

sub _render_screen {
    my ($budget) = @_;
    my $additional_rows = 5;
    $additional_rows +=20 unless $budget->lines;
    $additional_rows = 0 if $budget->id;
    my $buc = LedgerSMB::Business_Unit_Class->new(
           control_code => '', class_id => 0
    );
    my $bu = LedgerSMB::Business_Unit->new(control_code => '', class_id => 0);
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
        my $lines = $budget->lines;
        push @{$lines},
             {accnoset => 0, index => $_ + $budget->{rowcount}};
        ++$budget->{rowcount};
        $budget->lines($lines);
    }
    $budget->error('Invalid object')
         unless $budget->isa('LedgerSMB::Budget');
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
                 text => $LedgerSMB::App_State::Locale->text('Update'),
                 type => 'submit',
                value => 'update',
                class => 'submit',
             },
             {   name => 'action',
                 text => $LedgerSMB::App_State::Locale->text('Save'),
                 type => 'submit',
                value => 'save',
                class => 'submit',
             },
       ];
     } elsif (!$budget->{approved_by}){
         $budget->{buttons} = [
             {   name => 'action',
                 text => $LedgerSMB::App_State::Locale->text('Approve'),
                 type => 'submit',
                value => 'approve',
                class => 'submit',
             },
             {   name => 'action',
                 text => $LedgerSMB::App_State::Locale->text('Reject'),
                 type => 'submit',
                value => 'reject',
                class => 'submit',
             },
         ];
     } else {
         $budget->{buttons} = [
             {   name => 'action',
                 text => $LedgerSMB::App_State::Locale->text('Obsolete'),
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
    $request->{display_rows} = [];
    for (1 .. $request->{rowcount}){
        push @{$request->{display_rows}},
             { account_id => $request->{"account_id_$_"},
               debit => $request->{"debit_$_"},
               credit => $request->{"credit_$_"},
               description => $request->{"description_$_"},
             } if ($request->{"debit_$_"} or $request->{"credit_$_"});

    }
    $request->{rowcount} = scalar @{$request->{display_rows}} + 1;
    new_budget(@_);
}

=item view_budget
Reuuires id to be set.  Displays a budget for review.

=cut

sub view_budget {
    my ($request) = @_;
    my $budget = LedgerSMB::Budget->new(%$request);
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
                          funcname => 'account_get',
                              args => [$line->{account_id}]
        );
        $row->{account_id} = "$account->{accno}--$account->{description}";
        push @{$budget->{display_rows}}, $row;
    }
    _render_screen($budget);
}

=item save
LedgerSMB::Budget properties required.  Lines represented by
[property]_[line number] notation.

=cut

sub save {
    my ($request) = @_;
    my $budget = LedgerSMB::Budget->from_input($request);
    $budget->save();
    view_budget($budget);
}

=item approve
Requires id.  Approves the budget.

=cut

sub approve {
    my ($request) = @_;
    my $budget = LedgerSMB::Budget->new(%$request);
    $budget->approve;
    view_budget($request);
}

=item reject
Requires id.  Rejects unapproved budget and deletes it.

=cut

sub reject {
    my ($request) = @_;
    my $budget = LedgerSMB::Budget->new(%$request);
    $budget->reject;
    begin_search($request);
}

=item obsolete
Requires id, Marks budget obsolete.

=cut

sub obsolete {
    my ($request) = @_;
    my $budget = LedgerSMB::Budget->new(%$request);
    $budget->obsolete;
    view_budget($request);
}

=item add_note
Requires id, subject, and note.  Adds a note to the budget.

=cut

sub add_note {
    my ($request) = @_;
    my $budget = LedgerSMB::Budget->new(%$request);
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

=back

=head1 SEE ALSO

=over

=item LedgerSMB::Budget

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 LedgerSMB Core Team.  This file is licensed under the GNU
General Public License version 2, or at your option any later version.  Please
see the included License.txt for details.

=cut

1;
