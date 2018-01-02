=head1 UNIT TESTS FOR

LedgerSMB::Database::Change

=cut

use LedgerSMB::Database::Change;
use Test::More;
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

isnt($test1->sha,
     LedgerSMB::Database::Change->new($testpath . 'test3.sql')->sha,
     'SHA changes when content changes');

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
