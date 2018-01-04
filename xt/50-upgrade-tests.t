#!perl

use Test::More;
use LedgerSMB::Upgrade_Tests;

my @tests = LedgerSMB::Upgrade_Tests->get_tests();

plan tests => scalar @tests;

sub _validate_displayed_key {
    my ($test,@keys) = @_;
    for my $key (@keys) {
        ok grep( $key, $test->{display_cols}),
            "'$key' not displayed in test '$test->{name}'";
    }
};

for my $test (@tests){
    subtest $test->{name} => sub {
        _validate_displayed_key($test,keys %{$test->{selectable_values}})
            if $test->{selectable_values};

        _validate_displayed_key($test,$test->{columns})
            if $test->{columns};

        for my $btn (keys %{$test->{tooltips}}) {
            warn np $test if !grep( /^$btn$/, @{$test->{buttons}});
            ok grep( /^$btn$/, @{$test->{buttons}}),
                "No button '$btn' in test '$test->{name}'";
        }
    }
}