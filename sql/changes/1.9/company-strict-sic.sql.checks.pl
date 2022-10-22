package _19_uprade_checks;

use LedgerSMB::Database::ChangeChecks;

check q|Ensure that the company table doesn't contain invalid SIC codes.|,
    query => q|
        SELECT  DISTINCT sic_code
        FROM	company
        WHERE	sic_code IS NOT NULL
            AND sic_code !~ '^\d{2,6}$'
        ORDER BY 1;
    |,
    description => q|
The upgrade process found SIC codes in the company table that 
contain non-digit characters, are less than 2 digits, or more than 6 digits.

These SIC codes must be removed from the company table as they are prohibited 
by stricter data integrity rules enforced by the update.

Removal of these entries will not affect accounting data. 

Please delete the invalid values listed in the table below by clicking
the 'Delete invalid SIC codes' button.
|,
    tables => {
        company => {
            prim_key => [qw(sic_code)]
        },
    },
    on_failure => sub {
        my ($dbh, $rows) = @_;

        describe;

        grid $rows,
            name => 'company SIC codes',
            table => 'company',
            columns => [qw(sic_code)];

        confirm delete => 'Delete invalid SIC codes';
    },
    on_submit => sub {
        my ($dbh, $rows) = @_;
        my $confirm = provided 'confirm';

        if ($confirm eq 'delete') {
            my $delete = $dbh->prepare(
                'UPDATE company '.
                'SET   sic_code = NULL '.
                'WHERE sic_code = ? '
            ) or die 'ERROR preparing sql to NULL invalid SIC codes in company table: ' . $dbh->errstr;

            foreach my $row(@$rows) {
                $delete->execute(
                    $row->{sic_code},
                ) or die 'Failed to NULL invalid SIC code: ' . $dbh->errstr;
            }
        }
        else {
          die "Unexpected confirmation value found: $confirm";
        }
    }
;


1;
