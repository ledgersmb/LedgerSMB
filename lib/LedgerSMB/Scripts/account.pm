
package LedgerSMB::Scripts::account;
use Template;
use LedgerSMB::DBObject::Account;
use LedgerSMB::DBObject::EOY;
use Log::Log4perl;
use strict;
use warnings;

=pod

=head1 NAME

LedgerSMB:Scripts::account, LedgerSMB workflow scripts for managing accounts

=head1 SYNOPSIS

This module contains the workflows for managing chart of accounts entries.

In prior versions of LedgerSMB, these were found in the AM.pm.  In the current
version, these have been broken out and given their own API which is more
maintainable.

=head1 METHODS

=over

=cut


my $logger = Log::Log4perl::get_logger("LedgerSMB::DBObject::Account");


=item new

Displays a screen to create a new account.

=cut

sub new {
    my ($request) = @_;
    $request->{title} = $request->{_locale}->text('Add Account');
    $request->{charttype} = 'A';
    _display_account_screen($request);
}

=item edit

Retrieves account information and then displays the screen.

Requires the id and charttype variables in the request to be set.

=cut

sub edit {
    my ($request) = @_;
    if (!defined $request->{id}){
        $request->error('No ID provided');
    } elsif (!defined $request->{charttype}){
        $request->error('No Chart Type Provided');
    }
    $request->{chart_id} = $request->{id};
    my $account = LedgerSMB::DBObject::Account->new({base => $request});
    my @accounts = $account->get();
    my $acc = shift @accounts;
    if (!$acc){  # This should never happen.  Any occurance of this is a bug.
         $request->error($request->{_locale}->text('Bug: No such account'));
    }
    $acc->{title} = $request->{_locale}->text('Edit Account');
    $acc->{_locale} = $request->{_locale};
    _display_account_screen($acc);
}

=item save

Saves the account.

Request variables
id: (optional):  If set, overwrite existing account.
accno: the text used to specify the account number
description:  Text to describe the account
category: see COMMENT ON COLUMN account.category
gifi_accno:  The GIFI account entry control code
heading: (Optional) The integer representing the heading.id desired
contra:  If true, the account balances on the opposite side.
tax:  If true, is a tax account
link:  a list of strings representing text box identifier.

=cut

sub save {
    my ($request) = @_;
    $request->{parent} = undef if $request->{parent} == -1;
    die $request->{_locale}->text('Please select a valid heading')
       if (defined $request->{heading}
           and $request->{heading} =~ /\D/);
    my $account = LedgerSMB::DBObject::Account->new({base => $request});
    $account->{$account->{summary}}=$account->{summary};
    if ($request->{languagecount} > 0) {
        $account->{translations} = {};
        for my $index (1..$request->{languagecount}) {
            $account->{translations}->{$request->{"languagecode_$index"}}
            = $request->{"languagetranslation_$index"};
        }
    }

    $account->save;
    edit($account);
}

=item save_as_new

Saves as a new account.  Deletes the id field and then calls save()

=cut

sub save_as_new {
    my ($request) = @_;
    $request->{id} = undef;
    save($request);
}

# copied from AM.pm.  To be refactored.
sub _display_account_screen {
    my ($form) = @_;
    my $account = LedgerSMB::DBObject::Account->new({base => $form});
    @{$form->{all_headings}} = $account->list_headings();
    @{$form->{all_gifi}} = $account->gifi_list();
    $form->{recon} = $account->is_recon();
    my $locale = $form->{_locale};
    my $buttons = [];
    my $checked;
    my $hiddens;
    my $logger = Log::Log4perl->get_logger('');
    $logger->debug("scripts/account.pl Locale: $locale");

    foreach my $item ( split( /:/, $form->{link} ) ) {
        $form->{$item} = 1;
    }

    @{$form->{languages}} =
             LedgerSMB->call_procedure(funcname => 'person__list_languages');

    $hiddens->{type} = 'account';
    $hiddens->{$_} = $form->{$_} foreach qw(id inventory_accno_id income_accno_id expense_accno_id fxgain_accno_id fxloss_accno_id);
    $checked->{ $form->{charttype} } = "checked";

    my %button = ();

    if ( $form->{id} ) {
        $button{'save'} =
          { ndx => 3, key => 'S', value => $locale->text('Save'),
           id => 'action_save' };
        $button{'save_as_new'} =
          { ndx => 7, key => 'N', value => $locale->text('Save as new'),
           id => 'action_save_as_new' };

        if ( $form->{orphaned} ) {
            $button{'delete'} =
              { ndx => 16, key => 'D', value => $locale->text('Delete') };
        }
    }
    else {
        $button{'save'} =
          { ndx => 3, key => 'S', value => $locale->text('Save') };
    }

    for ( sort { $button{$a}->{ndx} <=> $button{$b}->{ndx} } keys %button ) {
        push @{$buttons}, {
            name => 'action',
            value => $_,
            accesskey => $button{$_}{key},
            title => "$button{$_}{value} [Alt-$button{$_}{key}]",
            text => $button{$_}{value},
            };
    }

    my $template = LedgerSMB::Template->new(
        user => $form->{_user},
        locale => $locale,
        format => 'HTML',
        path   => 'UI',
        template => 'accounts/edit');
    $template->render({
        form => $form,
        checked => $checked,
        buttons => $buttons,
        hiddens => $hiddens,
    });

}

=item yearend_info

Shows the yearend screen.  No expected inputs.

=cut

sub yearend_info {
    my ($request) = @_;
    my $eoy =  LedgerSMB::DBObject::EOY->new({base => $request});
    $eoy->list_earnings_accounts;
    $eoy->{closed_date} = $eoy->latest_closing;
    $eoy->{user} = $request->{_user};
    my $template = LedgerSMB::Template->new_UI(
        user => $request->{_user},
        locale => $request->{_locale},
        template => 'accounts/yearend'
    );
    $template->render({ request => $request,
                        eoy => $eoy});
}

=item post_yearend

Posts a year-end closing transaction.

Request variables expected:
end_date: Date for the yearend transaction.
reference: GL Source identifier.
description: Description of transaction
in_retention_acc_id: Account id to post retained earnings into

=cut

sub post_yearend {
    my ($request) = @_;
    my $eoy =  LedgerSMB::DBObject::EOY->new({base => $request});
    $eoy->close_books;
    my $template = LedgerSMB::Template->new_UI(
        user => $request->{_user},
        locale => $request->{_locale},
        template => 'accounts/yearend_complete'
    );
    $template->render($eoy);

}

=item reopen_books

This reopens books as of $request->{reopen_date}

=cut

sub reopen_books {
    my ($request) = @_;
    my $eoy =  LedgerSMB::DBObject::EOY->new({base => $request});
    $eoy->reopen_books;
    delete $request->{reopen_date};
    yearend_info($request);
}

=back

=head1 COPYRIGHT

Copyright (C) 2009 LedgerSMB Core Team.  This file is licensed under the GNU
General Public License version 2, or at your option any later version.  Please
see the included License.txt for details.

=cut


1;
