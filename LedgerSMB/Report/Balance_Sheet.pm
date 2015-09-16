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

package LedgerSMB::Report::Balance_Sheet;
use Moose;
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


=item incl_accnos

=cut

has incl_accnos => (is => 'ro', isa => 'Bool');

=back

=head1 SEMI-PUBLIC METHODS

=head2 run_report()

This sets rows to an empty arrayref, and sets balance_sheet to the structure of
the balance sheet.

=cut

sub run_report {
    my ($self) = @_;

    my @lines = $self->call_dbmethod(funcname => 'report__balance_sheet');
    my ($row) = $self->call_procedure(funcname => 'setting_get',
                                      args => [ 'earn_id' ]);
    my $earn_id = ($row) ? $row->{value} : -1;
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
                  return [ [ 'Q', 'q' ],
                           [ 'Q' ],
                      ];
              }
              elsif ($line->{account_type} eq 'A') {
                  return [ [ $line->{account_category},
                             $line->{account_number} ],
                           [ $line->{account_category} ],
                      ];
              }
              elsif ($line->{account_type} eq 'H'
                     && $line->{account_id} == $earn_id) {
                  # If the 'earn_id' is configured, we hit this case
                  # be sure to map the heading
                  return [ [ 'Q', 'q' ],
                           [ 'Q' ],
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
              return { account_number => $line->{gifi},
                       account_desc => $line->{gifi_description},
              };
        } : ($self->legacy_hierarchy) ?
        sub { my ($line) = @_;
              if ($line->{account_type} eq 'A'
                  && ($line->{account_category} eq 'E'
                      || $line->{account_category} eq 'I')) {
                  return undef;
              }
              return $line;
         } :
         sub { my ($line) = @_; return $line; };

    my $col_id = $self->cheads->map_path($self->column_path_prefix);
    $self->cheads->id_props($col_id, { description =>
                                           $self->to_date->to_output });

    for my $line (@lines) {
        my $props = &$row_props($line);
        my $paths = &$row_map($line);

        for my $path (@$paths) {
            my $row_id = $self->rheads->map_path($path);
            $self->accum_cell_value($row_id, $col_id, $line->{balance});
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
                                  'account_desc' =>
                                      $self->_locale->text('Expenses'),
                                  'account_description' =>
                                      $self->_locale->text('Expenses') },
                         'I' => { 'account_number' => 'I',
                                  'account_category' => 'I',
                                  'account_type' => 'H',
                                  'account_desc' =>
                                      $self->_locale->text('Income'),
                                  'account_description' =>
                                      $self->_locale->text('Income') },
                         'A' => { 'account_number' => 'A',
                                  'account_category' => 'A',
                                  'account_type' => 'H',
                                  'account_desc' =>
                                      $self->_locale->text('Assets'),
                                  'account_description' =>
                                      $self->_locale->text('Assets') },
                         'L' => { 'account_number' => 'L',
                                  'account_category' => 'L',
                                  'account_type' => 'H',
                                  'account_desc' =>
                                      $self->_locale->text('Liabilities'),
                                  'account_description' =>
                                      $self->_locale->text('Liabilities') },
                         'Q' => { 'account_number' => 'Q',
                                  'account_category' => 'Q',
                                  'account_type' => 'H',
                                  'account_desc' =>
                                      $self->_locale->text('Equity'),
                                  'account_description' =>
                                      $self->_locale->text('Equity') },
                         'q' => { 'account_number' => '',
                                  'account_category' => 'Q',
                                  'account_type' => 'H',
                                  'heading_path' => [ 'Q' ],
                                  'account_desc' =>
                                      $self->_locale->text('Current earnings'),
                                  'account_description' =>
                                      $self->_locale->text('Current earnings') },
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
    for $col_id (keys %{$self->cheads->ids}) {
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

    $self->rows([]);
}

=head2 template

Implements LedgerSMB::Report's abstract template method.

=cut

sub template {
    return "Reports/balance_sheet";
}

=head2 name

Implements LedgerSMB::Report's abstract 'name' method.

=cut

sub name {
    return 'Balance sheet';
}

=head1 COPYRIGHT

COPYRIGHT (C) 2013 The LedgerSMB Core Team.  This file may be re-used under the
terms of the LedgerSMB General Public License version 2 or at your option any
later version.  Please see enclosed LICENSE file for details.

=cut

__PACKAGE__->meta->make_immutable;

1;
