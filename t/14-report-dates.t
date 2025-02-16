#!/usr/bin/perl

use Test2::V0;

use Data::Dumper;
use URI;

use LedgerSMB::PGDate;
use LedgerSMB::Report::PNL::Income_Statement;
use LedgerSMB::Report::Balance_Sheet;


#   Test report date and comparison period calculations

# Test report date parsing and calculation

# scenarios consist of various combinations of selections for:

# 'from' dates, years&periods
# 'to' dates,
# period intervals


{  # Scenario 1: PNL, from & to dates, no comparison periods
    my $rpt = LedgerSMB::Report::PNL::Income_Statement->new(
        _uri => URI->new,
        basis => 'accrual',
        ignore_yearend => 'all',
        from_date => LedgerSMB::PGDate->from_input( '2016-01-01', format => 'YYYY-MM-DD' ),
        to_date => LedgerSMB::PGDate->from_input( '2016-12-31', format => 'YYYY-MM-DD' ),
        interval => 'year', # just a random valid value
        comparison_type => 'by_dates',
        );
    is($rpt->date_from->to_output, '2016-01-01', 'pnl, no cmp, from date');
    is($rpt->date_to->to_output, '2016-12-31', 'pnl, no cmp, to date');
    is($rpt->comparison_periods, 0, 'pnl, no cmp, # of comparisons');
    is(scalar(@{$rpt->comparisons}), 0, 'pnl, no cmp, count of comparisons');
}

{  # Scenario 2: PNL, from & to dates, 1 comparison period (by dates)
    my $rpt = LedgerSMB::Report::PNL::Income_Statement->new(
        _uri => URI->new,
        basis => 'accrual',
        ignore_yearend => 'all',
        from_date => LedgerSMB::PGDate->from_input( '2016-01-01', format => 'YYYY-MM-DD' ),
        to_date => LedgerSMB::PGDate->from_input( '2016-12-31', format => 'YYYY-MM-DD' ),
        interval => 'year', # just a random valid value
        comparison_periods => '1',
        comparison_type => 'by_dates',
        from_date_1 => LedgerSMB::PGDate->from_input( '2015-01-01', format => 'YYYY-MM-DD' ),
        to_date_1 => LedgerSMB::PGDate->from_input( '2015-12-31', format => 'YYYY-MM-DD' ),
        );
    is($rpt->date_from->to_output, '2016-01-01',
       'pnl, 1 cmp by dates, from date');
    is($rpt->date_to->to_output, '2016-12-31', 'pnl, 1 cmp by dates, to date');
    is(scalar(@{$rpt->comparisons}), 1, 'pnl, 1 cmp by dates, # of comparisons');
    is($rpt->comparisons->[0]->{from_date}->to_output, '2015-01-01',
       'pnl, 1 cmp by dates, from date cmp 1');
    is($rpt->comparisons->[0]->{to_date}->to_output, '2015-12-31',
       'pnl, 1 cmp by dates, to date cmp 1');
}

{  # Scenario 3: PNL, from date, 1 comparison period (by periods/year/date)
    my $rpt = LedgerSMB::Report::PNL::Income_Statement->new(
        _uri => URI->new,
        basis => 'accrual',
        ignore_yearend => 'all',
        from_date => LedgerSMB::PGDate->from_input( '2016-01-05', format => 'YYYY-MM-DD' ),
        to_date => LedgerSMB::PGDate->from_input( '2017-01-04', format => 'YYYY-MM-DD' ),
        interval => 'year', # just a random valid value
        comparison_periods => '1',
        comparison_type => 'by_periods',
        );
    is($rpt->date_from->to_output, '2016-01-05',
       'pnl, 1 cmp by periods/year, from date');
    is($rpt->date_to->to_output, '2017-01-04',
       'pnl, 1 cmp by periods/year, to date');
    is(scalar(@{$rpt->comparisons}), 1,
       'pnl, 1 cmp by periods/year, # of comparisons');
    is($rpt->comparisons->[0]->{from_date}->to_output, '2015-01-05',
       'pnl, 1 cmp by periods/year, from date cmp 1');
    is($rpt->comparisons->[0]->{to_date}->to_output, '2016-01-04',
       'pnl, 1 cmp by periods/year, to date cmp 1');
}

