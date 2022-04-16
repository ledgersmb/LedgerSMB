
package LedgerSMB::Report::Balance_Sheet;

=head1 NAME

LedgerSMB::Report::Balance_Sheet - The LedgerSMB Balance Sheet Report

=head1 SYNOPSIS

 my $report = LedgerSMB::Report::Balance_Sheet->new(%$request);
 $report->render($request);

=head1 DESCRIPTION

This report class defines the balance sheet functionality for LedgerSMB.   The
primary work is done in the database procedures, while this module largely
translates data structures for the report.

=cut

use Moose;
use namespace::autoclean;
extends 'LedgerSMB::Report::Hierarchical';
with 'LedgerSMB::Report::Dates';

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


=item timing

Can be one of C<ultimo> (the default) or C<primo> for ending or
starting balance respectively.

=cut

has timing => (is => 'ro', isa => 'Str', default => 'ultimo');

=item incl_accnos

=cut

has incl_accnos => (is => 'ro', isa => 'Bool');

=back

=head1 METHODS

=head2 run_report()

This sets rows to an empty arrayref, and sets balance_sheet to the structure of
the balance sheet.

=cut

sub run_report {
    my ($self) = @_;

    die $self->Text('Required period type')
           if $self->comparison_periods and $self->interval eq 'none';
    my @lines = $self->call_dbmethod(funcname => 'report__balance_sheet');
    my ($row) = $self->call_procedure(funcname => 'setting_get',
                                      args => [ 'earn_id' ]);
    my $earn_id = ($row && $row->{value}) ? $row->{value} : -1;
    my $row_map = ($self->gifi) ?
        sub { my ($line) = @_;
              return ($line->{account_type} eq 'H')
                  ? []
                  : [ [ $line->{account_category},
                        $line->{gifi} ],
                      [ $line->{account_category} ],
                  ];
        } : ($self->legacy_hierarchy) ?
        sub { my ($line) = @_;
              if ($line->{account_type} eq 'A'
                  && ($line->{account_category} eq 'E'
                      || $line->{account_category} eq 'I')) {
                  # If the 'earn_id' configuration is missing,
                  #  this is the case we hit
                  # (the query doesn't know which node to aggregate into)
                  return [ [ 'QL', 'Q', 'q' ],
                           [ 'QL', 'Q' ],
                           [ 'QL' ],
                      ];
              }
              elsif ($line->{account_type} eq 'A') {
                  if ($line->{account_category} eq 'A') {
                      return [ [ $line->{account_category},
                                 $line->{account_number} ],
                               [ $line->{account_category} ],
                          ];
                  }
                  else {
                      return [ [ 'QL',
                                 $line->{account_category},
                                 $line->{account_number} ],
                               [ 'QL',
                                 $line->{account_category} ],
                               [ 'QL' ],
                          ];
                  }
              }
              elsif ($line->{account_type} eq 'H'
                     && $line->{account_id} == $earn_id) {
                  # If the 'earn_id' is configured, we hit this case
                  # be sure to map the heading
                  return [ [ 'QL', 'Q', 'q' ],
                           [ 'QL', 'Q' ],
                           [ 'QL' ],
                      ];
              }
              return [];
        } :
        sub { my ($line) = @_;
              return [ ($line->{account_type} eq 'H')
                       ? $line->{heading_path}
                       : [ ( @{$line->{heading_path}},
                             $line->{account_number})
                       ],
                  ];
        };
    my $row_props = ($self->gifi) ?
        sub { my ($line) = @_;
              $line->{account_number} = $line->{gifi};
              $line->{account_description} = $line->{gifi_description};
              $line->{order} = $line->{account_number};
              return $line;
        } : ($self->legacy_hierarchy) ?
        sub { my ($line) = @_;
              if ($line->{account_type} eq 'A'
                  && ($line->{account_category} eq 'E'
                      || $line->{account_category} eq 'I')) {
                  return undef;
              }
              return $line;
         } :
         sub { my ($line) = @_;
               $line->{order} = $line->{account_number};
               return $line; };

    my $col_id = $self->cheads->map_path($self->column_path_prefix);
    $self->cheads->id_props($col_id,
                            { description => $self->date_to->to_output,
                              to_date     => $self->date_to->to_output,
                            });

    for my $line (@lines) {
        my $props = &$row_props($line);
        my $paths = &$row_map($line);

        for my $path (@$paths) {
            my $row_id = $self->rheads->map_path($path);
            $self->accum_cell_value($row_id, $col_id, $line->{amount});
            $self->rheads->id_props($row_id, $props)
                if defined $props;

            $props = undef;
        }
    }

    # Header rows don't have descriptions
    my %header_desc;
    if ($self->gifi || $self->legacy_hierarchy) {
        %header_desc = ( 'E' => { 'account_number' => 'E',
                                  'account_category' => 'E',
                                  'account_type' => 'H',
                                  'account_description' =>
                                      $self->Text('Expenses') },
                         'I' => { 'account_number' => 'I',
                                  'account_category' => 'I',
                                  'account_type' => 'H',
                                  'account_description' =>
                                      $self->Text('Income') },
                         'A' => { 'order' => '1',
                                  'account_number' => '',
                                  'account_category' => 'A',
                                  'account_type' => 'H',
                                  'account_description' =>
                                      $self->Text('Assets') },
                         'QL' => { 'order' => '2',
                                  'account_number' => '',
                                  'account_category' => 'QL',
                                  'account_type' => 'H',
                                  'account_description' =>
                                      $self->Text('Equity & Liabilities') },
                         'L' => { 'order' => '2',
                                  'account_number' => '',
                                  'account_category' => 'L',
                                  'account_type' => 'H',
                                  'heading_path' => [ 'QL' ],
                                  'account_description' =>
                                      $self->Text('Liabilities') },
                         'Q' => { 'order' => '3',
                                  'account_number' => '',
                                  'account_category' => 'Q',
                                  'account_type' => 'H',
                                  'heading_path' => [ 'QL' ],
                                  'account_description' =>
                                      $self->Text('Equity') },
                         'q' => { 'order' => '1',
                                  'account_number' => '',
                                  'account_category' => '',
                                  'account_type' => 'A',
                                  'heading_path' => [ 'QL', 'Q' ],
                                  'account_description' =>
                                      $self->Text('Current earnings') },
            );
    }
    else {
        %header_desc =
            map { $_->{accno} => { 'account_number' => $_->{accno},
                                   'account_description' => $_->{description} }
            }
            $self->call_dbmethod(funcname => 'account__all_headings');
    };
    for my $id (grep { ! defined $_->{props} } values %{$self->rheads->ids}) {
        $self->rheads->id_props($id->{id}, $header_desc{$id->{accno}});
    }
    for my $col_id (keys %{$self->cheads->ids}) {
        for my $row_id (keys %{$self->rheads->ids}) {
            my $value = $self->cells->{$row_id}->{$col_id};

            next unless $value;

            my $props = $self->rheads->id_props($row_id);
            my $cat = $props->{account_category};
            my $contra = $props->{contra};
            my $sign = (($contra) ? -1 : 1)
                * ((($cat eq 'A') || ($cat eq 'E')) ? -1 : 1);

            $self->cell_value($row_id, $col_id, $sign * $value)
                if $sign < 0;
        }
    }

    return $self->rows([]);
}

=head2 header_lines

=cut

sub header_lines {
    my $self = shift;

    return [
        $self->timing eq 'ultimo'
        ? $self->Text('Closing Balance')
        : $self->Text('Opening Balance')
        ];
}

=head2 template

Implements LedgerSMB::Report's abstract template method.

=cut

sub template {
    return 'balance_sheet';
}

=head2 name

Implements LedgerSMB::Report's abstract 'name' method.

=cut

sub name {
    my ($self) = @_;
    return $self->Text('Balance sheet');
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2013 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

__PACKAGE__->meta->make_immutable;

1;
