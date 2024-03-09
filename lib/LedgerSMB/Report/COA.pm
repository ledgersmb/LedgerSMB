
package LedgerSMB::Report::COA;

=head1 NAME

LedgerSMB::Report::COA - Chart of Accounts List for LedgerSMB

=head1 SYNPOSIS

  my $report = LedgerSMB::Report::COA->new(%$request);
  $report->render();

=head1 DESCRIPTION

This module provides a Chart of Account report for LedgerSMB.  This account is
useful regarding checking on current balances and managing the accounts.
Typically columns are displayed based on the permissions of the user.

=head1 INHERITS

=over

=item LedgerSMB::Report;

=back

=cut

use Moose;
use namespace::autoclean;
extends 'LedgerSMB::Report';


=head1 PROPERTIES

=over

=item columns

Read-only accessor, returns a list of columns.  Unless otherwise noted, each
column is intended to be visible to all who have permissions to run the report.

=over

=item accno

Displays the account number.

=item description

Account description.

=item gifi_accno

This is the GIFI account number.

=item debit_balance

This is the debit balance (or blank if none or balance is credit).

=item credit_balance

This is the credit balance (or blank if none or balance is debit)

=item link

This lists the link descriptions.  Each represents a group of drop-downs the
user has access to.  This should be visible only to admin users.

=item edit

Link to edit the account.  Should be visible only to admin users.

=item delete

Link to delete the account if it has no transactions.  Should be visible only to
admin users.

=back

=cut

sub columns {
    my ($self) = @_;
    return [
    {col_id => 'accno',
       name => $self->Text('Account Number'),
       type => 'href',
   href_base => '',
     pwidth => '2', },

    {col_id => 'description',
       name => $self->Text('Description'),
       type => 'href',
  href_base => '',
     pwidth => '6', },

    {col_id => 'category',
       name => $self->Text('Category'),
       type => 'text',
     pwidth => '1', },

    {col_id => 'contra',
       name => $self->Text('Contra'),
       type => 'boolean_checkmark',
     pwidth => '1', },

    {col_id => 'recon',
       name => $self->Text('Recon'),
       type => 'boolean_checkmark',
     pwidth => '1', },

    {col_id => 'tax',
       name => $self->Text('Tax'),
       type => 'boolean_checkmark',
     pwidth => '1', },

    {col_id => 'obsolete',
       name => $self->Text('Obsolete'),
       type => 'boolean_checkmark',
     pwidth => '1', },

    {col_id => 'gifi',
       name => $self->Text('GIFI'),
       type => 'text',
     pwidth => '1', },

    {col_id => 'link',
       name => $self->Text('Dropdowns'),
       type => 'text',
     pwidth => '3', },

    {col_id => 'delete',
       name => $self->Text('Delete'),
       type => 'href',
  href_base => '',
  html_only => '1', },
  ];
}

=item name

Returns the localized template name

=cut

sub name {
    my ($self) = @_;
    return $self->Text('Chart of Accounts');
}

=back


=head1 METHODS

=head2 run_report()

Runs the report, and assigns rows to $self->rows.

=cut

sub run_report{
    my ($self) = @_;
    my @rows = $self->call_dbmethod(funcname => 'report__coa');
    my %category = (
        'A' => $self->Text('Asset'),
        'L' => $self->Text('Liability'),
        'Q' => $self->Text('Equity'),
        'I' => $self->Text('Income'),
        'E' => $self->Text('Expense')
        );
    for my $r(@rows){
        my $ct;
        if ($r->{is_heading}){
           $ct = 'H';
        } else {
           $ct = 'A';
        }
        $r->{delete} = '['.$self->Text('Delete').']'
                  if !$r->{has_rows};
        $r->{accno_href_suffix} = 'account.pl?__action=edit&id='.$r->{id} .
           "&charttype=$ct";
        $r->{description_href_suffix} = $r->{accno_href_suffix};
        $r->{delete_href_suffix} = 'journal.pl?__action=delete_account&id='
        . $r->{id} . "&charttype=$ct";
        $r->{html_class} = 'listheading' if $r->{is_heading};

        next if $r->{is_heading};
        $r->{category} = $category{$r->{category}};
        $r->{link} =~ s/:/\n/g if $r->{link};
    }
    return $self->rows(\@rows);
}

=head2 set_buttons()

Returns a set of buttons to be displayed at the bottom of the report.

=cut

sub set_buttons {
    my ($self) = @_;
    my @buttons = ();

    if($self->_can_create_account) {
        push @buttons, (
            {
                name  => '__action',
                type  => 'submit',
                text  => $self->_locale->text('Create Account'),
                value => 'new_account',
                class => 'submit',
            },
            {
                name  => '__action',
                type  => 'submit',
                text  => $self->_locale->text('Create Heading'),
                value => 'new_heading',
                class => 'submit',
            },
        );
    }

    return \@buttons;
}

# PRIVATE METHODS

# _can_create_account()
#
# Returns true if current user has create_account permissions

sub _can_create_account {
    my ($self) = @_;
    my $r = $self->call_dbmethod(
        funcname => 'lsmb__is_allowed_role',
        args => {rolelist => ['account_create']}
    );

    return $r->{lsmb__is_allowed_role};
}



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012-2018 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

__PACKAGE__->meta->make_immutable;

1;