{  # Scenario 4: PNL, from month & year, 1 comparison period (by periods/year)
    my $rpt = LedgerSMB::Report::PNL::Income_Statement->new(
        _uri => URI->new,
        basis => 'accrual',
        ignore_yearend => 'all',
        from_date => LedgerSMB::PGDate->from_input( '2016-01-01', format => 'YYYY-MM-DD' ),
        to_date => LedgerSMB::PGDate->from_input( '2016-12-31', format => 'YYYY-MM-DD' ),
        interval => 'year', # just a random valid value
        comparison_periods => '1',
        comparison_type => 'by_periods',
        );
    is($rpt->date_from->to_output, '2016-01-01',
       'pnl, 1 cmp by periods/year, from date');
    is($rpt->date_to->to_output, '2016-12-31',
       'pnl, 1 cmp by periods/year, to date');
    is(scalar(@{$rpt->comparisons}), 1,
       'pnl, 1 cmp by periods/year, # of comparisons');
    is($rpt->comparisons->[0]->{from_date}->to_output, '2015-01-01',
       'pnl, 1 cmp by periods/year, from date cmp 1');
    is($rpt->comparisons->[0]->{to_date}->to_output, '2015-12-31',
       'pnl, 1 cmp by periods/year, to date cmp 1');
}


{  # Scenario 5: PNL, from month & year, 1 comparison period (by periods/quarter)
    my $rpt = LedgerSMB::Report::PNL::Income_Statement->new(
        _uri => URI->new,
        basis => 'accrual',
        ignore_yearend => 'all',
        from_month => '01',
        from_year => '2016',
        interval => 'quarter', # just a random valid value
        comparison_periods => '1',
        comparison_type => 'by_periods',
        );
    is($rpt->date_from->to_output, '2016-01-01',
       'pnl, 1 cmp by periods/quarter, from date');
    is($rpt->date_to->to_output, '2016-03-31',
       'pnl, 1 cmp by periods/quarter, to date');
    is(scalar(@{$rpt->comparisons}), 1,
       'pnl, 1 cmp by periods/quarter, # of comparisons');
    is($rpt->comparisons->[0]->{from_date}->to_output, '2015-10-01',
       'pnl, 1 cmp by periods/quarter, from date cmp 1');
    is($rpt->comparisons->[0]->{to_date}->to_output, '2015-12-31',
       'pnl, 1 cmp by periods/quarter, to date cmp 1');
}

{  # Scenario 6: PNL, from date, 1 comparison period (by periods/month)
    my $rpt = LedgerSMB::Report::PNL::Income_Statement->new(
        _uri => URI->new,
        basis => 'accrual',
        ignore_yearend => 'all',
        from_month => '01',
        from_year => '2016',
        interval => 'month', # just a random valid value
        comparison_periods => '1',
        comparison_type => 'by_periods',
        );
    is($rpt->date_from->to_output, '2016-01-01',
       'pnl, 1 cmp by periods/month, from date');
    is($rpt->date_to->to_output, '2016-01-31',
       'pnl, 1 cmp by periods/month, to date');
    is(scalar(@{$rpt->comparisons}), 1,
       'pnl, 1 cmp by periods/month, # of comparisons');
    is($rpt->comparisons->[0]->{from_date}->to_output, '2015-12-01',
       'pnl, 1 cmp by periods/month, from date cmp 1');
    is($rpt->comparisons->[0]->{to_date}->to_output, '2015-12-31',
       'pnl, 1 cmp by periods/month, to date cmp 1');
}

