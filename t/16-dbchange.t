#!perl

=head1 UNIT TESTS FOR

LedgerSMB::Database::Change

=cut

use LedgerSMB::Database::Change;
use Test::More;

use DBI;
use File::Find;

my $testpath = 't/data/loadorder/';

#
#
######################################
#
#
# See also xt/43-dbchange.t
#
######################################


=head1 TEST PLAN

Data is in t/data/loadorder

=head2 File Load Tests

=over

=item basic constructor, no properties for test1

=item basic constructor, all properties for test2

=item sha should be same for both, but different from test3

=back

=cut

my @properties = qw(no_transactions reload_subsequent);
my $test1 = LedgerSMB::Database::Change->new($testpath . 'test1.sql');
ok($test1, 'got test1 object');
is($test1->path, 't/data/loadorder/test1.sql', 'got correct path for test1');
ok($test1->{properties}, 'got a property hash for test1');
ok(exists $test1->{properties}->{$_}, "$_ exists in test1's property hash")
   for @properties;
is($test1->{properties}->{$_}, undef, "$_ property for test1 is undefined")
   for @properties;



my $test2 = LedgerSMB::Database::Change->new($testpath . 'test2.sql',
            { map { $_ => 1 } @properties });

ok($test2, 'got test2 object');
is($test2->path, 't/data/loadorder/test2.sql', 'got correct path for test2');
ok($test2->{properties}, 'got a property hash for test2');
ok(exists $test2->{properties}->{$_}, "$_ exists in test2's property hash")
   for @properties;
is($test2->{properties}->{$_}, 1, "$_ property for test2 is 1")
   for @properties;


is($test1->sha, $test2->sha, 'SHA is equal for both test1 and test2');

my $test3 = LedgerSMB::Database::Change->new($testpath . 'test3.sql');
isnt($test1->sha, $test3->sha, 'SHA changes when content changes');


=head2 Change is considered applied

=over

=item Change doesn't exist in database

Change is considered not to be applied

=item Change exists in database

Change is considered to be applied

=item Older change exists in database

Change is considered to be applied

=back

=cut

my $dbh = DBI->connect('dbi:Mock:', '', '', { AutoCommit => 0 });
$dbh->{mock_session} = DBD::Mock::Session->new(
    'sess',
    # Query and results for 'test1->applied'
    {
        statement => 'SELECT * FROM db_patches WHERE sha = ?',
        bound_params => [
            'j2EN+E5Xgx+71nQ31HoZMrg1p/j9AmX6i2I+CXBCnBw6Ptk9C6iw1zdSOqIYTB/9juTSJ3NMHTOa+qj8hoG6+w'
            ],
        results => [
            []
            ],
    },
    # Query and results for 'test3->applied'
    {
        statement => 'SELECT * FROM db_patches WHERE sha = ?',
        bound_params => [
            'Bah66A76A5TIzYojM4ycVU0Ygux/VnT0cijWVq8S60okKTaTHEKx09A6P0QcEJ2T4ulbrxAUumktrn+0tf7u+g'
            ],
        results => [ [ 'sha', 'path', 'last_updated' ],
                     [ $test3->sha, $test3->path, '2016-01-01T00:00Z' ],
            ],
    },
    # Query and results for 'test4->applied' / sha for test4.sql
    {
        statement => 'SELECT * FROM db_patches WHERE sha = ?',
        bound_params => [
            'Bah66A76A5TIzYojM4ycVU0Ygux/VnT0cijWVq8S60okKTaTHEKx09A6P0QcEJ2T4ulbrxAUumktrn+0tf7u+g'
            ],
        results => [ ],
    },
    # Query and results for 'test4->applied' / sha for test4.sql@1
    {
        statement => 'SELECT * FROM db_patches WHERE sha = ?',
        bound_params => [
            'vgSYa/awWhu6mThj4XkESaW4lrJCogWgCr3gC72m6wOnFpJ1KrvU9kSI3D5JRvClyrXRPiOmjM7rEqumSbixdg'
            ],
        results => [
            [ 'sha', 'path', 'last_updated' ],
            [ 'some-sha', 'test4.sql', '2015-01-01T00:00Z' ]
            ],
    });

ok(! $test1->is_applied($dbh), 'test1 is not applied');
ok($test3->is_applied($dbh), 'test3 is applied');
my $test4 = LedgerSMB::Database::Change->new($testpath . 'test4.sql');
ok($test4->is_applied($dbh), 'an older version of test4 is applied');


=head2 Internals Tests

=over

=item _combine_transaction_blocks()

=cut

is_deeply([ LedgerSMB::Database::Change::_combine_statement_blocks(
            'begin;', 'a;', 'b;', 'commit;') ],
          [ 'a;b;' ],
          'Combine into single transaction');

is_deeply([ LedgerSMB::Database::Change::_combine_statement_blocks(
              'a;','begin;','b;', 'c;' ,'commit;','d;') ],
          [ 'a;', 'b;c;', 'd;' ],
          'Combine into multiple transactions');

=item _split_statements()

Verify that our statement parser can parse each of our changes files
without skipping content -- by glueing the parsed bits together and
comparing a cleaned-up result.

=cut

$test1->{_content} = "aa;\n b; c; \nbegin; d; e; commit;";
$test1->{properties}->{no_transactions} = 1;

is_deeply([ $test1->_split_statements() ],
          ['aa;', 'b;', 'c;', 'begin;', 'd;', 'e;', 'commit;'],
          'Split statements');

my @changes;
sub collect {
    return if $File::Find::name !~ m/\.sql$/;

    push @changes, $File::Find::name;
}
find(\&collect, 'sql/changes/');

for my $change (@changes) {
    open $fh, "<:encoding(UTF-8)", $change
        or BAIL_OUT("Can't open: $change ($!, $@)");
    my $content;
    {
        local $/;
        $content = <$fh>;
    }
    close $fh or diag("error closing $change $!");

    $test1->{_content} = $content;
    $test1->{properties}->{no_transactions} = 1;
    my $joined_content = join('', $test1->_split_statements);
    $joined_content =~ s/[\s\n\t]+//g;
    $content =~ s/--.*//g;
    $content =~ s/[\s\n\t]+//g;
    is($joined_content,$content,"Complete recognition of $change");
}


=back

=cut

done_testing;
