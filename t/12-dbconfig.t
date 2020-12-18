#!perl

use File::Spec;
use Test::More;


use LedgerSMB::Sysconfig;

LedgerSMB::Sysconfig->initialize( $ENV{LSMB_CONFIG_FILE} // 'ledgersmb.conf' );
use LedgerSMB::Database::Config;

my $coa = LedgerSMB::Database::Config->new->charts_of_accounts;

ok( m/^[[:alnum:]]{2,2}(_[[:alnum:]]{2,2})?$/,
    "Returned coa key '$_' follows the xx or xx_xx pattern" )
    for (keys %$coa);
for my $coa_data (values %$coa) {
    is_deeply [ sort keys %$coa_data ], [ qw( chart code name sic ) ],
       'CoA data contains keys as per API declaration';
}
ok( scalar(@{$coa->{$_}->{chart}}) > 0,
    "There is at least one chart in coa data for '$_'")
    for (keys %$coa);
for my $type (qw( chart )) {
    for my $locale (keys %$coa) {
        ok( -f File::Spec->catfile('locale', 'coa', $locale, $_),
            "Returned coa item (locale/coa/$locale/$_) is a file")
            for (@{$coa->{$locale}->{$type}});
    }
}
for my $type (qw( sic )) {
    for my $locale (keys %$coa) {
        ok( -f File::Spec->catfile('sql', 'coa', $locale, $type, $_),
            "Returned coa item (sql/coa/$locale/$type/$_) is a file")
            for (@{$coa->{$locale}->{$type}});
    }
}

my $templates = LedgerSMB::Database::Config->new->templates;

is_deeply [ sort keys %$templates ], [ qw( demo xedemo ) ],
    'Returned template sets are the example templates';
for my $template (keys %$templates) {
    ok( -f $_, "Returned template item ($_) is a file" )
        for (@{$templates->{$template}});
}


done_testing;
