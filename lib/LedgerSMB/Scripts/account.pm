
package LedgerSMB::Scripts::account;

=head1 NAME

LedgerSMB:Scripts::accounts - web entry points for managing GL accounts

=head1 DESCRIPTION

This module contains the workflows for managing chart of accounts entries.

In prior versions of LedgerSMB, these were found in the AM.pm.  In the current
version, these have been broken out and given their own API which is more
maintainable.

=head1 METHODS

=over

=cut

use strict;
use warnings;

use Log::Log4perl;

use LedgerSMB;
use LedgerSMB::DBObject::Account;
use LedgerSMB::DBObject::EOY;
use LedgerSMB::Template::UI;


=item new_account

Displays a screen to create a new account.

=cut

sub new_account {
    my ($request) = @_;

    my $account = LedgerSMB::DBObject::Account->new({base => {
        dbh => $request->{dbh},
        charttype => 'A',
    }});

    return _display_account_screen($request, $account);
}

=item new_heading

Displays a screen to create a new Chart of Accounts heading.

=cut

sub new_heading {
    my ($request) = @_;

    my $account = LedgerSMB::DBObject::Account->new({base => {
        dbh => $request->{dbh},
        charttype => 'H',
    }});

    return _display_account_screen($request, $account);
}

=item edit

Retrieves account information and then displays the screen.

Requires the id and charttype variables in the request to be set.

=cut

sub edit {
    my ($request) = @_;

    my $account = LedgerSMB::DBObject::Account->new({base => {
        dbh => $request->{dbh},
        id => $request->{id},
        charttype => $request->{charttype},
    }});

    $account = $account->get;
    return _display_account_screen($request, $account);
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

    if ( defined $request->{parent} and $request->{parent} == -1 ) {
        $request->{parent} = undef;
    }
    die $request->{_locale}->text('Please select a valid heading')
       if (defined $request->{heading}
           and $request->{heading} =~ /\D/);
    my $account = LedgerSMB::DBObject::Account->new({base => $request});
    $account->{$account->{summary}}=$account->{summary};
    $account->save;
    return edit($account);
}

=item update_translations

Saves selected translations

=cut

sub update_translations {
    my ($request) = @_;
    my $account = LedgerSMB::DBObject::Account->new({base => $request});
    if ($request->{languagecount} > 0) {
        $account->{translations} = {};
        for my $index (1..$request->{languagecount}) {
            $account->{translations}->{$request->{"languagecode_$index"}}
            = $request->{"languagetranslation_$index"};
        }
    }

    $account->save_translations;
    return edit($account);
}

=item save_as_new

Saves as a new account.  Deletes the id field and then calls save()

=cut

sub save_as_new {
    my ($request) = @_;
    $request->{id} = undef;
    return save($request);
}


sub _display_account_screen {
    my ($form, $account) = @_;

    @{$account->{all_headings}} = $account->list_headings();
    $account->is_recon;
    $account->gifi_list;

    foreach my $item ( split( /:/, $account->{link} ) ) {
        $account->{$item} = 1;
    }

    my @languages = $form->call_procedure(
        funcname => 'person__list_languages'
    );

    my $template = LedgerSMB::Template::UI->new_UI;
    return $template->render($form, 'accounts/edit', {
        form => $account,
        languages => \@languages,
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
    my $template = LedgerSMB::Template::UI->new_UI;
    return $template->render($request, 'accounts/yearend',
                             { request => $request,
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
    my $template = LedgerSMB::Template::UI->new_UI;
    return $template->render($request, 'accounts/yearend_complete', $eoy);
}

=item close_period

Closes the books without posting a year-end.

Request variables expected:
period_close_date: Date up to (inclusive) which to close the books

=cut

sub close_period {
    my ($request) = @_;
    $request->{end_date} = $request->{period_close_date};
    my $eoy = LedgerSMB::DBObject::EOY->new({base => $request});
    $eoy->checkpoint_only;
    delete $request->{period_close_date};
    return yearend_info($request);
}


=item reopen_books

This reopens books as of $request->{reopen_date}

=cut

sub reopen_books {
    my ($request) = @_;
    my $eoy =  LedgerSMB::DBObject::EOY->new({base => $request});
    $eoy->reopen_books;
    delete $request->{reopen_date};
    return yearend_info($request);
}

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2009 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
