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

=back

=head1 SEMI-PUBLIC METHODS

=head2 run_report()

This sets rows to an empty arrayref, and sets balance_sheet to the structure of 
the balance sheet. 

=cut

sub run_report {
    my ($self) = @_;
   
    my @lines = $self->call_dbmethod(funcname => 'report__balance_sheet');
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
              ###TODO-REPORT-HEADINGS: 'current earnings' node doesn't
              # have a HEADING_PATH
              return $self->rheads->map_path([ ( @{$line->{heading_path}},
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
        my $col_id = $self->cheads->map_path([ 1 ]);
        # signs have already been converted in the query
        $self->cell_value($row_id, $col_id, $line->{balance});
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
