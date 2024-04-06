#!perl

use v5.32;
use warnings;

use Test2::V0;
use Test2::Mock;

use LedgerSMB::Workflow::Persister::Email::TiedContent;

package TestDBI {
    sub prepare { return shift; }
    sub err { 0 }
    sub errstr { 'An error occurred' }
    sub execute { 1; }
    sub finish { }
    sub fetchrow_array { return ('the-value') }
};


my $dbh = bless {}, 'TestDBI';
my $o = tie my $t, 'LedgerSMB::Workflow::Persister::Email::TiedContent',
    dbh => $dbh,
    id  => 'id',
    wf_id => 'wf';


ok tied($t), 'Tied variable';
ok !$o->{has_value}, 'Not accessed => not retrieved => no value';
is $t, 'the-value', 'Expected variable value "the-value"';
ok !$o->{dirty}, 'Retrieved from database => clean';
ok $o->{has_value}, 'Have value after retrieval from DB';
is $o->{value}, 'the-value', 'Retrieved value is cached';


$o = tie $t, 'LedgerSMB::Workflow::Persister::Email::TiedContent',
    dbh => $dbh,
    id  => 'id',
    wf_id => 'wf';

$t = 'another-value';
ok tied($t), 'Still tied';
is $t, 'another-value', 'Expected value after assignmet';
ok $o->{dirty}, 'Set by assignment => dirty';
ok $o->{has_value}, 'Set by assignment => has a value';


$o = tie $t, 'LedgerSMB::Workflow::Persister::Email::TiedContent',
    dbh => $dbh,
    id  => 'id',
    wf_id => 'wf',
    value => 'preassigned-value';

ok tied($t), 'Still tied';
is $t, 'preassigned-value', 'Expected value after pre-assignmet';
ok $o->{dirty}, 'Set by pre-assignment => dirty';
ok $o->{has_value}, 'Set by pre-assignment => has a value';


done_testing;
