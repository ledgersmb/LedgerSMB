
package LedgerSMB::Report::Listings::TemplateTrans;

=head1 NAME

LedgerSMB::Report::Listings::TemplateTrans - Listing of Template Transactions

=head1 DESCRIPTION

Implements a listing of template transactions: transactions which have
been (mostly) pre-filled. These transactions have themselves not been
posted, however, copies of these transactions can be (quickly) posted
due to the fact that only minimal additional data needs te be specified
in order to complete the financial transaction.

=cut

use Moose;
use namespace::autoclean;
use LedgerSMB::Magic qw( JRNL_GJ JRNL_AR JRNL_AP );

extends 'LedgerSMB::Report';

=head1 SYNOPSIS

 LedgerSMB::Report::Listings::TemplateTrans->new(%$request)->render($request);

=head1 FILTER CRITERIA

None, though we provide is_template by default.

=head2 is_template

Always true

=cut

has is_template => (is => 'ro', isa => 'Bool', default => 1);

=head2 approved

Always false

=cut

has approved => (is => 'ro', isa => 'Bool', default => 0);



=head1 METHODS

=head2 columns

=cut

sub columns {
    my ($self) = @_;
    my $href_base='transtemplate.pl?action=view&id=';
    return [ {
        col_id => 'row_select',
        type => 'checkbox',
        name => '',

     }, {
      col_id => 'id',
        type => 'href',
        name => LedgerSMB::Report::text('ID'),
   href_base => $href_base,
    }, {
      col_id => 'journal_type',
        type => 'text',
        name => 'Type'
    }, {
      col_id => 'description',
        type => 'href',
        name => LedgerSMB::Report::text('Description'),
   href_base => $href_base,
    }, {
      col_id => 'entity_name',
        type => 'text',
        name => LedgerSMB::Report::text('Counterparty'),
    }];
}

=head2 header_lines

none

=cut

sub header_lines { return [] }

=head2 set_buttons

none

=cut

sub set_buttons {
    return [
        { name => 'action',
            text => LedgerSMB::Report::text('Delete'),
           value => 'delete',
            type => 'submit',
           class => 'submit'
        },
        ];
}

=head2 name

Template Transactions

=cut

sub name {
    my $self = shift;
    return LedgerSMB::Report::text('Template Transactions');
}

=head2 run_report

=cut

my %jtype = (
    JRNL_GJ() => 'gl',
    JRNL_AR() => 'ar',
    JRNL_AP() => 'ap'
    );

sub run_report {
    my ($self) = @_;
    $self->manual_totals(1); #don't display totals
    my @rows = $self->call_dbmethod(funcname => 'journal__search');
    for my $ref(@rows){
       $ref->{journal_type} = $jtype{$ref->{entry_type}};
       $ref->{row_id} = $ref->{id};
    }
    return $self->rows(\@rows);
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2016 The LedgerSMB Core Team

This module may be used under the terms of the GNU General Public License
version 2 or at your option any later version.  Please see the enclosed
LICENSE.txt for details

=cut

__PACKAGE__->meta->make_immutable;
1;
