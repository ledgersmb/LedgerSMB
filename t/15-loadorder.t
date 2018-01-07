#!perl

=head1 UNIT TESTS FOR

LedgerSMB::Database::Loadorder

=cut

use Data::Dumper;

use LedgerSMB::Database::Loadorder;
use Test::More tests => 18;

=head1 TEST PLAN

data is in t/data/loadorder

=head2 parse tests

=over

=item get a loadorder object

=item scripts returns correct number

=item scripts all have correct paths

=item scripts all have correct properties

=back

=cut

my $loadorder = LedgerSMB::Database::Loadorder->new('t/data/loadorder/LOADORDER');

ok($loadorder, 'got a loadorder');
ok(ref $loadorder, 'loadorder is a reference');
is(scalar $loadorder->scripts, 6, '6 scripts detected');

like($_->path, qr#t/data/loadorder/test\d.sql#, 'Script path correct')
   for $loadorder->scripts;

my @notrans = (1, 3, 4);

my @scripts = $loadorder->scripts;

for my $loop (0 .. 5) {
    if (grep { $_ == $loop } @notrans) {
        ok($scripts[$loop]->{properties}->{no_transactions}, 'no transactions set');
    } else {
        ok(!$scripts[$loop]->{properties}->{no_transactions}, 'no transactions not set');
    }

}

$loadorder =
    LedgerSMB::Database::Loadorder->new('t/data/loadorder/LOADORDER',
                                        upto_tag => 'ignore-from-here');

@scripts = map { my $s = $_->path; $s =~ s|t/data/loadorder/||;
                 $s; } $loadorder->scripts;
is_deeply(\@scripts, ['test1.sql', 'test2.sql', 'test1.sql'],
   '3 scripts before "ignore-from-here" tag');

$loadorder =
    LedgerSMB::Database::Loadorder->new('t/data/loadorder/LOADORDER',
                                        upto_tag => 'ignore-me');

is(scalar $loadorder->scripts, 3, '3 scripts before "ignore-from-here" tag');

$loadorder =
    LedgerSMB::Database::Loadorder->new('t/data/loadorder/LOADORDER',
                                        upto_tag => 'ignore-me-too');

is(scalar $loadorder->scripts, 3, '3 scripts before "ignore-from-here" tag');
