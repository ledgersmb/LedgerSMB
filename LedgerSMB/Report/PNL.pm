=head1 NAME

LedgerSMB::Report::PNL - Profit and Loss Reporting Base Class for LedgerSMB

=head1 SYNPOSIS

 use Moose;
 extends LedgerSMB::Report::PNL;

=head1 DESCRIPTION

This provides the common profit and loss reporting functions for LedgerSMB 1.4
and later.

=cut

package LedgerSMB::Report::PNL;
use Moose;
extends 'LedgerSMB::Report::Hierarchical';
with 'LedgerSMB::Report::Dates';

=head1 CRITERIA PROPERTIES

Standard dates.  Additional fields can be added by child reports.

=cut

=head1 Datastore Properties

=over


=item gifi

Boolean, true if it is a gifi report.

=cut

has gifi => (is => 'rw', isa => 'Bool');

=item legacy_hierarchy

Boolean, true if the regular hierarchies need to be ignored,
  using account category as the "hierarchy".

=cut

has legacy_hierarchy => (is => 'rw', isa => 'Bool');

=item column_path_prefix



=cut

has column_path_prefix => (is => 'ro', isa => 'ArrayRef',
                           default => sub { [ 1 ] });

=back

=head1 CONSTANT REPORT-RELATED FUNCTIONS

=over

=item template

This may be overridden by child reports.

=cut

sub template { return 'Reports/PNL' }

=item columns

=cut

sub columns {
    return [];
}


=back

=head1 METHODS

=over

=item run_report

=cut

sub run_report {
    my ($self) = @_;

    my @lines = $self->report_base();
    my $row_map = ($self->gifi) ?
        sub { my ($line) = @_;
              return $self->rheads->map_path([ $line->{account_category},
                                               $line->{gifi} ]);
        } : ($self->legacy_hierarchy) ?
        sub { my ($line) = @_;
              return $self->rheads->map_path([ $line->{account_category},
                                               $line->{account_number} ]);
        } :
        sub { my ($line) = @_;
              return $self->rheads->map_path(
                  ($line->{account_type} eq 'H')
                  ? $line->{heading_path}
                  : [ ( @{$line->{heading_path}},
                        $line->{account_number})
                  ]);
        };
    my $row_props = ($self->gifi) ?
        sub { my ($line) = @_;
              return { account_number => $line->{gifi},
                       account_desc => $line->{gifi_description},
              };
        } :
        sub { my ($line) = @_; return $line; };


    for my $line (@lines) {
        my $row_id = &$row_map($line);
        my $col_id = $self->cheads->map_path($self->column_path_prefix);
        # signs have already been converted in the query
        $self->accum_cell_value($row_id, $col_id, $line->{amount});
        $self->rheads->id_props($row_id, &$row_props($line));
        $self->cheads->id_props($col_id, { description =>
                                               $self->to_date });
    }

    # Header rows don't have descriptions
    my %header_desc;
    if ($self->gifi || $self->legacy_hierarchy) {
        %header_desc = ( 'E' => { 'account_number' => 'E',
                                  'account_desc' => 
                                      $self->_locale->text('Expenses'),
                                  'account_description' =>
                                      $self->_locale->text('Expenses') },
                         'I' => { 'account_number' => 'I',
                                  'account_desc' =>
                                      $self->_locale->text('Income'),
                                  'account_description' =>
                                      $self->_locale->text('Income') },
                         'A' => { 'account_number' => 'A',
                                  'account_desc' =>
                                      $self->_locale->text('Assets'),
                                  'account_description' =>
                                      $self->_locale->text('Assets') },
                         'L' => { 'account_number' => 'L',
                                  'account_desc' =>
                                      $self->_locale->text('Liabilities'),
                                  'account_description' =>
                                      $self->_locale->text('Liabilities') },
                         'Q' => { 'account_number' => 'Q',
                                  'account_desc' =>
                                      $self->_locale->text('Equity'),
                                  'account_description' =>
                                      $self->_locale->text('Equity') },
            );
    }
    else {
        %header_desc =
            map { $_->{accno} => { 'account_number' => $_->{accno},
                                   'account_desc'   => $_->{description},
                                   'account_description' => $_->{description} }
            }
            $self->call_dbmethod(funcname => 'account__all_headings');
    };
    for my $id (grep { ! defined $_->{props} } values %{$self->rheads->ids}) {
        $self->rheads->id_props($id->{id}, $header_desc{$id->{accno}});
    }
    $self->rows([]);
}

=back

=head1 SEE ALSO

=over

=item LedgerSMB::DBObject

=item LedgerSMB::DBObject::Moose

=item LedgerSMB::MooseTypes

=item LedgerSMB::Report

=item LedgerSMB::Report::Dates

=back

=head1 COPYRIGHT

COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be re-used under the
terms of the LedgerSMB General Public License version 2 or at your option any
later version.  Please see enclosed LICENSE file for details.

=cut

1;
