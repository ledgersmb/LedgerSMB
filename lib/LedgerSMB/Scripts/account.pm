
use v5.36;
use warnings;
use experimental 'try';

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

use Log::Any;

use LedgerSMB;


=item new_account

Displays a screen to create a new account.

=cut

sub new_account {
    my ($request) = @_;
    return _display_account_screen($request, { charttype => 'A' });
}

=item new_heading

Displays a screen to create a new Chart of Accounts heading.

=cut

sub new_heading {
    my ($request) = @_;
    return _display_account_screen($request, { charttype => 'H' });
}

=item edit

Retrieves account information and then displays the screen.

Requires the id and charttype variables in the request to be set.

=cut

sub edit {
    my ($request) = @_;
    my $func = 'account_get';
    my $trans_func = 'account__list_translations';

    if ($request->{charttype} and $request->{charttype} eq 'H'){
      $func = 'account_heading_get';
      $trans_func = 'account_heading__list_translations';
    }

    my ($account) = $request->call_procedure(
        funcname => $func,
        args => [$request->{id}],
    );
    if ($account->{is_temp} && $account->{category} eq 'Q') {
        $account->{category} = 'Qt';
    }
    $account->{translations} = {
        map { $_->{language_code} => $_ }
        $request->call_procedure(
            funcname => $trans_func,
            args => [ $request->{id} ])
    };
    $account->{charttype} = $request->{charttype};
    my ($ref) = $request->call_procedure(
        funcname => 'account__is_recon',
        args     => [ $account->{accno} ]);
    $account->{account__is_recon} = $ref->{'account__is_recon'};

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

sub _generate_links {
    my $request = shift;
    my @links;
    my @descriptions = $request->call_procedure(
        funcname => 'get_link_descriptions',
        args => [
            undef, #summary
            undef, #custom
        ],
    );

    foreach my $d (@descriptions) {
       my $l = $d->{description};
       if ($request->{$l}) {
           push (@links, $l);
        }
     }

     return \@links;
}

sub save {
    my ($request) = @_;

    if ( defined $request->{parent} and $request->{parent} == -1 ) {
        $request->{parent} = undef;
    }
    die $request->{_locale}->text('Please select a valid heading')
       if (defined $request->{heading}
           and $request->{heading} =~ /\D/);

    if ($request->{charttype} and $request->{charttype} eq 'A') {
        if ($request->{category} eq 'Qt') {
            $request->@{'is_temp', 'category'} = ('1', 'Q');
        }
        try {
            $request->{$request->{summary}} = $request->{summary};
            my ($ref) = $request->call_procedure(
                funcname => 'account__save',
                args     => [
                    $request->@{qw(id accno description category
                                   gifi_accno heading heading_negative_balance)},
                    $request->{contra} // '0',
                    $request->{tax} // '0',
                    _generate_links($request),
                    $request->@{qw(obsolete is_temp)}
                ]);
            $request->{id} = $ref->{account__save};
        }
        catch ($var) {
            if ($var =~ m/Invalid link settings:\s*Summary/) {
                die $request->{_locale}->text(
                    'Error: Cannot include summary account in other dropdown menus'
                    );
            }
            else {
                die $var;
            }
        }

        if (defined $request->{recon}){
            $request->call_procedure(
                funcname => 'cr_coa_to_account_save',
                args     =>[
                    $request->{accno},
                    $request->{description}
                ]);
        }
    }
    else {
        my ($ref) = $request->call_procedure(
            funcname => 'account_heading_save',
            args     => [
                $request->@{qw(id accno description parent)}
            ]);
        $request->{id} = $ref->{account_heading_save};
    }
    return edit($request);
}

=item update_translations

Saves selected translations

=cut

sub update_translations {
    my ($request) = @_;
    my $trans_save_func = 'account__save_translation';
    my $trans_del_func = 'account__delete_translation';
    if ($request->{charttype} and $request->{charttype} eq 'H') {
        $trans_save_func = 'account_heading__save_translation';
        $trans_del_func = 'account_heading__delete_translation';
    }

    if ($request->{languagecount} > 0) {
        for my $index (1..$request->{languagecount}) {
            if (($request->{"languagecode_$index"} // '') eq '') {
                $request->call_procedure(
                    funcname => $trans_del_func,
                    args     => [
                        $request->{id},
                        $request->{"languagecode_$index"}
                    ]);
            }
            else {
                $request->call_procedure(
                    funcname => $trans_save_func,
                    args     => [
                        $request->{id},
                        $request->{"languagecode_$index"},
                        $request->{"languagetranslation_$index"}
                    ]);
            }
        }
    }

    return edit($request);
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
    my ($request, $account) = @_;
    @{$account->{all_headings}} =
        $request->call_procedure(funcname => 'account_heading__list');
    $account->{custom_link_descriptions} = [
        $request->call_procedure(
            funcname => 'get_link_descriptions',
            args => [ 0, 1 ] # summary = 0, custom = 1
        )];
    $account->{summary_link_descriptions} = [
        $request->call_procedure(
            funcname => 'get_link_descriptions',
            args => [ 1, undef ] # summary = 1, custom = 0
        )];
    foreach my $item ( split( /:/, $account->{link} ) ) {
        $account->{$item} = 1;
    }

    my @languages = $request->call_procedure(
        funcname => 'person__list_languages'
    );

    my $template = $request->{_wire}->get('ui');
    return $template->render($request, 'accounts/edit', {
        form => $account,
        gifis => [ $request->call_procedure(funcname => 'gifi__list') ],
        languages => \@languages,
    });
}


=item yearend_info

Shows the yearend screen.  No expected inputs.

=cut

sub yearend_info {
    my ($request) = @_;
    my $template = $request->{_wire}->get('ui');
    my $dbh = $request->{dbh};
    my @closing_dates = $dbh->selectall_array(
        q|select end_date,
                 exists (select *
                           from yearend y
                          where y.transdate = x.end_date
                            and not y.reversed) as is_yearend
            from (
              select distinct end_date
                from account_checkpoint) x
           order by end_date desc
           limit 10|,
        { Slice => {} }
        );
    die $dbh->errstr if $dbh->err;

    return $template->render(
        $request, 'accounts/yearend',
        {
            request => $request,
            eoy => {
                closing_dates       => \@closing_dates,
                earnings_accounts => [
                    $request->call_procedure(
                        funcname => 'eoy_earnings_accounts')
                    ],
                user              => $request->{_user},
            }
        });
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
    $request->call_procedure(
        funcname => 'eoy_close_books',
        args     => [
            $request->{end_date},
            $request->{reference},
            $request->{description},
            $request->{retention_acc_id}
        ]);
    my $template = $request->{_wire}->get('ui');
    return $template->render($request, 'accounts/yearend_complete', {});
}

=item close_period

Closes the books without posting a year-end.

Request variables expected:
period_close_date: Date up to (inclusive) which to close the books

=cut

sub close_period {
    my ($request) = @_;
    $request->call_procedure(
        funcname => 'eoy_create_checkpoint',
        args     => [ $request->{period_close_date} ]);
    delete $request->{period_close_date};
    return yearend_info($request);
}


=item reopen_books

This reopens books as of $request->{reopen_date}

=cut

sub reopen_books {
    my ($request) = @_;
    $request->call_procedure(
        funcname => 'eoy_reopen_books',
        args     => [ $request->{reopen_date} ]);
    delete $request->{reopen_date};
    return yearend_info($request);
}

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2022 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
