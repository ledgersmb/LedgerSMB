
package LedgerSMB::Reconciliation::Parser::CSV;

=head1 NAME

LedgerSMB::Reconciliation::Parser::CSV - Generic CSV customer bank statement parser

=head1 DESCRIPTION

Implements the mapping from generic CSV bank statement exports to
the input data for reconciliation.

=cut

use strict;
use warnings;
use Moo;
with 'LedgerSMB::Reconciliation::Format';

use Text::CSV;

use LedgerSMB::PGDate;
use LedgerSMB::PGNumber;

=head1 ATTRIBUTES

=head2 column_separator

Character used to separate columns in the CSV file.

Default: C<,>

=cut

has column_separator => (is => 'ro', default => sub { ',' });

=head2 column_quote

Character used to wrap column values in when they contain e.g. spaces.

Default: C<">

Example: The value C<My Name> will be wrapped, resulting in the output
C<"My Name"> between column separators.


=cut

has column_quote => (is => 'ro', default => sub { '"' });

=head2 column_value_escape

Character used to escape unsupported values inside quoted values. E.g. the
quoting character itself.

Default: C<">

Example: The value C<Then he said: "I'm fine, thanks"> will result in the following
output in the column: C<"Then he said: ""I'm fine, thanks""">.

=cut

has column_value_escape => (is => 'ro', default => sub { '"' });

=head2 first_row

Indicates whether the first row contains headers (column names) or values. In case
the first row is parsed as headers, the column references in the configuration are
treated as column names. In case the first row is parsed as data, the column references
are treated as column numbers.

Values: C<headers> (default) / C<data>

=cut

has first_row => (is => 'ro', default => sub { 'headers' });

=head2 mapping

Hash reference containing the mapping of the source columns to the desired output. Keys
in the hash are the output names. E.g.:

  {
     source => {
        column => 3, # numbered columns
     },
     date   => {
        column => 'A Name' # named columns
        format => 'DD/MM/YYYY',
     },
     ...
  }

The four keys are C<source>, C<date>, C<amount>, C<type>. Each has a
C<column> configuration item. The keys C<date> and C<amount> additionally have
a C<format> configuration. Please see L<LedgerSMB::PGDate> and L<LedgerSMB::PGNumber>
for valid values for the C<date> and C<amount> options, respectively.

=cut

has mapping => (is => 'ro', required => 1);

=head1 METHODS

=head2 process($fh)

Returns a reference to an array of entries extracted from the
transactions inn the ISO-20022/CAMT.053 XML file.

=cut

sub _process_named_columns {
    my ($self, $csv, $fh) = @_;
    my @cols = $csv->getline;
    my @entries;
    my $source = $self->mapping->{source}->{column};
    my $type = $self->mapping->{type}->{column};
    my $date = $self->mapping->{date}->{column};
    my $date_fmt = $self->mapping->{type}->{format};
    my $amount = $self->mapping->{amount}->{column};
    my $amount_fmt = { format => $self->mapping->{amount}->{format} };

    while (my $row = $csv->getline) {
        my %row;
        @row{@cols} = @$row;
        push @entries, {
            amount => LedgerSMB::PGNumber->from_input($row{$amount}, $amount_fmt),
            date   => LedgerSMB::PGDate->from_input($row{$date}, $date_fmt),
            source => $row{$source},
            type   => $row{$type}
        };
    }
    return \@entries;
}

sub _process_numbered_columns {
    my ($self, $csv, $fh) = @_;
    my @entries;
    my $source = $self->mapping->{source}->{column};
    my $type = $self->mapping->{type}->{column};
    my $date = $self->mapping->{date}->{column};
    my $date_fmt = $self->mapping->{type}->{format};
    my $amount = $self->mapping->{amount}->{column};
    my $amount_fmt = { format => $self->mapping->{amount}->{format} };

    while (my $row = $csv->getline) {
        push @entries, {
            amount => LedgerSMB::PGNumber->from_input($row->[$amount], $amount_fmt),
            date   => LedgerSMB::PGDate->from_input($row->[$date], $date_fmt),
            source => $row->[$source],
            type   => $row->[$type]
        };
    }
    return \@entries;
}

sub process {
    my $self = shift;
    my $fh   = shift;
    my $csv = Text::CSV->new(
        sep_char    => $self->column_separator,
        quote_char  => $self->column_quote,
        escape_char => $self->column_value_escape,
        );

    if ($self->first_row eq 'headers') {
        return $self->_process_named_columns($csv, $fh);
    }
    else {
        return $self->_process_numbered_columns($csv, $fh);
    }
}

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2023 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
