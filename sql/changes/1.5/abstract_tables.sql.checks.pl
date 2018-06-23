
package migration_checks;


use LedgerSMB::Database::ChangeChecks;



check 'Assert duplicate values between abstract "note" table and children',
    description => q|
The migration checks found rows in your "note" table which also exist in
one of the derived tables. No rows should be in the "note" table directly;
only derived tables should have rows.

The rows affected are listed below. Please accept the proposed migration
strategy by clicking the 'Remove' button below.
    |,
    query => qq|SELECT * FROM ONLY note n
                 WHERE EXISTS (select 1 from note d
                                where n.id = d.id
                               group by d.id
                               having count(*) > 1 ) |,
    on_failure => sub {
        my ($dbh, $rows) = @_;

        describe;
        grid $rows,
            name => 'fix_pv',
            columns => [ qw( id subject note created created_by ) ];


        confirm remove => 'Remove';
    },
    on_submit => sub {
        my ($dbh, $failed_rows) = @_;

        my $confirm = provided 'confirm'; # 'remove' / 'retain'

        if ($confirm eq 'remove') {
            $dbh->do(q{DELETE FROM ONLY note n
                    WHERE EXISTS (select 1 from note d
                                   where n.id = d.id
                                  group by d.id
                                  having count(*) > 1)})
                or die 'Unable to remove duplicate "note": ' . $dbh->errstr;
        }
        else {
          die "Unexpected confirmation value found: $confirm";
        }
    };



check 'Assert duplicate values between abstract "file_secondary_attachment" table and children',
    description => q|
The migration checks found rows in your "file_secondary_attachment" table
which also exist in one of the derived tables. No rows should be in the
"file_secondary_attachment" table directly; only derived tables should
have rows.

The rows affected are listed below. Please accept the proposed migration
strategy by clicking the 'Remove' button below.
    |,
    query => qq|SELECT * FROM ONLY file_secondary_attachment n
                 WHERE EXISTS (select 1 from file_secondary_attachment d
                                where n.file_id = d.file_id
                               group by d.file_id
                               having count(*) > 1)  |,
    on_failure => sub {
        my ($dbh, $rows) = @_;

        describe;
        grid $rows,
            name => 'fix_pv',
            columns => [ qw( id subject note created created_by ) ];


        confirm remove => 'Remove';
    },
    on_submit => sub {
        my ($dbh, $failed_rows) = @_;

        my $confirm = provided 'confirm'; # 'remove' / 'retain'

        if ($confirm eq 'remove') {
            $dbh->do(q{DELETE FROM ONLY file_secondary_attachment n
                    WHERE EXISTS (select 1 from file_secondary_attachment d
                                   where n.id = d.id
                                  group by d.id
                                  having count(*) > 1)})
                or die 'Unable to remove duplicate "file_secondary_attachment"s: ' . $dbh->errstr;
        }
        else {
          die "Unexpected confirmation value found: $confirm";
        }
    };


check 'Assert duplicate values between abstract "file_base" table and children',
    description => q|
The migration checks found rows in your "file_base" table
which also exist in one of the derived tables. No rows should be in the
"file_base" table directly; only derived tables should
have rows.

The rows affected are listed below. Please accept the proposed migration
strategy by clicking the 'Remove' button below.
    |,
    query => qq|SELECT * FROM ONLY file_base n
                 WHERE EXISTS (select 1 from file_base d
                                where n.id = d.id
                               group by d.id
                               having count(*) > 1 )  |,
    on_failure => sub {
        my ($dbh, $rows) = @_;

        describe;
        grid $rows,
            name => 'fix_pv',
            columns => [ qw( id subject note created created_by ) ];


        confirm remove => 'Remove';
    },
    on_submit => sub {
        my ($dbh, $failed_rows) = @_;

        my $confirm = provided 'confirm'; # 'remove' / 'retain'

        if ($confirm eq 'remove') {
            $dbh->do(q{DELETE FROM ONLY file_base n
                    WHERE EXISTS (select 1 from file_base d
                                   where n.id = d.id
                                  group by d.id
                                  having count(*) > 1)})
                or die 'Unable to remove duplicate "file_base"s: ' . $dbh->errstr;
        }
        else {
          die "Unexpected confirmation value found: $confirm";
        }
    };


