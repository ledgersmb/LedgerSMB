
package LedgerSMB::Report::PNL;

=head1 NAME

LedgerSMB::Report::PNL - Profit and Loss Reporting Base Class for LedgerSMB

=head1 SYNPOSIS

 use Moose;
 extends LedgerSMB::Report::PNL;

=head1 DESCRIPTION

This provides the common profit and loss reporting functions for LedgerSMB 1.4
and later.

=cut

use Moose;
use namespace::autoclean;
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

=item from_date
=item to_date

Dates come from LedgerSMB::Report::Dates

=cut

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

=item business_units

Array of business unit id's

=cut

has 'business_units' => (is => 'rw', isa => 'Maybe[ArrayRef[Int]]');

=back

=head1 CONSTANT REPORT-RELATED FUNCTIONS

=over

=item template

This may be overridden by child reports.

=cut

sub template { return 'PNL' }

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

sub _row_handlers_gifi {
    return (
        sub {
            my ($line) = @_;
            return ($line->{account_type} eq 'H')
                ? []
                : [ [ $line->{account_category},
                      $line->{gifi} ],
                    [ $line->{account_category} ],
                ];
        },
        sub {
            my ($line) = @_;
            $line->{account_number} = $line->{gifi};
            $line->{account_description} = $line->{gifi_description};
            $line->{order} = $line->{account_number};
            return $line;
       });
}

sub _non_gifi_row_props {
    my ($line) = @_;
    $line->{order} = $line->{account_number};
    return $line;
}

sub _row_handlers_legacy {
    return (
        sub {
            my ($line) = @_;
            return ($line->{account_type} eq 'H')
                ? []
                : [ [ 'q',
                      $line->{account_category},
                      $line->{account_number} ],
                    [ 'q',
                      $line->{account_category} ],
                    [ 'q' ],
                ];
        },
        \&_non_gifi_row_props
        );
}

sub _row_handlers_default {
    return (
        sub {
            my ($line) = @_;
            return [ ($line->{account_type} eq 'H')
                     ? $line->{heading_path}
                     : [ ( # heading_path undefined iff
                           # hierarchy config missing
                           @{$line->{heading_path} || []},
                           $line->{account_number})
                     ],
                ];
        },
        \&_non_gifi_row_props
        );
}

sub _header_descriptions {
    my ($self) = @_;

    if ($self->gifi || $self->legacy_hierarchy) {
        return (
            E => {
                order            => '2', # Sort *after* Income
                account_number   => '',
                account_category => 'E',
                account_type     => 'H',
                account_description => $self->Text('Expenses')
            },
            I => {
                order            => '1', # Sort *before* Expenses
                account_number   => '',
                account_category => 'I',
                account_type     => 'H',
                account_description => $self->Text('Income')
            },
            A => {
                account_number   => 'A',
                account_category => 'A',
                account_type     => 'H',
                account_description => $self->Text('Assets')
            },
            L => {
                account_number   => 'L',
                account_category => 'L',
                account_type     => 'H',
                account_description => $self->Text('Liabilities')
            },
            Q => {
                account_number   => 'Q',
                account_category => 'Q',
                account_type     => 'H',
                account_description => $self->Text('Equity')
            },
            q => {
                account_number   => '',
                account_category => 'Q',
                account_type     => 'H',
                heading_path     => [ 'Q', 'q' ],
                account_description => $self->Text('Current earnings')
            },
            );
    }
    else {
        return (
            map {
                $_->{accno} => {
                    account_number      => $_->{accno},
                    account_description => $_->{description}
                }
            }
            $self->call_dbmethod(funcname => 'account__all_headings')
            );
    }
}

sub run_report {
    my ($self) = @_;

    my @lines = $self->report_base();
    my ($row_map, $row_props);
    if ($self->gifi) {
        ($row_map, $row_props) = _row_handlers_gifi;
    }
    elsif ($self->legacy_hierarchy) {
        ($row_map, $row_props) = _row_handlers_legacy;
    }
    else {
        ($row_map, $row_props) = _row_handlers_default;
    }

    my $col_id = $self->cheads->map_path($self->column_path_prefix);
    my $_from_date = $self->from_date->to_output($self->{formatter_options});
    my $_to_date = $self->to_date->to_output($self->{formatter_options});
    $self->cheads->id_props($col_id,
                            { description =>
                                  $self->Text(
                                      "[_1]\n[_2]",
                                      $_from_date,
                                      $_to_date),
                              from_date => $_from_date,
                              to_date => $_to_date
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
    my %header_desc = $self->_header_descriptions;
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

=back

=head1 SEE ALSO

=over

=item LedgerSMB::MooseTypes

=item LedgerSMB::Report

=item LedgerSMB::Report::Dates

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

__PACKAGE__->meta->make_immutable;

1;
