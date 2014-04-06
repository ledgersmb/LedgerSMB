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

=item appname

The appname of the application the test belongs to.
Can currently be 'ledgersmb' or 'sql-leder'.

=cut

has appname => (is => 'ro', isa => 'Str', required => 1);

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

=item instructions

Human readable instructions for test, localized.

=back

=cut

has instructions => (is => 'ro', isa => 'Str', required => 1);


# 1.2-1.3 tests

push @tests, __PACKAGE__->new(
        test_query =>
           "select id, customernumber, name, address1, city, state, zipcode
                   from customer where customernumber in 
                    (SELECT customernumber from customer
                   GROUP BY customernumber
                   HAVING count(*) > 1)",
 display_name => $LedgerSMB::App_State::Locale->text('Unique Customernumber'),
 instructions => $LedgerSMB::App_State::Locale->text(
                   'Please make all customer numbers unique'),
         name => 'unique_customernumber',
 display_cols => ['customernumber', 'name', 'address1', 'city', 'state', 'zip'],
       column => 'customernumber',
        table => 'customer',
      appname => 'ledgersmb',
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
 instructions => $LedgerSMB::App_State::Locale->text(
                   'Please make all vendor numbers unique'),
         name => 'unique_vendornumber',
 display_cols => ['vendornumber', 'name', 'address1', 'city', 'state', 'zip'],
       column => 'customernumber',
        table => 'customer',
      appname => 'ledgersmb',
  min_version => '1.2',
  max_version => '1.2'
);

push @tests, __PACKAGE__->new(
   test_query => "SELECT * FROM employee WHERE employeenumber IS NULL",
 display_name => $LedgerSMB::App_State::Locale->text('No Null employeenumber'),
 instructions => $LedgerSMB::App_State::Locale->text(
                   'Enter employee numbers where they are missing'),
         name => 'null_employeenumber',
 display_cols => ['login', 'name', 'employeenumber'],
       column => 'employeenumber',
        table => 'employee',
      appname => 'ledgersmb',
  min_version => '1.2',
  max_version => '1.2'
);

push @tests, __PACKAGE__->new(
   test_query => "SELECT * FROM employee
                   WHERE not name ~ '[[:alnum:]_]'::text",
         name => 'minimal_employee_name_requirements',
 display_name => $LedgerSMB::App_State::Locale->text("Employee name doesn't meet minimal requirements (e.g. non-empty, alphanumeric)"),
 instructions => $LedgerSMB::App_State::Locale->text(
     'Make sure every name consists of alphanumeric characters (and underscores) only and is at least one character long'),
 display_cols => ['login', 'name', 'employeenumber'],
       column => 'name',
        table => 'employee',
      appname => 'ledgersmb',
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
 instructions => $LedgerSMB::App_State::Locale->text(
                   'Make employee numbers unique'),
 display_cols => ['login', 'name', 'employeenumber'],
       column => 'employeenumber',
        table => 'employee',
      appname => 'ledgersmb',
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
 instructions => $LedgerSMB::App_State::Locale->text(
                   'Make non-obsolete partnumbers unique'),
 display_cols => ['partnumber', 'description', 'sellprice'],
       column => 'partnumber',
        table => 'parts',
      appname => 'ledgersmb',
  min_version => '1.2',
  max_version => '1.2'
);

push @tests, __PACKAGE__->new(
   test_query => 'SELECT * from ar where invnumber in (
                   select invnumber from ar
                   group by invnumber having count(*) > 1)',
 display_name => $LedgerSMB::App_State::Locale->text('Unique AR Invoice numbers'),
 instructions => $LedgerSMB::App_State::Locale->text(
                   'Make invoice numbers unique'),
         name => 'unique_ar_invnumbers',
 display_cols =>  ['invnumber', 'transdate', 'amount', 'netamount', 'paid'],
       column =>  'invnumber',
        table =>  'ar',
      appname => 'ledgersmb',
  min_version => '1.2',
  max_version => '1.2',
);

# New tests in 1.4

