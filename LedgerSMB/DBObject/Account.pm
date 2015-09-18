=head1 NAME

LedgerSMB::DBObject::Account - Base class for chart of accounts entries

=head1 SYNOPSYS

This class contains methods for managing chart of accounts entries (headings
and accounts).

=head1 INERITS

=over

=item LedgerSMB::PGOld

=back

=head1 METHODS

=cut

package LedgerSMB::DBObject::Account;
use strict;
use warnings;
use base qw(LedgerSMB::PGOld);

use Try::Tiny;

sub _get_translations {
    my ($self) = @_;
    my $trans_func = 'account__list_translations';
    if ($self->{charttype} and $self->{charttype} eq 'H'){
      $trans_func = 'account_heading__list_translations';
    }

    $self->{translations} = {};
    my @translations = $self->call_procedure(funcname => $trans_func,
                                             args => [ $self->{id} ]);
    for my $trans (@translations) {
        $self->{translations}->{$trans->{language_code}} = $trans;
    }
}


=over

=item save()

This method saves the chart of accounts entry.

The hash component of the object may contain an id attribute, used to overwrite
an account if that one exists.

Hash entries Used:

id: (optional):  If set, overwrite existing account.
accno: the text used to specify the account number
description:  Text to describe the account
category: A = asset, L = liability, Q = Equity, I = Income, E = expense
gifi_accno:  The GIFI account entry control code
heading: (Optional) The integer representing the heading.id desired
contra:  If true, the account balances on the opposite side.
tax:  If true, is a tax account
link:  a list of strings representing text box identifier.

=cut

sub save {
    my $self = shift @_;
    if (!defined $self->{contra}){
        $self->{contra} = '0';
    }
    if (!defined $self->{tax}) {
    $self->{tax} = '0';
    }
    if ($self->{category} eq 'Qt'){
       $self->{is_temp} = '1';
       $self->{category} = 'Q';
    }
    $self->generate_links;
    my $func = 'account__save';
    my $trans_save_func = 'account__save_translation';
    my $trans_del_func = 'account__delete_translation';
    if ($self->{charttype} and $self->{charttype} eq 'H') {
        $func = 'account_heading_save';
        $trans_save_func = 'account_heading__save_translation';
        $trans_del_func = 'account_heading__delete_translation';
    }
    my ($id_ref) = try { $self->call_dbmethod(funcname => $func) }
                   catch {
                        if ($_ =~ /Invalid link settings:\s*Summary/){
                            die LedgerSMB::App_State::Locale->text(
                 'Error: Cannot include summary account in other dropdown menus'
                            );
                        }
                        die LedgerSMB::App_State::Locale->text(
                            'Internal Database Error.'
                        ) . " $_";
                  };
    $self->{id} = $id_ref->{$func};
    if (defined $self->{recon}){
        $self->call_procedure(funcname => 'cr_coa_to_account_save', args =>[ $self->{accno}, $self->{description}]);
    }

    for my $lang_code (keys %{$self->{translations}}) {
        if ($self->{translations}->{$lang_code} eq '') {
            $self->call_procedure(funcname => $trans_del_func,
                                  args => [ $self->{id}, $lang_code ]);
        }
        else {
            $self->call_procedure(
                funcname => $trans_save_func,
                args => [ $self->{id}, $lang_code,
                          $self->{translations}->{$lang_code}]);
        }
    }
    $self->_get_translations;
}

=item get()

This method gets a chart of accounts entry.  It requires that the $account->{id}
value must be properly set.

=cut

sub get {
    my $self = shift @_;
    my $func = 'account_get';
    if ($self->{charttype} and $self->{charttype} eq 'H'){
      $func = 'account_heading_get';
    }
    my @accounts =  $self->call_dbmethod(funcname => $func);
    $self->{account_list} = [];
    for my $ref (@accounts){
        bless $ref, 'LedgerSMB::DBObject::Account';
        $ref->merge($self, keys => ['_user', '_locale', 'stylesheet', '_roles', '_request']);
        $ref->set_dbh;
        if ($ref->{is_temp} and ($ref->{category} eq 'Q')){
            $ref->{category} = 'Qt';
        }

        $ref->_get_translations;
        push (@{$self->{account_list}}, $ref);
    }
    return @{$self->{account_list}};
}

=item check_transactions()

Returns true if the account has transactions, false if not.  Also sets the
$account->{has_transactions} value to the return value.

$account->{id} must be set.

=cut

sub check_transactions {
    my $self = shift @_;
    my ($ref) = $self->call_dbmethod(funcname => 'account_has_transactions');
    $self->{has_transactions} = $ref->{'account_has_transactions'};
}

=item is_recon

Returns true if is set up for reconciliation.  False otherwise.

=cut

sub is_recon {
    my $self = shift @_;
    my ($ref) = $self->call_dbmethod(funcname => 'account__is_recon');
    $self->{account__is_recon} = $ref->{'account__is_recon'};
    return $self->{account__is_recon};
}

=item delete()

Attempts to delete the account or heading.  This will NOT succeed if the
account is referenced in any way by any transactions, credit accounts, etc.
or in case of a heading where the heading is referenced by accounts or
child-headings.

$account->{id} and $account->{charttype} must be set.

=cut

sub delete {
    my $self = shift @_;
    if ($self->{charttype} eq 'A') {
    $self->call_dbmethod(funcname => 'account__delete');
    } elsif ($self->{charttype} eq 'H') {
    $self->call_dbmethod(funcname => 'account_heading__delete');
    } else {
    die "Unknown charttype."
    }
}

=item list()

Returns a list of all accounts.

=cut

sub list {
    my $self = shift @_;
    @{$self->{account_list}} =  $self->call_dbmethod(funcname => 'chart__list_all');
    return @{$self->{account_list}};
}

=item gifi_list()

Returns a list of all gifi codes and descriptions.

=cut

sub gifi_list {
    my $self = shift @_;
    @{$self->{gifi_list}} = $self->call_dbmethod(funcname => 'gifi__list');
    return @{$self->{gifi_list}};
}

=item generate_links()

A mostly-private method for generating and checking whether link data is valid.

This is usually done (automatically) in preparation for saving the information
to the database.

=cut

sub generate_links {
    my $self= shift @_;
    my $is_summary = 0;
    my $is_custom = 0;
    my @links;
    my @descriptions = $self->call_dbmethod(funcname =>
                                          'get_link_descriptions');
    foreach my $d (@descriptions) {
       my $l = $d->{description};
       if ($self->{$l}) {
           $is_summary++ if ($d->{summary} == 1);
           $is_custom++ if ($d->{custom} == 1);
           if ($is_summary > 1 || ($is_summary == 1 && $is_custom >=1 )) {
                $self->error($self->{_locale}->text("Too many links on summary account!"));
           }
           push (@links, $l);
        }
     }

     $self->{link} = $self->_db_array_scalars(@links);
}

=item list_headings

Returns a list of account_heading's.  No inputs required.

=cut

sub list_headings {
   my ($self) = shift @_;
   return $self->call_dbmethod(funcname => 'account_heading__list');
}

=back

=head1 SEE ALSO

LedgerSMB::DBObject, LedgerSMB

=head1 COPYRIGHT

Copyright (c) 2009, the LedgerSMB Core Team.  This is licensed under the GNU
General Public License, version 2, or at your option any later version.  Please
see the accompanying License.txt for more information.

=cut

1;
