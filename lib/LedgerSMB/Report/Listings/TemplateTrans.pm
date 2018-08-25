
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

=head2 can_delete

Boolean option which determines if option to delete is displayed.
Initialised according to whether the current user has the role
C<transaction_template_delete>.

=cut

has can_delete => (
    is => 'ro',
    isa => 'Bool',
    lazy => 1,
    builder => '_has_delete_permission'
);


=head1 METHODS

=head2 columns

=cut

sub columns {
    my ($self) = @_;
    my $href_base='transtemplate.pl?action=view&id=';
    my @columns;

    # Checkbox is only needed for delete option
    if ($self->can_delete) {
        push @columns, {
            col_id => 'row_select',
            type => 'checkbox',
            name => '',
        };
    }

    # Other fields are always displayed
    push @columns, {
      col_id => 'id',
        type => 'href',
        name => $self->Text('ID'),
   href_base => $href_base,
    }, {
      col_id => 'journal_type',
        type => 'text',
        name => 'Type'
    }, {
      col_id => 'description',
        type => 'href',
        name => $self->Text('Description'),
   href_base => $href_base,
    }, {
      col_id => 'entity_name',
        type => 'text',
        name => $self->Text('Counterparty'),
    };

    return \@columns;
}

=head2 header_lines

none

=cut

sub header_lines { return [] }

=head2 set_buttons

none

=cut

sub set_buttons {
    my ($self) = @_;
    my @buttons;

    if ($self->can_delete) {
        push @buttons, {
            name => 'action',
            text => $self->Text('Delete'),
           value => 'delete',
            type => 'submit',
           class => 'submit'
        };
    }

    return \@buttons;
}

=head2 name

Template Transactions

=cut

sub name {
    my $self = shift;
    return $self->Text('Template Transactions');
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


# PRIVATE METHODS

# has_delete_permission()
#
# returns true if current user has transaction_template_delete role,
# false otherwise.

sub _has_delete_permission {
    my ($self) = @_;
    my $r = $self->call_dbmethod(
        funcname => 'lsmb__is_allowed_role',
        args => {rolelist => ['transaction_template_delete']}
    );

    return $r->{lsmb__is_allowed_role};
}


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2016-2018 The LedgerSMB Core Team

This module may be used under the terms of the GNU General Public License
version 2 or at your option any later version.  Please see the enclosed
LICENSE.txt for details

=cut

__PACKAGE__->meta->make_immutable;
1;
