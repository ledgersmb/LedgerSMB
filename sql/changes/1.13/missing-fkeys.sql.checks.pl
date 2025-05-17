package _113_upgrade_checks;

use LedgerSMB::Database::ChangeChecks;


check q|Ensure that 'ar' table doesn't contain empty language codes|,
    query => q|SELECT * FROM ar WHERE language_code = ''|,
    description => q|
Your `ar` table contains rows with an empty `language_code`. As
tighter data integrity constraints are being introduced, these values
are no longer valid.

Empty language codes have previously been treated as equivalent to a
`NULL` value. To allow the upgrade to proceed, they will be explicitly
changed to `NULL` values.

This will not affect accounting data.

Click 'Proceed' to confirm conversion of empty language_code fields
to `NULL` values in the `ar` table.
|,
    on_failure => sub {
        my ($dbh, $rows) = @_;

        describe;
        confirm proceed => 'Proceed';
    },
    on_submit => sub {
        my ($dbh, $rows) = @_;

        my $confirm = provided 'confirm';

        if ($confirm eq 'proceed') {
            $dbh->do(q|UPDATE ar SET language_code=NULL WHERE language_code=''|)
                or die 'Unable to null empty ar.language_code: ' . $dbh->errstr;
        }
        else {
            die "Unexpected confirmation value found: $confirm";
        }
    }
;


check q|Ensure that 'ap' table doesn't contain empty language codes|,
    query => q|SELECT * FROM ap WHERE language_code = ''|,
    description => q|
Your `ap` table contains rows with an empty `language_code`. As
tighter data integrity constraints are being introduced, these values
are no longer valid.

Empty language codes have previously been treated as equivalent to a
`NULL` value. To allow the upgrade to proceed, they will be explicitly
changed to `NULL` values.

This will not affect accounting data.

Click 'Proceed' to confirm conversion of empty language_code fields
to `NULL` values in the `ap` table.
|,
    on_failure => sub {
        my ($dbh, $rows) = @_;

        describe;
        confirm proceed => 'Proceed';
    },
    on_submit => sub {
        my ($dbh, $rows) = @_;

        my $confirm = provided 'confirm';

        if ($confirm eq 'proceed') {
            $dbh->do(q|UPDATE ap SET language_code=NULL WHERE language_code=''|)
                or die 'Unable to null empty ap.language_code: ' . $dbh->errstr;
        }
        else {
            die "Unexpected confirmation value found: $confirm";
        }
    }
;


check q|Ensure that 'oe' table doesn't contain empty language codes|,
    query => q|SELECT * FROM oe WHERE language_code = ''|,
    description => q|
Your `oe` table contains rows with an empty `language_code`. As
tighter data integrity constraints are being introduced, these values
are no longer valid.

Empty language codes have previously been treated as equivalent to a
`NULL` value. To allow the upgrade to proceed, they will be explicitly
changed to `NULL` values.

This will not affect accounting data.

Click 'Proceed' to confirm conversion of empty language_code fields
to `NULL` values in the `oe` table.
|,
    on_failure => sub {
        my ($dbh, $rows) = @_;

        describe;
        confirm proceed => 'Proceed';
    },
    on_submit => sub {
        my ($dbh, $rows) = @_;

        my $confirm = provided 'confirm';

        if ($confirm eq 'proceed') {
            $dbh->do(q|UPDATE oe SET language_code=NULL WHERE language_code=''|)
                or die 'Unable to null empty oe.language_code: ' . $dbh->errstr;
        }
        else {
            die "Unexpected confirmation value found: $confirm";
        }
    }
;


1;
