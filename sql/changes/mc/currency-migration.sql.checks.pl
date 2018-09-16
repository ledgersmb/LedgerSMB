
package mc_migration_checks;

use LedgerSMB::Database::ChangeChecks;


check q|Assert availability of at least one currency|,
    query => q|SELECT 1 WHERE NOT EXISTS (select 1 from defaults
                                           where setting_key = 'curr'
                                             and (value is not null)
                                             and (value <> ''))|,
    description => q|
The migration checks found that the database being migrated
does not have a default (also known as 'base') currency configured.

For correct operation, a base currency is required.

In the row below, please enter the 3-letter currency code of the currency
used to keep the books.  (If you don't know the 3-letter code, please
find a list here: https://www.xe.com/iso4217.php )

|,
    on_failure => sub {
        my ($dbh, $rows) = @_;

        describe;
        # There's a bit of trickery here: we fake a single failed
        # line (which there isn't; the failed line which *is* returned
        # by the query contains a single '1')
        grid [ { setting => 'Currency', value => '' } ],
           name => 'add_curr',
           columns => [ qw( setting value ) ],
           edit_columns => [ 'value' ];

        confirm configure => 'Configure';
    },
    on_submit => sub {
        my ($dbh, $rows) = @_;
        my $confirm = provided 'confirm';

        if ($confirm eq 'configure') {
            # We add the 3-letter currency code to the 'defaults' table
            $dbh->do("INSERT INTO defaults VALUES ('curr', ?)", {},
                     # There's a single row in the entry form:
                     # the one we faked. Just grab the one value we want
                     # from it. There's no helper method for this trickery,
                     # so just run a plain insert into the database.
                     $rows->[0]->{value})
              or die "Failed to add currency: " . $dbh->errstr;
        }
        else {
          die "Unexpected confirmation value found: $confirm";
        }
    }
;



check q|Assert 3-letter currency codes|,
    query => q|SELECT u.curr
                 FROM unnest(string_to_array(
                         (select value from defaults
                           where setting_key = 'curr')), ':') as u(curr)
                WHERE length(u.curr) > 3|,
    description => q|
The migration checks found that there are currency codes in the
the database being migrated that are longer than the supported
format of 3 characters.

For correct operation, currency codes need to adhere to ISO 4217.

In the table below, please enter the 3-letter currency codes of the
currencies with the overly-long codes.
(If you don't know the 3-letter code, please find a list
here: https://www.xe.com/iso4217.php )

|,
    on_failure => sub {
        my ($dbh, $rows) = @_;

        for my $row (@$rows) {
            $row->{setting} = 'Currency';
            $row->{value} = $row->{curr};
        }

        describe;
        grid $rows,
           name => 'valid_curr',
           columns => [ qw( setting value curr ) ],
           edit_columns => [ 'value' ];

        confirm change => 'Change';
    },
    on_submit => sub {
        my ($dbh, $rows) = @_;
        my $confirm = provided 'confirm';

        if ($confirm eq 'change') {
            # The table of rows sent to the UI doesn't actually exist.
            # So here we go through a bit of trickery to assemble the
            # string to be inserted into the 'defaults' table.

            # We replace the original values with (hopefully)
            # 3-letter currency codes.
            my %map = map {  { $_->{curr} => $_->{value} } } @$rows;

            my $sth = $dbh->prepare(q{select value from defaults
                                       where setting_key = 'curr'})
                or die "Failed to change currency codes: " . $dbh->errstr;
            $sth->execute()
                or die "Failed to change currency codes: " . $dbh->errstr;

            my ($curr_value) = $sth->fetchrow_array;
            my $stringified_curr =
                join(':',
                     map { $map{$_} // $_ }
                     split /:/, $curr_value);
            $dbh->do("UPDATE defaults SET value = ? WHERE setting_key = 'curr'",
                     {}, $stringified_curr)
              or die "Failed to change currency codes: " . $dbh->errstr;
        }
        else {
            die "Unexpected confirmation value found: $confirm";
        }
    }
;


1;
