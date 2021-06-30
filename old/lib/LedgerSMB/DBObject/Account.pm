=head1 NAME

LedgerSMB::DBObject::Account - Base class for chart of accounts entries

=head1 SYNOPSIS

This class contains methods for managing chart of accounts entries (headings
and accounts).

=head1 INHERITS

=over

=item LedgerSMB::PGOld

=back

=head1 METHODS

=cut

package LedgerSMB::DBObject::Account;
use strict;
use warnings;
use base qw(LedgerSMB::PGOld);

use Feature::Compat::Try;

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
    return;
}


# _get_custom_account_links()
#
# Extracts all account_link_description records marked as 'custom' and
# not marked as 'summary' from the database.
#
# Sets the `custom_link_descriptions` object property to be an arrayref
# containing a hash for each resulting row.

sub _get_custom_account_links {
    my $self = shift;
    my @descriptions = $self->call_dbmethod(
        funcname => 'get_link_descriptions',
        args => {
            custom => 1,
            summary => 0,
        },
    );
    $self->{custom_link_descriptions} = \@descriptions;
    return;
}


# _get_summary_account_links()
#
# Extracts all account_link_description records marked as 'summary',
# including those marked as 'custom' from the database.
#
# Sets the `summary_link_descriptions` object property to be an arrayref
# containing a hash for each resulting row.

sub _get_summary_account_links {
    my $self = shift;
    my @descriptions = $self->call_dbmethod(
        funcname => 'get_link_descriptions',
        args => {
            custom => undef,
            summary => 1,
        },
    );
    $self->{summary_link_descriptions} = \@descriptions;
    return;
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
    if ($self->{charttype} and $self->{charttype} eq 'H') {
        $func = 'account_heading_save';
    }

    my $id_ref;
    try {
        ($id_ref) = $self->call_dbmethod(funcname => $func);
    }
    catch ($var) {
        if ($var =~ m/Invalid link settings:\s*Summary/) {
            die $self->{_locale}->text(
                'Error: Cannot include summary account in other dropdown menus'
            );
        }
        else {
            die $var;
        }
    }

    $self->{id} = $id_ref->{$func};

    if (defined $self->{recon}){
        $self->call_procedure(funcname => 'cr_coa_to_account_save', args =>[ $self->{accno}, $self->{description}]);
    }

    return $self->_get_translations;
}

=item save_translations

=cut

sub save_translations {
    my $self = shift @_;
    my $trans_save_func = 'account__save_translation';
    my $trans_del_func = 'account__delete_translation';
    if ($self->{charttype} and $self->{charttype} eq 'H') {
        $trans_save_func = 'account_heading__save_translation';
        $trans_del_func = 'account_heading__delete_translation';
    }
    for my $lang_code (keys %{$self->{translations}}) {
        if (($self->{translations}->{$lang_code} // '') eq '') {
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
    return;
}

=item get()

This method gets a chart of accounts entry corresponding with the object's
C<id> property.

The following object properties are set:

  * id
  * accno
  * gifi_accno
  * description
  * heading
  * category
  * obsolete
  * contra
  * is_temp
  * tax
  * link
  * translations
  * custom_link_descriptions
  * summary_link_descriptions

=cut

sub get {
    my $self = shift @_;
    my $func = 'account_get';

    if ($self->{charttype} and $self->{charttype} eq 'H'){
      $func = 'account_heading_get';
    }

    my $account = $self->call_procedure(
        funcname => $func,
        args => [$self->{id}],
    );

    if ($account->{is_temp} && $account->{category} eq 'Q') {
        $account->{category} = 'Qt';
    }

    @{$self}{keys %$account} = values %$account if $account;
    $self->_get_translations;
    $self->_get_custom_account_links;
    $self->_get_summary_account_links;

    return $self;
}

=item check_transactions()

Returns true if the account has transactions, false if not.  Also sets the
$account->{has_transactions} value to the return value.

$account->{id} must be set.

=cut

sub check_transactions {
    my $self = shift @_;
    my ($ref) = $self->call_dbmethod(funcname => 'account_has_transactions');
    return $self->{has_transactions} = $ref->{'account_has_transactions'};
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
    return;
}

=item list()

Returns a list of all accounts.

=cut

sub list {
    my $self = shift @_;
    @{$self->{account_list}} =  $self->call_dbmethod(funcname => 'chart_list_all');
    return @{$self->{account_list}};
}

=item gifi_list()

Returns a list of all gifi codes and descriptions. Populates the object
C<gifi_list> property.

=cut

sub gifi_list {
    my $self = shift @_;
    @{$self->{gifi_list}} = $self->call_dbmethod(funcname => 'gifi__list');
    return @{$self->{gifi_list}};
}

=item generate_links()

Returns an arrayref containing account_link descriptions corresponding with
those present and true in the request parameters.

The LedgerSMB UI does not allow an account to be a 'summary' for more than one
descriptor. This is implied by the user interface and enforced at the database
level.

=cut

sub generate_links {
    my $self = shift;
    my @links;
    my @descriptions = $self->call_dbmethod(
        funcname => 'get_link_descriptions',
        args => {
            summary => undef,
            custom => undef,
        },
    );

    foreach my $d (@descriptions) {
       my $l = $d->{description};
       if ($self->{$l}) {
           push (@links, $l);
        }
     }

     return $self->{link} = \@links;
}

=item list_headings

Returns a list of account_headings.  No inputs required.

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
