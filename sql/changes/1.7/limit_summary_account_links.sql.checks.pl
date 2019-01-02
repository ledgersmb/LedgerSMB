
package migration_checks;

use LedgerSMB::Database::ChangeChecks;


check(
    q|Check that each account is a summary for no more than one transaction type|,
    query => q{
        SELECT account.accno AS "Account",
               account.id AS account_id,
               account.description AS "Description",
               string_agg(account_link.description, ', ') AS "Currently Summary For"
        FROM account
        JOIN account_link ON (
            account.id = account_link.account_id
        )
        JOIN account_link_description ON (
            account_link.description = account_link_description.description
        )
        WHERE account_link_description.summary IS TRUE
        GROUP BY account.accno, account.id, account.description
        HAVING COUNT(*) > 1
    },
    description => q{
The migration check found that at least one of your accounts is linked as
a summary account for multiple transaction types.

An account may only be a summary for a single transaction type, but this
was not enforced in earlier versions of LedgerSMB.

To continue with the upgrade, the listed accounts must be altered so that
they are a summary account for only a single transaction type, or changed
so that they are no longer a summary account.

For each account row below, please select which transaction type it should be
a summary accout for, or leave the selection blank if the account
should no longer be considered as a summary accout.

These choices will not alter accounting data, but will affect which
accounts appear in certain selection menus. After the upgrade, you may review
your Chart of Accounts to consider whether any additional summary accounts
should be configured.
},
    tables => {
        'account_link' => {
            prim_key => ['account_id', 'Description' ]
        }
    },
    on_failure => sub {
        my ($dbh, $rows) = @_;

        describe;
        grid(
           $rows,
           name => 'account_link',
           columns => ['Account', 'Description', 'Currently Summary For', 'New Summary For'],
           edit_columns => ['New Summary For', 'Description'],
           dropdowns => {
               'New Summary For' => sub {
                   my ($row) = @_;
                   my $q = $dbh->prepare("
                       SELECT description AS value, description AS text
                       FROM account_link
                       WHERE account_id = ?
                       ORDER BY description
                   ");
                   $q->execute($row->{account_id});
                   return $q->fetchall_arrayref({});
               },
           },
        );

        confirm proceed => 'Proceed';
    },
    on_submit => sub {
        my ($dbh, $rows) = @_;
        my $confirm = provided 'confirm';

        if ($confirm eq 'proceed') {
            # Query to remove 'extra' summary links
            my $q = $dbh->prepare("
                DELETE FROM account_link
                WHERE account_id = ?
                AND (? IS NULL OR ? != description)
            ");

            my $provided_data = provided 'account_link';

            foreach my $row(@{$rows}) {
                $data = shift @{$provided_data};
   
                $q->execute(
                    $row->{'account_id'},
                    $data->{'New Summary For'},
                    $data->{'New Summary For'},
                ) or die 'Failed to clear unwanted account link summary descriptors: ' . $dbh->errstr;
            }
        }
        else {
          die "Unexpected confirmation value found: $confirm";
        }
    },
);



1;