push @tests, __PACKAGE__->new(
   test_query => "select * from acc_trans WHERE amount IS NULL",
 display_name => $LedgerSMB::App_State::Locale->text('No NULL Amounts'),
         name => 'no_null_ac_amounts',
 display_cols => ["trans_id", "chart_id", "transdate"],
 instructions => $LedgerSMB::App_State::Locale->text(
                   '?????'),
      appname => 'ledgersmb',
  min_version => '1.2',
  max_version => '1.4'
);

=pod 

 push @tests, __PACKAGE__->new(
    test_query => "select * from customer where arap_accno_id is null",
    display_name => $LedgerSMB::App_State::Locale->text('Empty AR account'),
    name => 'no_null_ar_accounts',
    display_cols => [ 'id', 'name', 'contact' ],
    appname => 'sql-ledger',
    min_version => '2.7',
    max_version => '2.8'
    );

 push @tests, __PACKAGE__->new(
    test_query => "select * from vendor where arap_accno_id is null",
    display_name => $LedgerSMB::App_State::Locale->text('Empty AP account'),
    name => 'no_null_ap_accounts',
    display_cols => [ 'id', 'name', 'contact' ],
    appname => 'sql-ledger',
    min_version => '2.7',
    max_version => '2.8'
    );
*/

=cut

push @tests,__PACKAGE__->new(
    test_query => "select *
                    from customer
                   where customernumber in (select customernumber
                                              from customer
                                             group by customernumber
                                             having count(*) > 1)",
    display_name => $LedgerSMB::App_State::Locale->text('Double customernumbers'), 
    name => 'no_double_customernumbers',
    display_cols => ['id', 'customernumber', 'name'],
 instructions => $LedgerSMB::App_State::Locale->text(
                   'Please make all customer numbers unique'),
    column => 'customernumber',
    table => 'customer',
    appname => 'sql-ledger',
    min_version => '2.7',
    max_version => '2.8'
    );

push @tests,__PACKAGE__->new(
    test_query => "select *
                    from vendor
                   where vendornumber in (select vendornumber
                                              from vendor
                                             group by vendornumber
                                             having count(*) > 1)",
    display_name => $LedgerSMB::App_State::Locale->text('Double vendornumbers'), 
    name => 'no_double_vendornumbers',
    display_cols => ['id', 'vendornumber', 'name'],
 instructions => $LedgerSMB::App_State::Locale->text(
                   'Please make all vendor numbers unique'),
    column => 'vendornumber',
    table => 'vendor',
    appname => 'sql-ledger',
    min_version => '2.7',
    max_version => '2.8'
    );

push @tests, __PACKAGE__->new(
    test_query => "select *
                     from employee
                    where employeenumber is null",
    display_name => $LedgerSMB::App_State::Locale->text('Null employee numbers'),
    name => 'no_null_employeenumbers',
    display_cols => ['id', 'login', 'name', 'employeenumber'],
 instructions => $LedgerSMB::App_State::Locale->text(
                   'Please make sure all employees have an employee number'),
    column => 'employeenumber',
    table => 'employee',
    appname => 'sql-ledger',
    min_version => '2.7',
    max_version => '2.8'
    );

push @tests, __PACKAGE__->new(
    test_query => "select *
                     from employee
                    where employeenumber in (select employeenumber
                                               from employee
                                              group by employeenumber
                                              having count(*) > 1)",
    display_name => $LedgerSMB::App_State::Locale->text('Null employee numbers'),
    name => 'no_duplicate_employeenumbers',
    display_cols => ['id', 'login', 'name', 'employeenumber'],
    column => 'employeenumber',
 instructions => $LedgerSMB::App_State::Locale->text(
                   'Please make all employee numbers unique'),
    table => 'employee',
    appname => 'sql-ledger',
    min_version => '2.7',
    max_version => '2.8'
    );

