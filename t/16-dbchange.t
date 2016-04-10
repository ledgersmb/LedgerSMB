=head1 UNIT TESTS FOR

LedgerSMB::Database::Change

=cut

use LedgerSMB::Database::Change;
use Test::More tests => 20;

my $testpath = 't/data/loadorder/';

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

isnt($test1->sha, LedgerSMB::Database::Change->new($testpath . 'test3.sql')->sha, 'SHA changes when content chenges');

=head2 Wrapping Tests

=over

=item test1 should have begin/commit when asking for content

=item test2 should not have begin/commit when asking for content

=back

=cut

like($test1->content, qr/BEGIN;/, 'Test1 content has BEGIN');
like($test1->content, qr/COMMIT;/, 'Test1 content has COMMIT');

unlike($test2->content, qr/BEGIN;/, 'Test2 content has no BEGIN');
unlike($test2->content, qr/COMMIT;/, 'Test2 content has no COMMIT');
