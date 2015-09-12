=head1 NAME

LedgerSMB::Report::Listings::Business_Unit - List Business Reporting Units

=head1 SYNOPSIS

 LedgerSMB::Report::Listings::Business_Unit->new(%$request)->render;

=cut

package LedgerSMB::Report::Listings::Business_Unit;
use Moose;
extends 'LedgerSMB::Report';

=head1 DESCRIPTION

Reporting Units provide the general categories by which transaction lines can
be assigned.  These include departments, funds, projects, and the like.  This
flexible system allows for complex reporting of costs associated with business
activities.

=head1 REPORT CRITERIA

=head2 id

Business unit class id

=cut

has id => (is => 'ro', isa => 'Int');

=head1 CONSTANTS

=head2 columns

=over

=item control_coe

=item description

=item start_date

=item end_date

=back

=cut

sub columns {
    return [
      { col_id => 'control_code',
          type => 'href',
     href_base => 'business_unit.pl?action=edit&id=',
          name => LedgerSMB::Report::text('Control Code') },

      { col_id => 'description',
          type => 'text',
          name => LedgerSMB::Report::text('Description') },

      { col_id => 'start_date',
          type => 'text',
          name => LedgerSMB::Report::text('Start Date') },

      { col_id => 'description',
          type => 'text',
          name => LedgerSMB::Report::text('End Date') },
    ];
}

=head2 header_lines

None.

=cut

sub header_lines { [] };

=head2 name

Business Units List

=cut

sub name { LedgerSMB::Report::text('Business Unit List'); }

=head1 METHODS

=head2 run_report

=cut

sub run_report {
    my $self = shift;
    $self->rows([
      map { { %$_, row_id => $_->{id}, } }
       $self->call_dbmethod(funcname => 'business_unit__list_by_class',
                              args => { class_id => $self->id } )
    ]);
}

=head1 COPYRIGHT

Copyright (C) 2014 The LedgerSMB Core Team.  This file may be re-used under the
terms of the GNU General Public License version 2 or at your option any later
version.  Please see the included LICENSE.TXT for more information.

=cut

__PACKAGE__->meta->make_immutable;

1;
