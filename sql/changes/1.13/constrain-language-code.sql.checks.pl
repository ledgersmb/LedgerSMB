package _113_upgrade_checks;

use LedgerSMB::Database::ChangeChecks;


check q|Remove invalid and unused language codes|,
    query => q|
        select * from language
        where code !~ '^[a-z]{2}(_[A-Z]{2})?$'
        and not language__is_used(code)
    |,
    description => q|
Your `language` table has unused records which have an invalid `code`.

This upgrade introduces constraints to improve data integrity, which
prohibit invalid language codes. So that the upgrade can proceed,
these records will be deleted. As they are not used within your
database, they can be safely deleted without impact on other records.

Click 'Delete' to confirm deletion of the unused `language` records
with an invalid `code`.
|,
    on_failure => sub {
        my ($dbh, $rows) = @_;

        describe;

        grid $rows,
            name => 'failing_rows',
            table => 'language',
            columns => [ qw| code description last_updated | ];

        confirm delete => 'Delete';
    },
    on_submit => sub {
        my ($dbh, $rows) = @_;

        my $confirm = provided 'confirm';

        if ($confirm eq 'delete') {

            my $delete_language = $dbh->prepare(join(' ',
                q|DELETE FROM language|,
                q|WHERE code = ?|,
            )) or die 'ERROR preparing quuery to delete language: ' . $dbh->errstr;

            foreach my $row (@$rows) {
                $delete_language->execute(
                    $row->{code}
                ) or die 'Failed to remove language record ' . $dbh->errstr;
            }
        }
        else {
            die "Unexpected confirmation value found: $confirm";
        }
    }
;


check q|Fix invalid language codes|,
    query => q|
        select * from language
        where code !~ '^[a-z]{2}(_[A-Z]{2})?$'
    |,
    description => q|
Your `language` table has records which have an invalid `code`.

This upgrade introduces constraints to improve data integrity, which
prohibit invalid language codes.

So that the upgrade can proceed, please provide a valid language code
for each of the languages below.

Language codes much be of the form `xx` (two lower-case letters) or
`xx_XX` (two lower-case letters, an underscore, followed by two
upper-case letters).

Examples of valid language codes can be found at:
[https://explore.transifex.com/languages/](https://explore.transifex.com/languages/)

For each language below, if the updated language code corresponds with
an existing language in the database, references will be updated and the
old invalid record deleted.

If the updated language code is 'new' a new language record
will be created and references updated before the old invalid record
is deleted.

Click 'Update' to confirm these changes.
|,
    tables => {
        language => {
            prim_key => 'code',
        },
    },
    on_failure => sub {
        my ($dbh, $rows) = @_;

        describe;

        grid $rows,
            name => 'invalid_language_codes',
            table => 'language',
            columns => [ qw| code description last_updated | ],
            edit_columns => [ 'code' ];

        confirm update => 'Update';
    },
    on_submit => sub {
        my ($dbh, $rows) = @_;

        my $confirm = provided 'confirm';

        if ($confirm eq 'update') {

            my $provided_data = provided 'invalid_language_codes';

            my $insert_language = $dbh->prepare(join(' ',
                q|INSERT INTO language (code, description)|,
                q|VALUES (?,?)|,
                q|ON CONFLICT DO NOTHING|,
            )) or die 'ERROR preparing query to insert language: ' . $dbh->errstr;

            my $delete_language = $dbh->prepare(join(' ',
                q|DELETE FROM language|,
                q|WHERE code = ?|,
            )) or die 'ERROR preparing quuery to delete language: ' . $dbh->errstr;

            my @ref_tables = qw(
                account_heading_translation
                account_translation
                ap
                ar
                business_unit_translation
                eca_invoice
                entity_credit_account
                oe
                parts_translation
                partsgroup_translation
                template
            );

            my @update_refs = map {
                $dbh->prepare(join(' ',
                    qq|UPDATE $_|,
                    q|SET language_code = ?|,
                    q|WHERE language_code = ?|,
                )) or die 'ERROR preparing query to update language refs: ' . $dbh->errstr;
            } @ref_tables;

            my $update_user_preferences = $dbh->prepare(join(' ',
                q|UPDATE user_preference|,
                q|SET value = ?|,
                q|WHERE value = ?|,
                q|AND name= 'language'|,
            )) or die 'ERROR preparing query to update language preferences: ' . $dbh->errstr;

            push @update_refs, $update_user_preferences;

            foreach my $row(@{$rows}) {
                $data = shift @{$provided_data};

                # No point continuing unless something has changed
                next unless $data->{code} ne $row->{code};

                $insert_language->execute(
                    $data->{code},
                    $row->{description},
                ) or die 'ERROR inserting language: ' . $dbh->errstr;

                foreach my $query (@update_refs) {
                    $query->execute(
                        $data->{code},
                        $row->{code},
                    ) or die 'ERROR updating language reference: ' . $dbh->errstr;
                }

                $delete_language->execute(
                    $row->{code},
                ) or die 'ERROR deleting language: ' . $dbh->errstr;
            }
        }
        else {
            die "Unexpected confirmation value found: $confirm";
        }
    }
;


1;
