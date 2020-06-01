package _18_upgrade_checks;
use LedgerSMB::Database::ChangeChecks;


check q|Ensure that the gl database table doesn't contain NULL approval flags or transacton dates|,
    query => q|
        SELECT id, reference, description, approved,
               (select min(transdate) from acc_trans a where a.trans_id = gl.id)
               as transdate
        FROM gl
        WHERE gl.transdate IS NULL
        OR gl.approved IS NULL
        ORDER BY id
    |,
    description => q|
The upgrade process found gl table entries with NULL transaction dates or
approval flags. These are invalid and must be corrected as they are
prohibited by stricter data integrity rules enforced by the update.

The transaction dates offered in the table below are suggested values
based on data in your database.

Please fill in the missing data and press 'Save' to fix this issue.
|,

    tables => {
        gl => {
            prim_key => 'id',
        },
    },
    on_failure => sub {
        my ($dbh, $rows) = @_;

        describe;
        grid (
            $rows,
            name => 'gl',
            columns => [qw(id reference description notes trans_type_code transdate approved)],
            edit_columns => [qw(transdate approved)],
        );
        confirm save => 'Save';
    },
    on_submit => sub {
        my ($dbh, $rows) = @_;
        my $confirm = provided 'confirm';

        if ($confirm eq 'save') {
            save_grid $dbh, $rows, name => 'gl';
        }
        else {
            die "Unexpected confirmation value found: $confirm";
        }
    }
;


check q|Ensure that the ap database table doesn't contain NULL approval flags or transacton dates|,
    query => q|
        SELECT id, reference, description, approved,
               (select min(transdate) from acc_trans a where a.trans_id = ap.id)
               as transdate
        FROM ap
        WHERE ap.transdate IS NULL
        OR ap.approved IS NULL
        ORDER BY id
    |,
    description => q|
The upgrade process found ap table entries with NULL transaction dates or
approval flags. These are invalid and must be corrected as they are
prohibited by stricter data integrity rules enforced by the update.

The transaction dates offered in the table below are suggested values
based on data in your database.

Please fill in the missing data and press 'Save' to fix this issue.
|,

    tables => {
        ap => {
            prim_key => 'id',
        },
    },
    on_failure => sub {
        my ($dbh, $rows) = @_;

        describe;
        grid (
            $rows,
            name => 'ap',
            columns => [qw(id invnumber ordnumber curr notes description amount_bc transdate approved)],
            edit_columns => [qw(transdate approved)],
        );

        confirm save => 'Save';
    },
    on_submit => sub {
        my ($dbh, $rows) = @_;
        my $confirm = provided 'confirm';

        if ($confirm eq 'save') {
            save_grid $dbh, $rows, name => 'ap';
        }
        else {
            die "Unexpected confirmation value found: $confirm";
        }
    }
;


check q|Ensure that the ar database table doesn't contain NULL approval flags or transacton dates|,
    query => q|
        SELECT id, reference, description, approved,
               (select min(transdate) from acc_trans a where a.trans_id = ar.id)
               as transdate
        FROM ar
        WHERE ar.transdate IS NULL
        OR ar.approved IS NULL
        ORDER BY id
    |,
    description => q|
The upgrade process found ar table entries with NULL transaction dates or
approval flags. These are invalid and must be corrected as they are
prohibited by stricter data integrity rules enforced by the update.

The transaction dates offered in the table below are suggested values
based on data in your database.

Please fill in the missing data and press 'Save' to fix this issue.
|,

    tables => {
        ar => {
            prim_key => 'id',
        },
    },
    on_failure => sub {
        my ($dbh, $rows) = @_;

        describe;
        grid (
            $rows,
            name => 'ar',
            columns => [qw(id invnumber ordnumber curr notes description amount_bc transdate approved)],
            edit_columns => [qw(transdate approved)]
        );

        confirm save => 'Save';
    },
    on_submit => sub {
        my ($dbh, $rows) = @_;
        my $confirm = provided 'confirm';

        if ($confirm eq 'save') {
            save_grid $dbh, $rows, name => 'ar';
        }
        else {
            die "Unexpected confirmation value found: $confirm";
        }
    }
;


check q|Ensure that the acc_trans database table doesn't contain NULL approval flags or transacton dates|,
    query => q|
        SELECT *
        FROM acc_trans
        WHERE transdate IS NULL
        OR approved IS NULL
        ORDER BY entry_id
    |,
    description => q|
The upgrade process found acc_trans table entries with NULL transaction dates
or approval flags. These are invalid and must be corrected as they are
prohibited by stricter data integrity rules enforced by the update.