check 'Assert "note" table containing no records of its own',
    description => q|
The migration checks found rows in your "note" table
which do not exist in one of the derived table. This isn't allowed
and the upgrade process tries to introduce a restriction to prevent it.
However, the pre-existing rows prevent this new check from being
introduced.

The solution is to remove these rows from the database, as by design
they can't be connected to anything else in the database.

NOTE: Please backup your database before running this action, so you have
a source to recover these records from, in case the deleted records
contained vital information.

The rows affected are listed below. Please accept the proposed migration
strategy by clicking the 'Remove' button below, but understand that in
case there's no backup, this information is removed irreversibly.
    |,
    query => qq|SELECT * FROM ONLY note|,
    on_failure => sub {
        my ($dbh, $rows) = @_;

        describe;
        grid $rows,
            name => 'fix_pv',
            columns => [ qw( id subject note created created_by ) ];


        confirm remove => 'Remove';
    },
    on_submit => sub {
        my ($dbh, $failed_rows) = @_;

        my $confirm = provided 'confirm'; # 'remove' / 'retain'

        if ($confirm eq 'remove') {
            $dbh->do(q{DELETE FROM ONLY note})
                or die 'Unable to remove "note" records: ' . $dbh->errstr;
        }
        else {
          die "Unexpected confirmation value found: $confirm";
        }
    };


check 'Assert "file_secondary_attachment" table containing no records of its own',
    description => q|
The migration checks found rows in your "file_secondary_attachment" table
which do not exist in one of the derived table. This isn't allowed
and the upgrade process tries to introduce a restriction to prevent it.
However, the pre-existing rows prevent this new check from being
introduced.

The solution is to remove these rows from the database, as by design
they can't be connected to anything else in the database.

NOTE: Please backup your database before running this action, so you have
a source to recover these records from, in case the deleted records
contained vital information.

The rows affected are listed below. Please accept the proposed migration
strategy by clicking the 'Remove' button below, but understand that in
case there's no backup, this information is removed irreversibly.
    |,
    query => qq|SELECT * FROM ONLY file_secondary_attachment|,
    on_failure => sub {
        my ($dbh, $rows) = @_;

        describe;
        grid $rows,
            name => 'fix_pv',
            columns => [ qw( id subject note created created_by ) ];


        confirm remove => 'Remove';
    },
    on_submit => sub {
        my ($dbh, $failed_rows) = @_;

        my $confirm = provided 'confirm'; # 'remove' / 'retain'

        if ($confirm eq 'remove') {
            $dbh->do(q{DELETE FROM ONLY file_secondary_attachment})
                or die 'Unable to remove "file_secondary_attachment" records: ' . $dbh->errstr;
        }
        else {
          die "Unexpected confirmation value found: $confirm";
        }
    };



check 'Assert "file_base" table containing no records of its own',
    description => q|
The migration checks found rows in your "file_base" table
which do not exist in one of the derived table. This isn't allowed
and the upgrade process tries to introduce a restriction to prevent it.
However, the pre-existing rows prevent this new check from being
introduced.

The solution is to remove these rows from the database, as by design
they can't be connected to anything else in the database.

NOTE: Please backup your database before running this action, so you have
a source to recover these records from, in case the deleted records
contained vital information.

The rows affected are listed below. Please accept the proposed migration
strategy by clicking the 'Remove' button below, but understand that in
case there's no backup, this information is removed irreversibly.
    |,
    query => qq|SELECT * FROM ONLY file_base|,
    on_failure => sub {
        my ($dbh, $rows) = @_;

        describe;
        grid $rows,
            name => 'fix_pv',
            columns => [ qw( id subject note created created_by ) ];


        confirm remove => 'Remove';
    },
    on_submit => sub {
        my ($dbh, $failed_rows) = @_;

        my $confirm = provided 'confirm'; # 'remove' / 'retain'

        if ($confirm eq 'remove') {
            $dbh->do(q{DELETE FROM ONLY file_base})
                or die 'Unable to remove "file_base" records: ' . $dbh->errstr;
        }
        else {
          die "Unexpected confirmation value found: $confirm";
        }
    };




1;
