#!perl

use Test2::V0;
use warnings;
use strict;

use DBD::Mock::Session;
use DBD::Mock;
use DBI;
use List::Util qw( any );

use LedgerSMB::Company;
my $mock;
my $company;
my $conf;
my $history;
my @queries;



$mock    = DBI->connect('dbi:Mock:', '', '', { PrintError => 1 });
$company = LedgerSMB::Company->new( dbh => $mock );
$conf    = $company->configuration;

$mock->{mock_add_resultset} = {
    results => [
        ['proname', 'pronargs', 'proargnames', 'argtypes'],
        ['config_gifi__save', 2, ['code', 'description'], ['text', 'text ']]
        ],
        };
$mock->{mock_add_resultset} = {
    results => [ ['config_gifi__save'], ['ok'] ],
    execute_attributes => {
        pg_type => [ qw/text/ ],
    },
}; # config_gifi__save returned row
$mock->{mock_add_resultset} =
    [
     ['proname', 'pronargs', 'proargnames', 'argtypes'],
     ['config_currency__save', 2, ['code', 'description'], ['text', 'text ']]
    ];
$mock->{mock_add_resultset} = {
    results => [ ['config_currency__save'], ['EUR'] ],
    execute_attributes => {
        pg_type => [ qw/text/ ],
    },
}; # config_currency__save returned row

ok lives {
$conf->from_xml(<<XML);
<configuration>
  <gifi-list>
   <gifi code="ok" description="oh nee" />
  </gifi-list>
  <coa>
  </coa>
  <currencies default="EUR">
   <currency code="EUR">EURO payment area currency</currency>
  </currencies>
  <settings>
    <setting name="phone" value="+1 555 206 111" />
  </settings>
</configuration>
XML

}
or diag $@;

$history = $mock->{mock_all_history};