Please fill in the missing data and press 'Save' to fix this issue.
|,

    tables => {
        acc_trans => {
            prim_key => 'entry_id',
        },
    },
    on_failure => sub {
        my ($dbh, $rows) = @_;
        describe;
        grid (
            $rows,
            name => 'acc_trans',
            columns => [qw(entry_id trans_id amount_bc source memo voucher_id trans_id transdate approved)],
            edit_columns => [qw(transdate approved)]
        );
        confirm save => 'Save';
    },
    on_submit => sub {
        my ($dbh, $rows) = @_;
        my $confirm = provided 'confirm';

        if ($confirm eq 'save') {
            save_grid $dbh, $rows, name => 'acc_trans';
        }
        else {
            die "Unexpected confirmation value found: $confirm";
        }
    }
;


check q|Repair missing approval status for transactions|,
    query => q|
        SELECT *
        FROM transactions t
        JOIN (
            SELECT id, approved FROM ar
            UNION SELECT id, approved FROM ap
            UNION SELECT id, approved FROM gl
        ) g ON g.id = t.id
        WHERE t.approved IS NULL
    |,
    description => q|
The upgrade process found transaction table entries with a NULL approval
status. These are invalid and must be corrected as required by stricter
data integrity rules enforced by the update.

The missing data can be deduced from the corresponding
ar, ap or gl tables.

To fix this issue by automatically filling the missing data, press 'Repair'.
|,
    on_failure => sub {
        my ($dbh, $rows) = @_;
        describe;
        confirm repair => 'Repair';
    },
    on_submit => sub {
        my ($dbh, $rows) = @_;
        my $confirm = provided 'confirm';

        if ($confirm eq 'repair') {
            $dbh->do(
                q{UPDATE transactions }.
                q{SET approved = g.approved }.
                q{FROM ( }.
                q{SELECT id, approved FROM ar }.
                q{UNION SELECT id, approved FROM ap }.
                q{UNION SELECT id, approved FROM gl }.
                q{) g }.
                q{WHERE g.id = transactions.id }.
                q{AND transactions.approved IS NULL}
            ) or die "Failed to replace missing transactions.approved data: " . $dbh->errstr;
        }
        else {
            die "Unexpected confirmation value found: $confirm";
        }
    }
;


check q|Clear orphaned invoice rows|,
    query => q|
        SELECT * FROM invoice
        JOIN transactions t ON (invoice.trans_id = t.id)
        WHERE t.transdate IS NULL
        AND NOT EXISTS (SELECT 1 FROM acc_trans WHERE trans_id = t.id OR invoice_id = invoice.id)
        AND NOT EXISTS (SELECT 1 FROM ap WHERE ap.id = t.id)
        AND NOT EXISTS (SELECT 1 FROM ar WHERE ar.id = t.id)
        AND NOT EXISTS (SELECT 1 FROM gl WHERE gl.id = t.id)
    |,
    description => q|
The upgrade process found invoice rows which have no transaction date and
which are not part of any financial transaction.

These are invalid and must be removed before the upgrade can
be completed as it enforces stricter data integrity constraints.

Deleting these rows will not affect financial information.

To remove these rows and proceed with the update, press 'Delete'.
|,
    on_failure => sub {
        my ($dbh, $rows) = @_;
        describe;
        grid (
            $rows,
            name => 'invoice',
            columns => [qw(id description quantity allocated unit sellprice)],
        );
        confirm delete => 'Delete';
    },
    on_submit => sub {
        my ($dbh, $rows) = @_;
        my $confirm = provided 'confirm';

        if ($confirm eq 'delete') {

            $dbh->do(
                q{DELETE FROM invoice_note }.
                q{USING invoice, transactions t }.
                q{WHERE invoice_note.ref_key = invoice.id }.
                q{AND invoice.trans_id = t.id }.
                q{AND t.transdate IS NULL }.
                q{AND NOT EXISTS (SELECT 1 FROM acc_trans WHERE trans_id = t.id OR invoice_id = invoice.id) }.
                q{AND NOT EXISTS (SELECT 1 FROM ap WHERE ap.id = t.id) }.
                q{AND NOT EXISTS (SELECT 1 FROM ar WHERE ar.id = t.id) }.
                q{AND NOT EXISTS (SELECT 1 FROM gl WHERE gl.id = t.id)}
            ) or die "Failed to delete invoice_note records for orphaned invoices: " . $dbh->errstr;

            $dbh->do(
                q{DELETE FROM invoice_tax_form }.
                q{USING invoice, transactions t }.
                q{WHERE invoice_tax_form.invoice_id = invoice.id }.
                q{AND invoice.trans_id = t.id }.
                q{AND t.transdate IS NULL }.
                q{AND NOT EXISTS (SELECT 1 FROM acc_trans WHERE trans_id = t.id OR invoice_id = invoice.id) }.
                q{AND NOT EXISTS (SELECT 1 FROM ap WHERE ap.id = t.id) }.
                q{AND NOT EXISTS (SELECT 1 FROM ar WHERE ar.id = t.id) }.
                q{AND NOT EXISTS (SELECT 1 FROM gl WHERE gl.id = t.id)}
            ) or die "Failed to delete invoice_tax_form_records for orphaned invoices: " . $dbh->errstr;

            $dbh->do(
                q{DELETE FROM invoice }.
                q{USING transactions t }.
                q{WHERE invoice.trans_id = t.id }.
                q{AND t.transdate IS NULL }.
                q{AND NOT EXISTS (SELECT 1 FROM acc_trans WHERE trans_id = t.id OR invoice_id = invoice.id) }.
                q{AND NOT EXISTS (SELECT 1 FROM ap WHERE ap.id = t.id) }.
                q{AND NOT EXISTS (SELECT 1 FROM ar WHERE ar.id = t.id) }.
                q{AND NOT EXISTS (SELECT 1 FROM gl WHERE gl.id = t.id)}
            ) or die "Failed to delete orphamed invoice records: " . $dbh->errstr;
        }
        else {
            die "Unexpected confirmation value found: $confirm";
        }
    }