{  # Scenario 7: PNL, from date, 9 comparisons period (by periods/month)
    my $rpt = LedgerSMB::Report::PNL::Income_Statement->new(
        _uri => URI->new,
        basis => 'accrual',
        ignore_yearend => 'all',
        from_month => '01',
        from_year => '2016',
        interval => 'month', # just a random valid value
        comparison_periods => '9',
        comparison_type => 'by_periods',
        );
    is($rpt->date_from->to_output, '2016-01-01',
       'pnl, 9 cmp by periods/month, from date');
    is($rpt->date_to->to_output, '2016-01-31',
       'pnl, 9 cmp by periods/month, to date');
    is(scalar(@{$rpt->comparisons}), 9,
       'pnl, 9 cmp by periods/month, # of comparisons');
    is($rpt->comparisons->[0]->{from_date}->to_output, '2015-12-01',
       'pnl, 9 cmp by periods/month, from date cmp 1');
    is($rpt->comparisons->[0]->{to_date}->to_output, '2015-12-31',
       'pnl, 9 cmp by periods/month, to date cmp 1');
    is($rpt->comparisons->[1]->{from_date}->to_output, '2015-11-01',
       'pnl, 9 cmp by periods/month, from date cmp 2');
    is($rpt->comparisons->[1]->{to_date}->to_output, '2015-11-30',
       'pnl, 9 cmp by periods/month, to date cmp 2');
    is($rpt->comparisons->[2]->{from_date}->to_output, '2015-10-01',
       'pnl, 9 cmp by periods/month, from date cmp 3');
    is($rpt->comparisons->[2]->{to_date}->to_output, '2015-10-31',
       'pnl, 9 cmp by periods/month, to date cmp 3');
    is($rpt->comparisons->[3]->{from_date}->to_output, '2015-09-01',
       'pnl, 9 cmp by periods/month, from date cmp 4');
    is($rpt->comparisons->[3]->{to_date}->to_output, '2015-09-30',
       'pnl, 9 cmp by periods/month, to date cmp 4');
    is($rpt->comparisons->[4]->{from_date}->to_output, '2015-08-01',
       'pnl, 9 cmp by periods/month, from date cmp 5');
    is($rpt->comparisons->[4]->{to_date}->to_output, '2015-08-31',
       'pnl, 9 cmp by periods/month, to date cmp 5');
    is($rpt->comparisons->[5]->{from_date}->to_output, '2015-07-01',
       'pnl, 9 cmp by periods/month, from date cmp 6');
    is($rpt->comparisons->[5]->{to_date}->to_output, '2015-07-31',
       'pnl, 9 cmp by periods/month, to date cmp 6');
    is($rpt->comparisons->[6]->{from_date}->to_output, '2015-06-01',
       'pnl, 9 cmp by periods/month, from date cmp 7');
    is($rpt->comparisons->[6]->{to_date}->to_output, '2015-06-30',
       'pnl, 9 cmp by periods/month, to date cmp 7');
    is($rpt->comparisons->[7]->{from_date}->to_output, '2015-05-01',
       'pnl, 9 cmp by periods/month, from date cmp 8');
    is($rpt->comparisons->[7]->{to_date}->to_output, '2015-05-31',
       'pnl, 9 cmp by periods/month, to date cmp 8');
    is($rpt->comparisons->[8]->{from_date}->to_output, '2015-04-01',
       'pnl, 9 cmp by periods/month, from date cmp 9');
    is($rpt->comparisons->[8]->{to_date}->to_output, '2015-04-30',
       'pnl, 9 cmp by periods/month, to date cmp 9');
}





{  # Scenario 1: B/S, from & to dates, no comparison periods
    my $rpt = LedgerSMB::Report::Balance_Sheet->new(
        _uri => URI->new,
        basis => 'accrual',
        ignore_yearend => 'all',
        from_date => LedgerSMB::PGDate->from_input( '2016-01-01', format => 'YYYY-MM-DD' ),
        to_date => LedgerSMB::PGDate->from_input( '2016-12-31', format => 'YYYY-MM-DD' ),
        interval => 'year', # just a random valid value
        comparison_type => 'by_dates',
        );
    is($rpt->date_from->to_output, '2016-01-01', 'b/s, no cmp, from date');
    is($rpt->date_to->to_output, '2016-12-31', 'b/s, no cmp, to date');
    is($rpt->comparison_periods, 0, 'b/s, no cmp, # of comparisons');
    is(scalar(@{$rpt->comparisons}), 0, 'b/s, no cmp, count of comparisons');
}

