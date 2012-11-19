=head1 NAME

LedgerSMB::Upgrade_Tests - Upgrade tests for LedgerSMB

=head1 SYNPOPSIS

 TODO

=head1 DESCRIPTION

This module has a single function that returns upgrade tests.

=cut

package LedgerSMB::Upgrade_Tests;
use strict;
use warnings;
use Moose;

my @tests;

=head1 FUNCTIONS

=over

=item get_tests()

Returns the test array

=cut

sub get_tests{
    return @tests;
}

=item get_by_name($name)

Returns the test object with the name.

=cut

sub get_by_name {
    my ($self, $name) = $_;
    for my $test (@tests){
       return $test if $test->name eq $name;
    }
}

=back

=head1 TEST DEFINITION

Each test is a Moose object with the following properties (optional ones marked
as such).

=over

=item name

=cut

has name => (is => 'ro', isa => 'Str', required => 1);

=item min_version

The first version to run this against

=cut

has min_version => (is => 'ro', isa => 'Str', required => 1);

=item max_version 

The maximum version to run this against

=cut

has max_version => (is => 'ro', isa => 'Str', required => 1);

=item test_query

Text of the query to run

=cut 

has test_query => (is => 'ro', isa => 'Str', required => 1);

=item table

Repair query table to run once per result.

=cut 

has table => (is => 'ro', isa => 'Str', required => 0);


=item column

Repair query column to run once per result

=cut

has column => (is => 'ro', isa => 'Str', required => 0);

=item display_cols

columns to display on test failures

=cut

has display_cols => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);

=item display_name

Human readable, localized display name

=cut

has display_name => (is => 'ro', isa => 'Str', required => 1);

=back

=cut

# 1.2-1.3 tests

push @tests, __PACKAGE__->new(
        test_query =>
           "select id, customernumber, name, address1, city, state, zipcode
                   from customer where customernumber in 
                    (SELECT customernumberfrom customer
                   GROUP BY customernumber
                   HAVING count(*) > 1)",
 display_name => $LedgerSMB::App_State::Locale->text('Unique Customernumber'),
         name => 'unique_customernumber',
 display_cols => ['customernumber', 'name', 'address1', 'city', 'state', 'zip'],
       column => 'customernumber',
        table => 'customer',
  min_version => '1.2',
  max_version => '1.2'
);

push @tests, __PACKAGE__->new(
        test_query =>
           "select id, vendornumber, name, address1, city, state, zipcode
                   from vendor where vendornumber in 
                    (SELECT vendornumber from vendor
                   GROUP BY vendornumber
                   HAVING count(*) > 1)",
 display_name => $LedgerSMB::App_State::Locale->text('Unique Vendornumber'),
         name => 'unique_vendornumber',
 display_cols => ['vendornumber', 'name', 'address1', 'city', 'state', 'zip'],
       column => 'customernumber',
        table => 'customer',
  min_version => '1.2',
  max_version => '1.2'
);

push @tests, __PACKAGE__->new(
   test_query => "SELECT * FROM employee WHERE employeenumber IS NULL",
 display_name => $LedgerSMB::App_State::Locale->text('No Null employeenumber'),
         name => 'null_employeenumber',
 display_cols => ['login', 'name', 'employeenumber'],
       column => 'employeenumber',
        table => 'employee',
  min_version => '1.2',
  max_version => '1.2'
);

push @tests, __PACKAGE__->new(
   test_query => 'SELECT * FROM employee 
                   WHERE employeenumber IN 
                         (SELECT employeenumber FROM employee 
                        GROUP BY employeenumber
                          HAVING count(*) > 1)',
         name => 'duplicate_employee_numbers',
 display_name => $LedgerSMB::App_State::Locale->text('Duplicate employee numbers'),
 display_cols => ['login', 'name', 'employeenumber'],
       column => 'employeenumber',
        table => 'employee',
  min_version => '1.2',
  max_version => '1.2'
);

push @tests, __PACKAGE__->new(
   test_query => "select * from parts where obsolete is not true 
                  and partnumber in 
                  (select partnumber from parts 
                  WHERE obsolete is not true
                  group by partnumber having count(*) > 1)",
         name => 'duplicate_partnumbers',
 display_name => $LedgerSMB::App_State::Locale->text('Unique nonobsolete partnumbers'),
 display_cols => ['partnumber', 'description', 'sellprice'],
       column => 'partnumber',
        table => 'parts',
  min_version => '1.2',
  max_version => '1.2'
);

push @tests, __PACKAGE__->new(
   test_query => 'SELECT * from ar where invnumber in (
                   select invnumber from ar
                   group by invnumber having count(*) > 1)',
 display_name => $LedgerSMB::App_State::Locale->text('Unique AR Invoice numbers'),
         name => 'unique_ar_invnumbers',
 display_cols =>  ['invnumber', 'transdate', 'amount', 'netamount', 'paid'],
       column =>  'invnumber',
        table =>  'ar',
  min_version => '1.2',
  max_version => '1.2',
);

# New tests in 1.4

push @tests, __PACKAGE__->new(
   test_query => "select * from acc_trans WHERE amount IS NULL",
 display_name => $LedgerSMB::App_State::Locale->text('No NULL Amounts'),
         name => 'no_null_ac_amounts',
 display_cols => ["trans_id", "chart_id", "transdate"],
  min_version => '1.2',
  max_version => '1.4'
);


__PACKAGE__->meta->make_immutable;

1;