;

check q|Clear orphaned transaction's attached files|,
    query => q|
        SELECT id, transdate, file_name, uploaded_by, uploaded_at
        FROM file_transaction f
        JOIN transactions t ON (f.ref_key = t.id)
        WHERE t.transdate IS NULL
        AND NOT EXISTS (SELECT 1 FROM acc_trans WHERE trans_id = t.id OR voucher_id = v.id)
        AND NOT EXISTS (SELECT 1 FROM ap WHERE ap.id = t.id)
        AND NOT EXISTS (SELECT 1 FROM ar WHERE ar.id = t.id)
        AND NOT EXISTS (SELECT 1 FROM gl WHERE gl.id = t.id)
    |,
    description => q|
The upgrade process found files attached to orphaned transactions.

Due to stricter integrity constraints, these transactions can't be stored in
the database anymore. As a result, the files attached to these transactions
cannot remain connected. Two options are available:

1. 'Delete' the files listed below  
   This action can't be undone. As the files aren't available in the
   application, due to the fact that they are attached to orphaned
   transactions, this may not make a difference.
2. 'Copy' the files to the 'incoming' queue  
   This action preserves the data in the database. At the moment the data
   isn't accessible through the UI. Although data isn't directly accessible,
   it *will* be retained for future reference.

Please select either 'Delete' or 'Copy' below.
    |,
    on_failure => sub {
        my ($dbh, $rows) = @_;
        describe;
        grid (
            $rows,
            name => 'files',
            columns => [qw(id transdate file_name uploaded_by uploaded_at)],
            dropdowns => {
                uploaded_by => dropdown_sql($dbh, q|select entity_id as uploaded_by, name as description from employee_search|),
            },
        );
        confirm delete => 'Delete';
        confirm copy => 'Copy';
    },
    on_submit => sub {
        my ($dbh, $rows) = @_;
        my $confirm = provided 'confirm';

        if ($confirm eq 'delete') {

            $dbh->do(q|
        DELETE FROM file_transaction f
        USING transactions t
        WHERE (f.ref_key = t.id)
        AND t.transdate IS NULL
        AND NOT EXISTS (SELECT 1 FROM acc_trans WHERE trans_id = t.id OR trans_id = f.ref_key)
        AND NOT EXISTS (SELECT 1 FROM ap WHERE ap.id = t.id)
        AND NOT EXISTS (SELECT 1 FROM ar WHERE ar.id = t.id)
        AND NOT EXISTS (SELECT 1 FROM gl WHERE gl.id = t.id)
               |);
        }
        elsif ($confirm eq 'copy') {
            $dbh->do(q|
        INSERT INTO file_incoming (content, mime_type_id, file_name,
                     description, uploaded_by, uploaded_at, ref_key,
                     file_class)
        SELECT content, mime_type_id, file_name, description, uploaded_by,
                     uploaded_at, 0, 7
        FROM file_transaction f
        JOIN transactions t ON (f.ref_key = t.id)
        WHERE t.transdate IS NULL
        AND NOT EXISTS (SELECT 1 FROM acc_trans WHERE trans_id = t.id OR trans_id = f.ref_key)
        AND NOT EXISTS (SELECT 1 FROM ap WHERE ap.id = t.id)
        AND NOT EXISTS (SELECT 1 FROM ar WHERE ar.id = t.id)
        AND NOT EXISTS (SELECT 1 FROM gl WHERE gl.id = t.id)
                     |)
                and
                $dbh->do(q|
        DELETE FROM file_transaction f
        USING transactions t
        WHERE (f.ref_key = t.id)
        AND t.transdate IS NULL
        AND NOT EXISTS (SELECT 1 FROM acc_trans WHERE trans_id = t.id OR trans_id = f.ref_key)
        AND NOT EXISTS (SELECT 1 FROM ap WHERE ap.id = t.id)
        AND NOT EXISTS (SELECT 1 FROM ar WHERE ar.id = t.id)
        AND NOT EXISTS (SELECT 1 FROM gl WHERE gl.id = t.id)
                         |);
        }
        else {
            die "Unexpected confirmation value found: $confirm";
        }
    }