@queries = grep {
    my $stmt = $_;
    any { $_ eq 'config_gifi__save' } @{ $_->{bound_params} // [] };
    } $history->@*;
is(scalar(@queries), 1, 'Test 1: config_gifi__save');
is($queries[0]->{bound_params}, [ 'config_gifi__save', 'public' ],
   'Test 1: config_gifi__save() arguments');

@queries = grep {
    $_->{statement} =~ m/config_currency__save/
    } $history->@*;
is(scalar(@queries), 1, 'Test 1: config_currency__save');
is($queries[0]->{bound_params}, [ 'EUR', 'EURO payment area currency' ],
   'Test 1: config_currency__save() arguments');

##########################################################################
#
# Test 2
#
##########################################################################


$mock    = DBI->connect('dbi:Mock:', '', '',
                        { PrintError => 1, RaiseError => 1 });
$company = LedgerSMB::Company->new( dbh => $mock );
$conf    = $company->configuration;

$mock->{mock_add_resultset} = {
    results => [
        ['proname', 'pronargs', 'proargnames', 'argtypes'],
        ['account_heading_save', 4,
         [qw/in_id in_accno in_description in_parent/],
         [qw/int text text int/]]
        ]
};
$mock->{mock_add_resultset} = {
    results => [
        [ 'account_heading_save' ],
        [ 1 ]
        ],
    execute_attributes => {
        pg_type => [ 'integer' ],
    },
};  # account_heading_save returned row
$mock->{mock_add_resultset} = {
    results => [
        ['proname', 'pronargs', 'proargnames', 'argtypes'],
        ['account__save_translation',
         3, ['id', 'language_code', 'description' ], ['int', 'text', 'text ']]
        ]
};
$mock->{mock_add_resultset} = {
    results => [ [ 'account_heading__save_translation' ],
                 [ undef ] ],
    execute_attributes => {
        pg_type => [ 'void' ],
    },
};  # account__save_translation returned row


$mock->{mock_add_resultset} = {
    results => [
        ['proname', 'pronargs', 'proargnames', 'argtypes'],
        ['account__save', 11,
         [qw/in_id in_accno in_description in_category in_gifi_accno in_heading
          in_contra in_tax in_link in_is_temp/],
         [qw/int text text char(1) text int
          bool bool text[] bool bool/]]
        ]
};
$mock->{mock_add_resultset} = {
    results => [ [ 'account__save' ],
                 [ 1 ] ],
    execute_attributes => {
        pg_type => [ 'integer' ],
    },
};  # account__save returned row

$mock->{mock_add_resultset} = {
    results => [
        ['proname', 'pronargs', 'proargnames', 'argtypes'],
        ['account__save_translation',
         3, ['id', 'language_code', 'description' ], ['int', 'text', 'text']]
        ]
};
$mock->{mock_add_resultset} = {
    results => [ [ 'account__save_translation' ],
                 [ undef ] ],
    execute_attributes => {
        pg_type => [ 'void' ],
    },
};  # account__save_translation returned row

$mock->{mock_add_resultset} = {
    results => [
        [ 'taxmodule_id', 'taxmodule_name' ],
        [ 1,            , 'Simple'         ],
        ],
};

$mock->{mock_add_resultset} = {
    results => [
        ['proname', 'pronargs', 'proargnames', 'argtypes'],
        ['account__save_tax',
         3,
         [qw/chart_id validto rate minvalue maxvalue
             taxnumber pass taxmodule_id old_validto/],
         [qw/int date numeric numeric numeric text int int date/]]
        ]
};
$mock->{mock_add_resultset} = {
    results => [ [ 'account__save_tax' ],
                 [ 1 ] ],
    execute_attributes => {
        pg_type => [ 'bool' ],
    },
};  # account__save_translation returned row


$mock->{mock_add_resultset} = {
    results => [
        ['proname', 'pronargs', 'proargnames', 'argtypes'],
        ['config_curr__save', 2, ['code', 'description'], ['text', 'text']]
        ]
};
$mock->{mock_add_resultset} = {
    results => [ ['config_curr__save'], ['EUR'] ],
    execute_attributes => {
        pg_type => [ 'text' ],
    },
};  # config_curr__save returned row

$mock->{mock_add_resultset} = {
    results => [
        [qw/ id accno description category gifi_accno heading_id
             contra tax obsolete is_heading / ],
        [ 'A-15', '0410', 'Maschinen', 'A', undef, 'H-1', 0, 1, 0, 0 ],
        ],
    execute_attributes => {
        pg_type => [ qw/text text text text text int bool bool bool bool/ ],
    },
};

ok lives {
$conf->from_xml(<<XML);
<configuration>
  <coa>
    <account-heading id="h-4" code="0400" description="MASCHINEN">
      <translation lang="en">MACHINES</translation>
      <account code="0410" description="Maschinen" category="Asset">
        <link code="AP_paid" />
        <tax>
          <rate value="0.15" />
        </tax>
        <translation lang="en">Machines</translation>
      </account>
    </account-heading>
  </coa>
  <currencies>
    <currency code="EUR">EURO payment area currency</currency>
  </currencies>
  <settings>
    <setting name="income_accno_id" accno="0410" />
  </settings>
</configuration>
XML

}
or diag $@;

$history = $mock->{mock_all_history};
# use Data::Dumper; print STDERR Dumper($history);

@queries = grep { $_->{statement} =~ m/account_heading_save(?!_)/ } $history->@*;
is(scalar(@queries), 1, 'Test 2: account_heading_save');
is($queries[0]->{bound_params}, [ undef, '0400', 'MASCHINEN', undef ],
   'Test 2: account_heading_save() arguments');

@queries = grep { $_->{statement} =~ m/account_heading__save_translation/ } $history->@*;
is(scalar(@queries), 1, 'Test 2: account_heading__save_translation');
is($queries[0]->{bound_params}, [ 1, 'en', 'MACHINES' ],
   'Test 2: account_heading__save_translation() arguments');


@queries = grep { $_->{statement} =~ m/account__save(?!_)/ } $history->@*;
is(scalar(@queries), 1, 'Test 2: account__save');
is($queries[0]->{bound_params},
   [ undef, '0410', 'Maschinen', 'A', undef, 1, 0, 1, [ 'AP_paid' ], 0 ],
   'Test 2: account__save() arguments');


@queries = grep { $_->{statement} =~ m/account__save_translation/ } $history->@*;
is(scalar(@queries), 1, 'Test 2: account__save_translation');
is($queries[0]->{bound_params},
   [ 1, 'en', 'Machines' ],
   'Test 2: account__save_translation() arguments');

@queries = grep { $_->{statement} =~ m/account__save_tax/ } $history->@*;
is(scalar(@queries), 1, 'Test 2: account__save_tax');
is($queries[0]->{bound_params},
   [ 1, 'infinity', 0.15, undef, undef, undef, 0, 1, undef ],
   'Test 2: account__save_tax() arguments');


@queries = grep { $_->{statement} =~ m/config_currency__save/ } $history->@*;
is(scalar(@queries), 1, '');
is($queries[0]->{bound_params}, [ 'EUR', 'EURO payment area currency' ], '');



done_testing;
