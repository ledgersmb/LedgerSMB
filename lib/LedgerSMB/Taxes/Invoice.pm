package LedgerSMB::Taxes::Invoice;

use strict;
use warnings;

=head1 NAME

LedgerSMB::Taxes::Invoice - Automatic taxation for API invoices

=head1 DESCRIPTION

Adapts invoice lines and the customer's billing address to the existing tax
provider interface. Customer and product tax eligibility are intersected before
running the configured providers. No manual tax details are generated.

=head1 METHODS

=head2 calculate($dbh, $invoice, $precision)

Returns taxes keyed by account number. The invoice contains C<eca>, C<lines>,
C<transdate> and C<lines_total>. Each line contains C<part> and C<total>.
Amounts are rounded after aggregation, using the company's currency precision.

=cut

use LedgerSMB::PGNumber;
use LedgerSMB::Tax;

sub calculate {
    my ($class, $dbh, $invoice, $precision) = @_;
    my $address = $dbh->selectrow_hashref(q{
        SELECT l.line_one AS address, l.city, l.state,
               l.mail_code AS zipcode, c.short_name AS country
          FROM entity_credit_account eca
          LEFT JOIN eca_to_location el ON el.credit_id = eca.id
                                      AND el.location_class = 1
          LEFT JOIN entity_to_location et ON et.entity_id = eca.entity_id
                                         AND et.location_class = 1
          LEFT JOIN location l ON l.id = coalesce(el.location_id, et.location_id)
          LEFT JOIN country c ON c.id = l.country_id
         WHERE eca.id = ?
    }, {}, $invoice->{eca}->{id});
    my $form = bless {
        ($address // {})->%*,
        dbh => $dbh,
        transdate => $invoice->{transdate},
        subtotal => $invoice->{lines_total},
    }, $class;
    my $accounts = $dbh->selectcol_arrayref(q{
        SELECT a.accno FROM account a JOIN eca_tax et ON et.chart_id = a.id
         WHERE et.eca_id = ? ORDER BY a.accno
    }, {}, $invoice->{eca}->{id});
    # LedgerSMB::Tax declares the legacy package name Tax.
    my @providers = Tax::init_taxes($form, join ' ', @$accounts); ## no critic (Modules::RequireExplicitInclusion)
    my %eligible;
    my %taxes;
    for my $line ($invoice->{lines}->@*) {
        my $part_id = $line->{part}->{id};
        $eligible{$part_id} //= {
            map { $_ => 1 } $dbh->selectcol_arrayref(q{
                SELECT a.accno FROM account a
                  JOIN partstax pt ON pt.chart_id = a.id WHERE pt.parts_id = ?
            }, {}, $part_id)->@*
        };
        my @line_taxes = grep { $eligible{$part_id}->{$_->account} } @providers;
        Tax::calculate_taxes(\@line_taxes, $form, $line->{total}, 0); ## no critic (Modules::RequireExplicitInclusion)
        for my $provider (@line_taxes) {
            my $account = $provider->account;
            my $tax = $taxes{$account} //= {
                tax => { chart_id => $dbh->selectrow_array(
                    'SELECT id FROM account WHERE accno = ?', {}, $account) },
                amount => LedgerSMB::PGNumber->bzero,
            };
            $tax->{amount} += $provider->value;
            $tax->{source} = $form->{'taxsource_' . $account};
        }
    }
    for my $tax (values %taxes) {
        $tax->{amount} = $tax->{amount}->copy->bfround(
            -$precision, $tax->{amount} < 0 ? '-inf' : '+inf');
    }
    return \%taxes;
}

=head2 dberror($query)

Reports database errors raised by the legacy tax initialization interface.

=cut

sub dberror {
    my ($self, $query) = @_;
    die $self->{dbh}->errstr;
}

1;

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version. A copy of the license should have been included with
your software.

=cut
