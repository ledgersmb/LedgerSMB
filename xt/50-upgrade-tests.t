#!perl

use Test::More;
use LedgerSMB::Upgrade_Tests;

my @tests = sort { $a->{appname}     cmp $b->{appname}     or
                   $a->{name}        cmp $b->{name}        or
                   $a->{min_version} cmp $b->{min_version} or
                   $a->{max_version} cmp $b->{max_version}
                 } LedgerSMB::Upgrade_Tests->get_tests();

plan tests => scalar @tests;

sub _validate_displayed_key {
    my ($test,@keys) = @_;
    for my $key (@keys) {
        ok grep (/^$key$/, @{$test->{display_cols}}),
            "$key displayed in test $test->{name}:$test->{appname}";
    }
};

for my $test (@tests){
    subtest "$test->{name}:$test->{appname} $test->{min_version}-$test->{max_version}" => sub {
        _validate_displayed_key($test,keys %{$test->{selectable_values}})
            if $test->{selectable_values};

        _validate_displayed_key($test,@{$test->{columns}})
            if @{$test->{columns}};

        for my $btn (keys %{$test->{tooltips}}) {
            ok grep( /^$btn$/, @{$test->{buttons}}),
                "Button '$btn' in test '$test->{name}'";
        }
    }
}