{  # Scenario 2: B/S, from & to dates, 1 comparison period (by dates)
    my $rpt = LedgerSMB::Report::Balance_Sheet->new(
        _uri => URI->new,
        ignore_yearend => 'all',
        from_date => LedgerSMB::PGDate->from_input( '2016-01-01', format => 'YYYY-MM-DD' ),
        to_date => LedgerSMB::PGDate->from_input( '2016-12-31', format => 'YYYY-MM-DD' ),
        interval => 'year', # just a random valid value
        comparison_periods => '1',
        comparison_type => 'by_dates',
        from_date_1 => LedgerSMB::PGDate->from_input( '2015-01-01', format => 'YYYY-MM-DD' ),
        to_date_1 => LedgerSMB::PGDate->from_input( '2015-12-31', format => 'YYYY-MM-DD' ),
        );
    is($rpt->date_from->to_output, '2016-01-01',
       'b/s, 1 cmp by dates, from date');
    is($rpt->date_to->to_output, '2016-12-31', 'b/s, 1 cmp by dates, to date');
    is(scalar(@{$rpt->comparisons}), 1, 'b/s, 1 cmp by dates, # of comparisons');
    is($rpt->comparisons->[0]->{from_date}->to_output, '2015-01-01',
       'b/s, 1 cmp by dates, from date cmp 1');
    is($rpt->comparisons->[0]->{to_date}->to_output, '2015-12-31',
       'b/s, 1 cmp by dates, to date cmp 1');

}


{  # Scenario 3: B/S, from & to dates, 1 comparison period (by periods)
    my $rpt = LedgerSMB::Report::Balance_Sheet->new(
        _uri => URI->new,
        ignore_yearend => 'all',
        from_date => LedgerSMB::PGDate->from_input( '2016-01-01', format => 'YYYY-MM-DD' ),
        to_date => LedgerSMB::PGDate->from_input( '2016-12-31', format => 'YYYY-MM-DD' ),
        interval => 'year', # just a random valid value
        comparison_periods => '1',
        comparison_type => 'by_periods',
        );
    is($rpt->date_from->to_output, '2016-01-01',
       'b/s, 1 cmp by dates, from date');
    is($rpt->date_to->to_output, '2016-12-31', 'b/s, 1 cmp by dates, to date');
    is(scalar(@{$rpt->comparisons}), 1, 'b/s, 1 cmp by dates, # of comparisons');
    is($rpt->comparisons->[0]->{from_date}->to_output, '2015-01-01',
       'b/s, 1 cmp by dates, from date cmp 1');
    is($rpt->comparisons->[0]->{to_date}->to_output, '2015-12-31',
       'b/s, 1 cmp by dates, to date cmp 1');

}


{  # Scenario 4: B/S, from month & year, 1 comparison period (by periods)
    my $rpt = LedgerSMB::Report::Balance_Sheet->new(
        _uri => URI->new,
        basis => 'accrual',
        ignore_yearend => 'all',
        from_month => '01',
        from_year => '2016',
        interval => 'year', # just a random valid value
        comparison_periods => '1',
        comparison_type => 'by_periods',
        );
    is($rpt->date_from->to_output, '2016-01-01',
       'b/s, 1 cmp by dates, from date');
    is($rpt->date_to->to_output, '2016-12-31', 'b/s, 1 cmp by dates, to date');
    is(scalar(@{$rpt->comparisons}), 1, 'b/s, 1 cmp by dates, # of comparisons');
    is($rpt->comparisons->[0]->{from_date}->to_output, '2015-01-01',
       'b/s, 1 cmp by dates, from date cmp 1');
    is($rpt->comparisons->[0]->{to_date}->to_output, '2015-12-31',
       'b/s, 1 cmp by dates, to date cmp 1');
}

done_testing;
