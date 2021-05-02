
package deleted_transactions_checks;

use LedgerSMB::Database::ChangeChecks;


check q|Found files associated with non-existing transactions|,
    query => q|
      select id from file_transaction ft
       where not exists (select 1 from ar
                          where ft.ref_key = ar.id)
             and not exists (select 1 from ap
                              where ft.ref_key = ap.id)
             and not exists (select 1 from gl
                              where ft.ref_key = gl.id)
                   |,
    description => q|
The migration checks found rows in your "file_transaction" table holding
files which do not belong to any transactions.

The files will be deleted from your database, but to prevent dataloss,
we have saved them to /tmp/deleted_transaction_files/*

Click 'Continue' once you verified the files have been correctly saved.
|,
    on_failure => sub {
        my ($dbh, $rows) = @_;

        describe;

        my $dbname = $dbh->{pg_db};
        $dbname =~ s/[^a-zA-Z0-9_-]//g; # clean the database name
        my $tmp_dir = File::Spec->rel2abs(
            File::Spec->catdir('deleted_transaction_files', $dbname),
            File::Spec->tmpdir
            );
        unless (-e $tmp_dir) {
            mkdir $tmp_dir
                or die "Can't create directory $tmp_dir: $!";
        }

        if (@$rows) {
            # the list of rows is empty when this function is called as
            # part of the 'on_submit' phase, which happens to discover the
            # grids and options used in this function.
            #
            # However, I'm unable at the moment to let DBD::Mock know that
            # this query is being prepared, but never executed. Instead, we
            # just skip the entire block when there are no rows.
            my $sth =
                $dbh->prepare('select * from file_transaction where id = ?')
                or die $dbh->errstr;
            for my $row (@$rows) {
                my $tgt_dir = File::Spec->rel2abs(
                    $row->{id},
                    $tmp_dir);
                unless (-e $tgt_dir) {
                    mkdir $tgt_dir
                        or die "Can't create directory $tgt_dir: $!";
                }

                $sth->execute($row->{id})
                    or die $sth->errstr;

                my $rowcount = 0;
                while (my $fr = $sth->fetchrow_hashref('NAME_lc')) {
                    die "Too many rows returned!" if $rowcount > 0;
                    my $fn = $fr->{file_name};
                    # clean $fn
                    $fn =~ s/[^a-zA-Z0-9_-]//g;

                    $fn = File::Spec->rel2abs( $fn, $tgt_dir );
                    open my $fh, '>', $fn
                        or die "Failed to create file $fn for output: $!";
                    binmode $fh, ':bytes';
                    print $fh $fr->{content};
                    close $fh
                        or warn "Failed to close file $fn: $!";

                    $rowcount++;
                }
            }
        }

        confirm continue => 'Continue';
    },
    on_submit => sub {
        my ($dbh, $rows) = @_;

        for my $row (@$rows) {
            $dbh->do('DELETE FROM file_transaction WHERE id = ?',
                     {}, $row->{id});
        }
    }
;


1;
