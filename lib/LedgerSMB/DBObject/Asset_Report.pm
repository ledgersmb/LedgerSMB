
package LedgerSMB::DBObject::Asset_Report;

=head1 NAME

LedgerSMB::DBObject::Asset_Report - LedgerSMB Base Class for Asset Reports

=head1 SYNOPSIS

This library contains the base utility functions for creating, saving, and
retrieving depreciation categories of asset depreciation and disposal reports.

=head1 STANDARD PROPERTIES

=over

=item id int

Integer id of asset report

=item report_date date

Effective date of report

=item gl_id bigint

ID of GL transaction if applicable and approved.

=item asset_class bigint

ID of asset class for the report the assets are

=item report_class int

Integer of the report class desired.

=item entered_by bigint

Integer id of the individual who entered the report

=item approved_by bigint

Integer id of the individual who approved the report

=item entered_at timestamp

Timestamp the report was created

=item approved_at timestamp

Timestamp the report was approved

=item depreciated_qty

Number of units (production or time) depreciated

=item dont_approve bool

If true, do not approve, ever.

=item submitted bool

If true, submitted for approval


=back

=head1 METHODS

=over

=cut

use base qw(LedgerSMB::PGOld);
use strict;
use warnings;

=item save

Uses standard properties

Saves report to the database.  Sets ID.

For each asset to be added to the report, we see:

for each row, id_$row contains the asset id for that row.  Let this be $id

if asset_$id, the asset is added.  Each asset also has:
amount_$id
dm_$id
percent_$id

=cut

sub save {
    my ($self) = @_;
    if ($self->{depreciation}){
        my ($ref) = $self->call_dbmethod(funcname => 'asset_report__save');
        $self->{report_id} = $ref->{id};
        $self->{asset_ids} = $self->_db_array_scalars(@{$self->{asset_ids}});
        my ($dep) = $self->call_dbmethod(funcname => 'asset_class__get_dep_method');
        $self->call_dbmethod(funcname => $dep->{sproc});
    } else {
       my ($ref) = $self->call_dbmethod(funcname => 'asset_report__begin_disposal');
       for my $i (0 .. $self->{rowcount}){
           if ($self->{"asset_$i"} == 1){
              my $id = $self->{"id_$i"};
              $self->call_procedure(funcname => 'asset_report__dispose',
                               args => [$ref->{id},
                                        $id,
                                        $self->{"amount_$id"},
                                        $self->{"dm_$id"},
                                        $self->{"percent_$id"}]);
          }
       }
    }
}

=item get

Gets report from the database.

=cut

sub get {
    my ($self) = @_;
    my ($ref) = $self->call_dbmethod(funcname => 'asset_report__get');
    $self->merge($ref);
    $self->{report_lines} = [];
    if ($self->{report_class} == 1){
        @{$self->{report_lines}} = $self->call_dbmethod(
                                  funcname => 'asset_report__get_lines'
        );
    } elsif ($self->{report_class} == 2) {
        @{$self->{report_lines}} = $self->call_dbmethod(
                                  funcname => 'asset_report__get_disposal'
        );
    } elsif ($self->{report_class} == 4) {
       @{$self->{report_lines}} = $self->call_dbmethod(
                                   funcname => 'asset_report_partial_disposal_details'
       );
    }
    return;
}

=item generate

Properties used:

* report_id int:  Report to enter the transactions into,
* accum_account_id int:  ID for accumulated depreciation.

=cut

sub generate {
    my ($self) = @_;
    @{$self->{assets}} = $self->call_dbmethod(
                   funcname => 'asset_report__generate'
    );
    for my $asset (@{$self->{assets}}){
        if ($self->{depreciation}){
           $asset->{checked} = "CHECKED";
        }
    }
}

=item approve

Properties used:

id

For depreciation accounts, expense_acct must be set.

For disposal accounts, gain_acct and loss_acct must be set.

Approves the referenced transaction and creates a GL draft (which must then be
approved.

=cut

sub approve {
    my ($self) = @_;
    $self->call_dbmethod(funcname => 'asset_report__approve');
}

=item search

Searches for matching asset reports for review and approval.

Search criteria in properties:

* start_date date
* end_date date
* asset_class int
* approved bool
* entered_by int

Start and end dates specify the date range (inclusive) and all other matches
are exact. Undefs match all records.

=cut

sub search {
    my ($self) = @_;
    return $self->call_dbmethod(funcname => 'asset_report__search');
}

=item get_metadata

Sets the following properties:

* asset_classes:  List of asset classes
* exp_accounts:  List of expense accounts
* gain_accounts:  List of gain accounts
* loss_accounts:  list of loss accounts
* disp_methods:  List of disposal methods

=cut

sub get_metadata {
    my ($self) = @_;
    @{$self->{asset_classes}} = $self->call_dbmethod(
                   funcname => 'asset_class__list'
    );
    @{$self->{exp_accounts}} = $self->call_dbmethod(
                   funcname => 'asset_report__get_expense_accts'
    );
    @{$self->{gain_accounts}} = $self->call_dbmethod(
                   funcname => 'asset_report__get_gain_accts'
    );
    @{$self->{disp_methods}} = $self->call_dbmethod(
                   funcname => 'asset_report__get_disposal_methods'
    );
    @{$self->{loss_accounts}} = $self->call_dbmethod(
                   funcname => 'asset_report__get_loss_accts'
    );
    for my $atype (qw(exp_accounts gain_accounts loss_accounts)){
        for my $acct (@{$self->{$atype}}){
            $acct->{text} = $acct->{accno}. '--'. $acct->{description};
        }
    }
}

=back

=head1 Copyright (C) 2010-2014, The LedgerSMB core team.

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