push @tests, __PACKAGE__->new(
    test_query => "select *
                     from ar
                    where invnumber in (select invnumber
                                          from ar
                                         group by invnumber
                                         having count(*) > 1)
                   order by invnumber",
    display_name => $LedgerSMB::App_State::Locale->text('Non-unique invoice numbers'),
    name => 'no_duplicate_ar_invoicenumbers',
    display_cols => ['id', 'invnumber', 'transdate', 'duedate', 'datepaid',
                     'ordnumber', 'quonumber', 'approved'],
    column => 'invnumber',
 instructions => $LedgerSMB::App_State::Locale->text(
                   'Please make all AR invoice numbers unique'),
    table => 'ar',
    appname => 'sql-ledger',
    min_version => '2.7',
    max_version => '2.8'
    );

#  There's no AP uniqueness requirement? 
# push @tests, __PACKAGE__->new(
#     test_query => "select *
#                      from ap
#                     where invnumber in (select invnumber
#                                                from ap
#                                               group by invnumber
#                                               having count(*) > 1)
#                     order by invnumber",
#     display_name => $LedgerSMB::App_State::Locale->text('Non-unique invoice numbers'),
#     name => 'no_duplicate_ap_invoicenumbers',
#     display_cols => ['id', 'invnumber', 'transdate', 'duedate', 'datepaid',
#                      'ordnumber', 'quonumber', 'approved'],
#     column => 'invnumber',
#  instructions => $LedgerSMB::App_State::Locale->text(
#                    'Please make all AP invoice numbers unique'),
#     table => 'ap',
#     appname => 'sql-ledger',
#     min_version => '2.7',
#     max_version => '2.8'
#     );


push @tests, __PACKAGE__->new(
    test_query => "select *
                     from makemodel
                    where model is null",
    display_name => $LedgerSMB::App_State::Locale->text('Null model numbers'),
    name => 'no_null_modelnumbers',
    display_cols => ['parts_id', 'make', 'model'],
 instructions => $LedgerSMB::App_State::Locale->text(
                   'Please make sure all modelsnumbers are non-empty'),
    column => 'model',
    table => 'makemodel',
    appname => 'sql-ledger',
    min_version => '2.7',
    max_version => '2.8'
    );


push @tests, __PACKAGE__->new(
    test_query => "select *
                     from makemodel
                    where make is null",
    display_name => $LedgerSMB::App_State::Locale->text('Null make numbers'),
    name => 'no_null_makenumbers',
    display_cols => ['parts_id', 'make', 'model'],
    column => 'make',
 instructions => $LedgerSMB::App_State::Locale->text(
                   'Please make sure all make numbers are non-empty'),
    table => 'makemodel',
    appname => 'sql-ledger',
    min_version => '2.7',
    max_version => '2.8'
    );


push @tests, __PACKAGE__->new(
    test_query => "select *
                     from partscustomer
                    where not exists (select 1
                                        from pricegroup
                                       where id = pricegroup_id)",
    display_name => $LedgerSMB::App_State::Locale->text('Non-existing customer pricegroups in partscustomer'),
    name => 'partscustomer_pricegroups_exist',
    display_cols => ['parts_id', 'credit_id', 'pricegroup_id'],
 instructions => $LedgerSMB::App_State::Locale->text(
                   'Please fix the pricegroup data in your partscustomer table (no UI available)'),
    table => 'partscustomer',
    appname => 'sql-ledger',
    min_version => '2.7',
    max_version => '2.8'
    );

#  ### On the vendor side, SL doesn't use pricegroups
# push @tests, __PACKAGE__->new(
#     test_query => "select *
#                      from partsvendor
#                     where not exists (select 1
#                                         from pricegroup
#                                        where id = pricegroup_id)",
#     display_name => $LedgerSMB::App_State::Locale->text('Non-existing vendor pricegroups in partsvendor'),
#     name => 'partsvendor_pricegroups_exist',
#     display_cols => ['parts_id', 'credit_id', 'pricegroup_id'],
#  instructions => $LedgerSMB::App_State::Locale->text(
#                    'Please fix the pricegroup data in your partsvendor table (no UI available)'),
#     table => 'partsvendor',
#     appname => 'sql-ledger',
#     min_version => '2.7',
#     max_version => '2.8'
#     );


__PACKAGE__->meta->make_immutable;

1;
