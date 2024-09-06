=head1 UNIT TESTS FOR

LedgerSMB::Database::Change

=cut

use Test2::V0;

use LedgerSMB::Database::Change;
use DBI;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($OFF);

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

$dbh->do(qq{DROP DATABASE IF EXISTS $ENV{LSMB_NEW_DB}_41_dbchange})
    or die $dbh->errstr;
$dbh->do(qq{CREATE DATABASE $ENV{LSMB_NEW_DB}_41_dbchange})
    or die $dbh->errstr;
my $chg_db = DBI->connect(qq{dbi:Pg:dbname=$ENV{LSMB_NEW_DB}_41_dbchange},
                          undef, undef, { AutoCommit => 0, PrintError => 0 });
$chg_db->do(q{CREATE SCHEMA xyz})
    or die $chg_db->errstr;
my $change = LedgerSMB::Database::Change->new();
LedgerSMB::Database::Change::init($chg_db);
$chg_db->commit
    or die $chg_db->errstr;

=head1 TEST PLAN

=head2 Changes in non-'AutoCommit' mode (transactional mode)

=head3 WITHOUT transactions

=cut

$change->{properties}->{no_transactions} = 1;
$change->{_path} = 'test1a';
$change->{_sha} = 'nosha-test1a';

# Test a transaction: second statement will fail
# DDL statements in PSQL are transactional, so the first statement
#  will have no effect
$change->{_content} = qq{
  CREATE TABLE test1a (
     id serial
  );
  UPDATE test1a SET id = 'a';
};
$change->apply($chg_db);
$chg_db->commit or $chg_db->rollback;
$chg_db->do(q{SELECT count(*) FROM test1a;});
is $chg_db->err, undef, 'Expect no error after querying table test1a';
is $chg_db->rows, -1, 'Successfully created table test1a';

$chg_db->rollback;
$chg_db->disconnect;

=head3 WITH transactions

=cut

$chg_db = $chg_db->clone( { AutoCommit => 0 } );

$change->{properties}->{no_transactions} = 0;
$change->{_path} = 'test1b';
$change->{_sha} = 'nosha-test1b';

# Test a transaction: second statement will fail
# DDL statements in PSQL are transactional, so the first statement
#  will have no effect
$change->{_content} = qq{
  CREATE TABLE test1b (
     id serial
  );
  UPDATE test1b SET id = 'a';
};
eval { $change->apply($chg_db); };
$chg_db->commit or $chg_db->rollback;
$chg_db->do(q{SELECT count(*) FROM test1b;});
ok defined($chg_db->err), 'Expect error after querying table test1b';
like $chg_db->errstr, qr/relation "test1b" does not exist/,
    'Correctly failed to create table test1b';

$chg_db->rollback;
$chg_db->disconnect;



=head2 Changes in 'AutoCommit' mode

=head3 WITHOUT transactions

=cut

$chg_db = $chg_db->clone( { AutoCommit => 1 } );
$change->{properties}->{no_transactions} = 1;
$change->{_path} = 'test2a';
$change->{_sha} = 'nosha-test2a';

# Test a transaction: second statement will fail
# DDL statements in PSQL are transactional, so the first statement
#  will have no effect
$change->{_content} = qq{
  CREATE TABLE test2a (
     id serial
  );
  UPDATE test2a SET id = 'a';
};
$change->apply($chg_db);
$chg_db->do(q{SELECT count(*) FROM test2a;});
is $chg_db->err, undef, 'Expect no error after querying table test2a';
is $chg_db->rows, -1, 'Successfully created table test2a';

$chg_db->disconnect;

=head3 WITH transactions

=cut

$chg_db = $chg_db->clone( { AutoCommit => 1 } );
$change->{properties}->{no_transactions} = 0;
$change->{_path} = 'test2b';
$change->{_sha} = 'nosha-test2b';

# Test a transaction: second statement will fail
# DDL statements in PSQL are transactional, so the first statement
#  will have no effect
$change->{_content} = qq{
  CREATE TABLE test2b (
     id serial
  );
  UPDATE test2b SET id = 'a';
};
eval { $change->apply($chg_db); };
$chg_db->do(q{SELECT count(*) FROM test2b;});
ok defined($chg_db->err), 'Expect error after querying table test2b';
like $chg_db->errstr, qr/relation "test2b" does not exist/,
    'Correctly failed to create table test2b';

$chg_db->disconnect;

=head2 Script talk-back through LISTEN/NOTIFY.

=cut

$chg_db = $chg_db->clone( { AutoCommit => 1 } );
$change->{properties}->{no_transactions} = 0;
$change->{_path} = 'test3';
$change->{_sha} = 'nosha-test3';

# Test a transaction: second statement will fail
# DDL statements in PSQL are transactional, so the first statement
#  will have no effect
$change->{_content} = qq{
  CREATE TABLE test3 (
     id serial
  );
  select pg_notify('upgrade.' || current_database(),
                   '{"type":"feedback","content":"test"}');
};
eval { $change->apply($chg_db); };
$chg_db->do(q{SELECT count(*) FROM test3;});
is $chg_db->err, undef, 'Expect no error after querying table test3';
is $chg_db->rows, -1, 'Correctly created table test3';

my @row = $chg_db->selectrow_array(
    q{SELECT messages FROM db_patches WHERE sha = ? AND messages IS NOT NULL},
    undef, 'nosha-test3');
is $chg_db->err, undef, 'Expect no error after querying table db_patches';
ok defined($row[0]), 'db_patches contains our test case';

use Data::Dumper;
use JSON::PP;
my $json = JSON::PP->new;
my $msgs = $json->decode($row[0]);
is scalar($msgs->@*), 1, 'Exactly one element in the messages array';
diag Dumper($msgs);


$chg_db->disconnect;


=head1 POSTAMBLE

=cut

$dbh->do(qq{DROP DATABASE  "$ENV{LSMB_NEW_DB}_41_dbchange"});
$dbh->disconnect;

done_testing;
