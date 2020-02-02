package _18_uprade_checks;

use LedgerSMB::Database::ChangeChecks;

check q|Ensure that the database doesn't contain NULL default exchange rates|,
    query => q|
        SELECT exchangerate_type.description,
               r.rate_type,
               r.curr,
               r.valid_from,
               r.valid_to,
               r.rate
        FROM exchangerate_default r
        JOIN exchangerate_type ON exchangerate_type.id = r.rate_type
        WHERE r.rate IS NULL
        ORDER BY valid_from
    |,
    description => q|
The upgrade process found exchange rate defaults with NULL values, which
are invalid.

These defaults must be removed as they are prohibited by stricter data
integrity rules enforced by the update.

Removal of these entries will not affect accounting data. They are used
only to pre-populate the exchange rate field when entering a new transaction.

Please delete the invalid values listed in the table below by clicking
the 'Delete null exchange rate defaults' button.
|,
    tables => {
        exchangerate_default => {
            prim_key => [qw(rate_type curr valid_from)]
        },
    },
    on_failure => sub {
        my ($dbh, $rows) = @_;

        describe;

        grid $rows,
            name => 'exchange rate defaults',
            table => 'exchangerate_default',
            columns => [qw(description curr valid_from valid_to rate)];

        confirm delete => 'Delete null exchange rate defaults';
    },
    on_submit => sub {
        my ($dbh, $rows) = @_;
        my $confirm = provided 'confirm';

        if ($confirm eq 'delete') {
            my $delete = $dbh->prepare(
                'DELETE FROM exchangerate_default '.
                'WHERE rate_type = ? '.
                'AND curr = ? '.
                'AND valid_from = ?'
            ) or die 'ERROR preparing sql to remove default exchange rate ' . $dbh->errstr;

            foreach my $row(@$rows) {
                $delete->execute(
                    $row->{rate_type},
                    $row->{curr},
                    $row->{valid_from},
                ) or die 'Failed to remove default exchange rate: ' . $dbh->errstr;
            }
        }
        else {
          die "Unexpected confirmation value found: $confirm";
        }
    }
;


1;
