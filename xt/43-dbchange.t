=head1 UNIT TESTS FOR

LedgerSMB::Database::Change

=cut

use LedgerSMB::Database::Change;
use Test::Exception;
use Test::More;
use DBI;

#
#
######################################
#
#
# See also t/16-dbchange.t
#
######################################


my $dbh = DBI->connect("dbi:Pg:dbname=$ENV{LSMB_NEW_DB}", undef, undef,
                       { AutoCommit => 1, PrintError => 0 });

$dbh->do(qq{CREATE DATABASE $ENV{LSMB_NEW_DB}_41_dbchange});
my $chg_db = DBI->connect(qq{dbi:Pg:dbname=$ENV{LSMB_NEW_DB}_41_dbchange},
                          undef, undef, { AutoCommit => 0, PrintError => 0 });

my $change = LedgerSMB::Database::Change->new();
LedgerSMB::Database::Change::init($chg_db);
$chg_db->commit;

=head1 TEST PLAN

=head2 Changes in non-'AutoCommit' mode (transactional mode)

=head3 WITHOUT transactions

=cut

$change->{properties}->{no_transactions} = 1;
$change->{_path} = 'test1';
$change->{_sha} = 'nosha';

# Test a transaction: second statement will fail
# DDL statements in PSQL are transactional, so the first statement
#  will have no effect
$change->{_content} = qq{
  CREATE TABLE test1 (
     id serial
  );
  UPDATE test1 SET id = 'a';
};
$change->apply($chg_db);
$chg_db->commit or $chg_db->rollback;
$chg_db->do(q{SELECT count(*) FROM test1;});
is $chg_db->rows, -1, 'Successfully created the table';

$chg_db->rollback;
$chg_db->disconnect;

=head2 Changes in 'AutoCommit' mode

=head3 WITH transactions

=cut

$chg_db = $chg_db->clone( { AutoCommit => 1 } );
$change->{properties}->{no_transactions} = 1;

# Test a transaction: second statement will fail
# DDL statements in PSQL are transactional, so the first statement
#  will have no effect
$change->{_content} = qq{
  CREATE TABLE test2 (
     id serial
  );
  UPDATE test2 SET id = 'a';
};
$change->apply($chg_db);
$chg_db->do(q{SELECT count(*) FROM test2;});
like $chg_db->errstr, qr/relation "test2" does not exist/,
    'Correctly failed to create the table';

$chg_db->disconnect;

$dbh->do(qq{DROP DATABASE  "$ENV{LSMB_NEW_DB}_41_dbchange"});
$dbh->disconnect;

done_testing;