;


check q|Clear orphaned transaction entries|,
    query => q|
        SELECT * FROM transactions t
        WHERE (approved IS NULL OR transdate IS NULL)
        AND locked_by IS NULL
        AND approved_by IS NULL
        AND approved_at IS NULL
        AND NOT EXISTS (SELECT 1 FROM acc_trans WHERE trans_id = t.id)
        AND NOT EXISTS (SELECT 1 FROM ap WHERE ap.id = t.id)
        AND NOT EXISTS (SELECT 1 FROM ar WHERE ar.id = t.id)
        AND NOT EXISTS (SELECT 1 FROM gl WHERE gl.id = t.id)
        AND NOT EXISTS (SELECT 1 FROM file_transaction WHERE ref_key = t.id)
        AND NOT EXISTS (SELECT 1 FROM invoice WHERE trans_id = t.id)
        AND NOT EXISTS (SELECT 1 FROM new_shipto WHERE trans_id = t.id)
        AND NOT EXISTS (SELECT 1 FROM recurring WHERE id = t.id);
    |,
    description => q|
The upgrade process found orphaned transaction table entries which are not
referenced by anything else (meaning these transactions don't even have
transaction lines).

As the rows are not referenced by other tables and contain no data
themselves, they can be removed without affecting accounting data.

Please remove the orphaned transactions by pressing 'Delete'.
|,
    on_failure => sub {
        my ($dbh, $rows) = @_;
        describe;
        grid (
            $rows,
            name => 'transactions',
            columns => [qw(id table_name locked_by approved approved_by approved_at transdate)],
        );
        confirm delete => 'Delete';
    },
    on_submit => sub {
        my ($dbh, $rows) = @_;
        my $confirm = provided 'confirm';

        if ($confirm eq 'delete') {
            # It's possible vouchers are in the way of deleting
            # the orphaned transactions. Remove them.
            $dbh->do(q|
               DELETE FROM voucher v
               USING transactions t
               WHERE (v.trans_id = t.id)
               AND t.transdate IS NULL
               AND NOT EXISTS (SELECT 1 FROM acc_trans WHERE trans_id = t.id OR voucher_id = v.id)
               AND NOT EXISTS (SELECT 1 FROM ap WHERE ap.id = t.id)
               AND NOT EXISTS (SELECT 1 FROM ar WHERE ar.id = t.id)
               AND NOT EXISTS (SELECT 1 FROM gl WHERE gl.id = t.id)
               |);

            $dbh->do(
                q{DELETE FROM transactions t }.
                q{WHERE locked_by IS NULL }.
                q{AND approved_by IS NULL }.
                q{AND approved_at IS NULL }.
                q{AND transdate IS NULL }.
                q{AND NOT EXISTS (SELECT 1 FROM acc_trans WHERE trans_id = t.id) }.
                q{AND NOT EXISTS (SELECT 1 FROM ap WHERE ap.id = t.id) }.
                q{AND NOT EXISTS (SELECT 1 FROM ar WHERE ar.id = t.id) }.
                q{AND NOT EXISTS (SELECT 1 FROM gl WHERE gl.id = t.id) }.
                q{AND NOT EXISTS (SELECT 1 FROM file_transaction WHERE ref_key = t.id) }.
                q{AND NOT EXISTS (SELECT 1 FROM invoice WHERE trans_id = t.id) }.
                q{AND NOT EXISTS (SELECT 1 FROM new_shipto WHERE trans_id = t.id) }.
                q{AND NOT EXISTS (SELECT 1 FROM recurring WHERE id = t.id) }
            ) or die "Failed to delete orphaned transactions records: " . $dbh->errstr;
        }
        else {
            die "Unexpected confirmation value found: $confirm";
        }
    }
;


1;
