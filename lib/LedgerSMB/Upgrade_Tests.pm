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
use Moose::Util::TypeConstraints;
use namespace::autoclean;
use LedgerSMB::Locale qw(marktext);

=head1 FUNCTIONS

=over

=item get_tests()

Returns the test array

=cut

sub get_tests {
    my ($self) = @_;
    my @tests = $self->_get_tests;
    return @tests;
}

=item get_by_name($name)

Returns the test object with the name.

=cut

sub get_by_name {
    my ($self, $name) = @_;
    my @tests = $self->_get_tests;
    for my $test (@tests){
       return $test if $test->name eq $name;
    }
    return;
}

=back

=head1 TEST DEFINITION

Each test is a Moose object with the following properties (optional ones marked
as such).

=over

=item name

Name of the test

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

=item selectable_values

Hash specifying for each column (identified by the key) which
query to execute to retrieve the values to fill the drop-down with.

Each query needs to return 2 columns: C<text> and C<value>, where
C<value> is the value to be stored in the (fixed) record and
C<text> is the textual value to be presented in the UI.

=cut

has selectable_values => (is => 'ro', isa => 'HashRef', required => 0);

=item force_queries

Array of queries to run on Force. Typically, they will be use to remove missing
or invalid values from tables. For example, removing references to a missing
business discount from the customer and vendor tables. The data is still good
because the discount has been applied but we cannot find the actual values at
the time.

=cut

has force_queries => (is => 'ro', isa => 'ArrayRef', required => 0);

=item insert

Insert data instead of update. This to set defaults on a very limited subset
of tables. Business, for example isn't required in SQL-Ledger but mandatory for
LedgerSMB.

=cut

has insert => (is => 'ro', isa => 'Bool', required => 0, default => 0);

=item id_where

Repair query key to set the values if we can repair

=cut

has id_where => (is => 'ro', isa => 'Str', required => 0, default => 'id');

=item id_column

Repair column to use as id

=cut

has id_column => (is => 'ro', isa => 'Str', required => 0, default => 'id');

=item columns

Repair query columns to run once per result

=cut

has columns => (is => 'ro', isa => 'ArrayRef[Str]', required => 0);

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

=cut

has instructions => (is => 'ro', isa => 'Str', required => 1);

=item buttons

Enabled buttons

=cut

subtype 'button'
    => as 'Str'
    => where { $_ =~ /Save and Retry|Cancel|Force/ }
    => message { "Invalid button '$_'" };

has buttons => (is => 'ro', isa => 'ArrayRef[button]',
                default => sub {['Save and Retry', 'Cancel']},
                required => 0);

=item tooltips

Tooltip for each button

=cut

has tooltips => (is => 'ro',
    isa => 'HashRef[Str]',
    default => sub {
        return {
            'Save and Retry' => marktext('Save the fixes provided and attempt to continue migration'),
            'Cancel' => marktext('Cancel the <b>migration</b>')
    }},
    required => 0);

=back

=head1 Methods

=cut

sub _get_tests {
    my ($request) = @_;

    my @tests;

# 1.2-1.3 tests

push @tests, __PACKAGE__->new(
        test_query =>
           "select id, customernumber, name, address1, city, state, zipcode
                   from customer where customernumber in
                    (SELECT customernumber from customer
                   GROUP BY customernumber
                   HAVING count(*) > 1)",
 display_name => marktext('Unique Customernumber'),
 instructions => marktext(
                   'Please make all customer numbers unique'),
         name => 'unique_customernumber',
 display_cols => ['customernumber', 'name', 'address1', 'city', 'state', 'zip'],
      columns => ['customernumber'],
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
 display_name => marktext('Unique Vendornumber'),
 instructions => marktext(
                   'Please make all vendor numbers unique'),
         name => 'unique_vendornumber',
 display_cols => ['vendornumber', 'name', 'address1', 'city', 'state', 'zip'],
      columns => ['customernumber'],
        table => 'customer',
      appname => 'ledgersmb',
  min_version => '1.2',
  max_version => '1.2'
);

push @tests, __PACKAGE__->new(
   test_query => "SELECT * FROM employee WHERE employeenumber IS NULL",
 display_name => marktext('No Null employeenumber'),
 instructions => marktext(
                   'Enter employee numbers where they are missing'),
         name => 'null_employeenumber',
 display_cols => ['login', 'name', 'employeenumber'],
      columns => ['employeenumber'],
        table => 'employee',
      appname => 'ledgersmb',
  min_version => '1.2',
  max_version => '1.2'
);

push @tests, __PACKAGE__->new(
   test_query => "SELECT * FROM employee
                   WHERE not name ~ '[[:alnum:]_]'::text",
         name => 'minimal_employee_name_requirements',
 display_name => marktext("Employee name doesn't meet minimal requirements (e.g. non-empty, alphanumeric)"),
 instructions => marktext(
     'Make sure every name consists of alphanumeric characters (and underscores) only and is at least one character long'),
 display_cols => ['login', 'name', 'employeenumber'],
      columns => ['name'],
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
 display_name => marktext('Duplicate employee numbers'),
 instructions => marktext(
                   'Make employee numbers unique'),
 display_cols => ['login', 'name', 'employeenumber'],
      columns => ['employeenumber'],
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
                  group by partnumber having count(*) > 1)
                  order by partnumber",
         name => 'duplicate_partnumbers',
 display_name => marktext('Unique nonobsolete partnumbers'),
 instructions => marktext(
                   'Make non-obsolete partnumbers unique'),
 display_cols => ['partnumber', 'description', 'sellprice'],
      columns => ['partnumber'],
        table => 'parts',
      appname => 'ledgersmb',
  min_version => '1.2',
  max_version => '1.2'
);

push @tests, __PACKAGE__->new(
   test_query => 'SELECT * from ar where invnumber in (
                   select invnumber from ar
                   group by invnumber having count(*) > 1)',
 display_name => marktext('Unique AR Invoice numbers'),
 instructions => marktext(
                   'Make invoice numbers unique'),
         name => 'unique_ar_invnumbers',
 display_cols => ['invnumber', 'transdate', 'amount', 'netamount', 'paid'],
      columns => ['invnumber'],
        table =>  'ar',
      appname => 'ledgersmb',
  min_version => '1.2',
  max_version => '1.2',
);

# New tests in 1.4

push @tests, __PACKAGE__->new(
   test_query => "select * from acc_trans WHERE amount IS NULL",
 display_name => marktext('No NULL Amounts'),
         name => 'no_null_ac_amounts',
 display_cols => ["trans_id", "chart_id", "transdate"],
    id_column => 'trans_id',
 instructions => marktext(
                   'There are NULL values in the amounts column of your
source database. Please either find professional help to migrate your
database, or delete the offending rows through PgAdmin III or psql'),
      appname => 'ledgersmb',
  min_version => '1.2',
  max_version => '1.4'
);

push @tests, __PACKAGE__->new(
       test_query => "-- Select transactions without charts where removing them would unbalance tha transaction
                                            WITH ac1 AS (
                                            SELECT DISTINCT trans_id, chart_id, MIN(transdate) as transdate, ROUND(CAST(SUM(amount) AS NUMERIC),2) AS amount
                                                    FROM acc_trans
                                                    WHERE trans_id IN (
                                                            SELECT trans_id FROM (
                                                                    SELECT trans_id, SUM(amount) as amount from acc_trans
                                                                    WHERE chart_id IS NULL
                                                                    GROUP BY trans_id) as a
                                                            WHERE a.amount <> 0)
                                                    AND chart_id IS NULL
                                                    GROUP BY trans_id, chart_id
                                                    ORDER BY trans_id, transdate
                                    ),
                                    -- Hint the user about the type of the remaining entries
                                    ac2 AS (
                                            SELECT DISTINCT ac.trans_id,SUBSTR(c.link,1,2) AS type
                                            FROM acc_trans ac
                                            JOIN chart c ON chart_id = c.id
                                            WHERE trans_id IN ( SELECT trans_id FROM ac1)
                                            AND c.link ~ 'amount'
                                    )
                                    -- Present data
                                    SELECT * from ac1
                                    LEFT JOIN ac2 ON (ac1.trans_id = ac2.trans_id)
                                    ORDER BY ac1.trans_id",
     display_name => $LedgerSMB::App_State::Locale->text('No unassigned amounts in Transactions'),
             name => 'no_unbalanced_ac_transactions',
     display_cols => ["trans_id", "type", "chart_id", "transdate", "amount"],
     instructions => $LedgerSMB::App_State::Locale->text(
                       'The following transactions have unassigned amounts'),
            table => 'acc_trans',
selectable_values => { chart_id => "SELECT concat(accno,' -- ',description) AS text, id as value
                                    FROM chart
                                    WHERE charttype = 'A'
                                    ORDER BY id" },
          columns => ['chart_id'],
        id_column => 'trans_id',
         id_where => 'chart_id IS NULL AND trans_id',
      appname => 'sql-ledger',
  min_version => '2.7',
  max_version => '3.0'
);

push @tests, __PACKAGE__->new(
   test_query => "select *, eca.id as id  from entity_credit_account eca
                     join entity_class ec on eca.entity_class = ec.id
                     join entity e on eca.entity_id = e.id
                   where meta_number in
                       (select meta_number from entity_credit_account
                        group by meta_number having count(*) > 1)
                   order by meta_number",
 display_name => marktext('No duplicate meta_numbers'),
         name => 'no_meta_number_dupes',
 display_cols => [ 'meta_number', 'class', 'description', 'name' ],
      columns => ['meta_number'],
        table => 'entity_credit_account',
 instructions => marktext("Make sure all meta numbers are unique."),
      appname => 'ledgersmb',
  min_version => '1.3',
  max_version => '1.4'
);

push @tests, __PACKAGE__->new(
   test_query => "select distinct gifi_accno from chart
                   where not exists (select 1
                                       from gifi
                                      where gifi.accno = chart.gifi_accno)
                         and gifi_accno is not null
                         and gifi_accno !~ '^\\s*\$'",
 display_name => marktext('GIFI accounts not in "gifi" table'),
         name => 'missing_gifi_table_rows',
 display_cols => [ 'gifi_accno' ],
        table => 'chart',
 instructions => marktext("Please use the 1.2 UI to add the GIFI accounts"),
      appname => 'ledgersmb',
  min_version => '1.2',
  max_version => '1.2'
);

push @tests, __PACKAGE__->new(
   test_query => "select distinct gifi_accno as accno from chart
                   where not exists (select 1
                                       from gifi
                                      where gifi.accno = chart.gifi_accno)
                         and gifi_accno is not null
                         and gifi_accno !~ '^\\s*\$'",
 display_name => marktext('GIFI accounts not in "gifi" table'),
         name => 'missing_gifi_table_rows',
 display_cols => [ 'accno', 'description' ],
        table => 'gifi',
      columns => ['description'],
    id_column => 'accno',
     id_where => 'description IS NULL AND accno',
 instructions => marktext("Please add the missing GIFI accounts"),
      appname => 'sql-ledger',
  min_version => '2.7',
  max_version => '3.0'
);


push @tests, __PACKAGE__->new(
   test_query => "select distinct gifi_accno from account
                   where not exists (select 1
                                       from gifi
                                      where gifi.accno = account.gifi_accno)
                         and gifi_accno is not null
                         and gifi_accno !~ '^\\s*\$'",
 display_name => marktext('GIFI accounts not in "gifi" table'),
         name => 'missing_gifi_table_rows',
 display_cols => [ 'gifi_accno' ],
        table => 'account',
 instructions => marktext("Please use the 1.3/1.4 UI to add the GIFI accounts"),
      appname => 'ledgersmb',
  min_version => '1.3',
  max_version => '1.4'
);



#=pod

#  push @tests, __PACKAGE__->new(
#     test_query => "select * from customer where arap_accno_id is null",
#   display_name => marktext('Empty AR account'),
#           name => 'no_null_ar_accounts',
#   display_cols => [ 'id', 'name', 'contact' ],
#   instructions => marktext("Please correct the empty AR accounts"),
#        appname => 'sql-ledger',
#    min_version => '2.7',
#    max_version => '3.0'
#     );

#  push @tests, __PACKAGE__->new(
#     test_query => "select * from vendor where arap_accno_id is null",
#   display_name => marktext('Empty AP account'),
#           name => 'no_null_ap_accounts',
#   display_cols => [ 'id', 'name', 'contact' ],
#   instructions => marktext("Please correct the empty AP accounts"),
#        appname => 'sql-ledger',
#    min_version => '2.7',
#    max_version => '3.0'
#     );
#*/

#=cut


push @tests,__PACKAGE__->new(
    test_query => "select *
                    from chart
                   where charttype = 'A'
                     and category not in ('A', 'L', 'Q', 'I', 'E')",
    display_name => marktext('Unsupported account categories'),
    name => 'unsupported_account_types',
    display_cols => ['category', 'accno', 'description'],
 instructions => marktext(
                   'Please make sure all accounts have a category of
(A)sset, (L)iability, e(Q)uity, (I)ncome or (E)xpense.'),
   columns => ['category'],
    table => 'chart',
    appname => 'sql-ledger',
    min_version => '2.7',
    max_version => '3.0'
    );

push @tests,__PACKAGE__->new(
    test_query => "select *
                    from chart
                   where charttype = 'A'
                     and link ~ '(^|:)(AR|AP|IC)(:|\$)'
                     and link ~ '(AR|AP|IC)[^:]'",
    display_name => marktext('Unsupported account link combinations'),
    name => 'unsupported_account_links',
    display_cols => ['accno', 'description', 'link'],
 instructions => marktext(
                   'An account can either be a summary account (which have a
link of "AR", "AP" or "IC" value) or be linked to dropdowns (having any
number of "AR_*", "AP_*" and/or "IC_*" links concatenated by colons (:).'),
   columns => ['link'],
    table => 'chart',
    appname => 'sql-ledger',
    min_version => '2.7',
    max_version => '3.0'
    );

push @tests,__PACKAGE__->new(
    test_query => "select *
                    from chart c
                   where charttype = 'A'
                     and 0 = (select count(*)
                            from chart cn
                           where cn.charttype = 'H'
                             and cn.accno < c.accno)",
    display_name => marktext('Accounts without heading'),
    name => 'no_header_accounts',
    display_cols => ['accno', 'description', 'link'],
 instructions => marktext(
                   'Please go into the SQL-Ledger UI and create/rename a
heading which sorts alphanumerically before the first account by accno'),
    table => 'chart',
    appname => 'sql-ledger',
    min_version => '2.7',
    max_version => '3.0'
    );

push @tests,__PACKAGE__->new(
    test_query => "select *
                    from customer
                   where customernumber is null",
    display_name => marktext('Empty customernumbers'),
    name => 'no_empty_customernumbers',
    display_cols => ['id', 'customernumber', 'name'],
 instructions => marktext(
                   'Please make sure there are no empty customer numbers.'),
   columns => ['customernumber'],
    table => 'customer',
    appname => 'sql-ledger',
    min_version => '2.7',
    max_version => '3.0'
    );

    push @tests,__PACKAGE__->new(
        test_query => "select id, 'auto-business-' || id as description, 0 as discount from (
                          select distinct id from (
                                    select business_id as id from customer
                              union select business_id from vendor
                          ) a
                           where id is not null
                             and id <> 0
                             and id not in (select id from business)
                        order by id
                      ) a",
      display_name => marktext('Empty businesses'),
              name => 'no_businesses',
      display_cols => ['id', 'description', 'discount'],
      instructions => marktext(
                       'Undefined businesses.<br>
Please make sure business used by vendors and constomers are defined.<br>
<i><b>Hover on buttons</b> to see their effects and impacts</i>'),
           columns => ['description', 'discount'],
             table => 'business',
           appname => 'sql-ledger',
       min_version => '2.7',
       max_version => '3.0',
            insert => 1,
            # They should be constrained
           buttons => ['Save and Retry', 'Cancel', 'Force'],
     force_queries => ['UPDATE customer SET business_id = NULL
                         WHERE business_id NOT IN (
                            SELECT id FROM business);
                        UPDATE vendor SET business_id = NULL
                         WHERE business_id NOT IN (
                            SELECT id FROM business);'],
          # I want to add to the tooltips already defaulted properly - YL
          tooltips => {
            'Save and Retry' => marktext('Save the fixes provided and attempt to continue migration'),
            'Cancel' => marktext('Cancel the <b>migration</b>'),
            'Force' => marktext('This will <b>remove</b> the business references in <u>vendor</u> and <u>customer</u> tables')
          }
        );


push @tests, __PACKAGE__->new(
    test_query => "SELECT id, name, business_id
                     FROM vendor
                    WHERE business_id NOT IN (SELECT id
                     FROM business)
                      AND business_id <> 0
                 ORDER BY name",
    display_name => marktext('Vendor not in a business'),
    name => 'no_business_for_vendor',
    display_cols => ['id', 'name', 'business_id'],
    columns => ['business_id'],
 instructions => marktext(
                   'LedgerSMB vendors must be assigned to a valid business.<br>
Please review the selection or select the proper business from the list'),
selectable_values => { business_id => "SELECT concat(description,' -- ',discount) AS text, id as value
                                        FROM business
                                        ORDER BY id"},
    table => 'vendor',
    appname => 'sql-ledger',
    min_version => '2.7',
    max_version => '3.0'
    );

push @tests, __PACKAGE__->new(
    test_query => "SELECT id, name, business_id
                     FROM customer
                    WHERE business_id NOT IN (SELECT id
                                              FROM business)
                      AND business_id <> 0
                 ORDER BY name",
    display_name => marktext('Customer not in a business'),
    name => 'no_business_for_customer',
    display_cols => ['id', 'name', 'business_id'],
    columns => ['business_id'],
 instructions => marktext(
                   'LedgerSMB customers must be assigned to a valid business.<br>
Please review the selection or select the proper business from the list'),
selectable_values => { business_id => "SELECT concat(description,' -- ',discount) AS text, id as value
                                        FROM business
                                        ORDER BY id"},
    table => 'customer',
    appname => 'sql-ledger',
    min_version => '2.7',
    max_version => '3.0'
    );

push @tests, __PACKAGE__->new(
    test_query => "SELECT id, name, business_id
                     FROM vendor
                    WHERE business_id NOT IN (SELECT id
                     FROM business)
                      AND business_id <> 0
                 ORDER BY name",
    display_name => marktext('Vendor not in a business'),
    name => 'no_business_for_vendor',
    display_cols => ['id', 'name', 'business_id'],
    columns => ['business_id'],
 instructions => marktext(
                   'LedgerSMB vendors must be assigned to a valid business.<br>
Please review the selection or select the proper business from the list'),
selectable_values => { business_id => "SELECT concat(description,' -- ',discount) AS text, id as value
                                        FROM business
                                        ORDER BY id"},
    table => 'vendor',
    appname => 'sql-ledger',
    min_version => '2.7',
    max_version => '3.0'
    );

push @tests, __PACKAGE__->new(
    test_query => "SELECT id, name, business_id
                     FROM customer
                    WHERE business_id NOT IN (SELECT id
                                              FROM business)
                      AND business_id <> 0
                 ORDER BY name",
    display_name => marktext('Customer not in a business'),
    name => 'no_business_for_customer',
    display_cols => ['id', 'name', 'business_id'],
    columns => ['business_id'],
 instructions => marktext(
                   'LedgerSMB customers must be assigned to a valid business.<br>
Please review the selection or select the proper business from the list'),
selectable_values => { business_id => "SELECT concat(description,' -- ',discount) AS text, id as value
                                        FROM business
                                        ORDER BY id"},
    table => 'customer',
    appname => 'sql-ledger',
    min_version => '2.7',
    max_version => '3.0'
    );

push @tests,__PACKAGE__->new(
    test_query => "select *
                    from chart
                   where charttype = 'A'
                     and category not in ('A', 'L', 'Q', 'I', 'E')",
    display_name => marktext('Unsupported account categories'),
    name => 'unsupported_account_types',
    display_cols => ['category', 'accno', 'description'],
 instructions => marktext(
                   'Please make sure all accounts have a category of
(A)sset, (L)iability, e(Q)uity, (I)ncome or (E)xpense.'),
   columns => ['category'],
    table => 'chart',
    appname => 'sql-ledger',
    min_version => '2.7',
    max_version => '3.0'
    );

# push @tests,__PACKAGE__->new(
#     test_query => "select *
#                     from chart
#                    where charttype = 'A'
#                      and link ~ ':?\\(AR|AP|IC\\)\\(:|$\\)'",
#     display_name => marktext('Unsupported account link combinations'),
#     name => 'unsupported_account_links',
#     display_cols => ['accno', 'description', 'link'],
#  instructions => marktext(
#                    'An account can either be a summary account (which have a
# link of "AR", "AP" or "IC" value) or be linked to dropdowns (having any
# number of "AR_*", "AP_*" and/or "IC_*" links concatenated by colons (:).'),
#    columns => ['category'],
#     table => 'chart',
#     appname => 'sql-ledger',
#     min_version => '2.7',
#     max_version => '3.0'
#     );

push @tests,__PACKAGE__->new(
    test_query => "select *
                    from chart c
                   where charttype = 'A'
                     and 0 = (select count(*)
                            from chart cn
                           where cn.charttype = 'H'
                             and cn.accno < c.accno)",
    display_name => marktext('Accounts without heading'),
    name => 'no_header_accounts',
    display_cols => ['accno', 'description', 'link'],
 instructions => marktext(
                   'Please go into the SQL-Ledger UI and create/rename a
heading which sorts alphanumerically before the first account by accno'),
    table => 'chart',
    appname => 'sql-ledger',
    min_version => '2.7',
    max_version => '3.0'
    );

push @tests,__PACKAGE__->new(
    test_query => "select *
                    from customer
                   where customernumber in (select customernumber
                                              from customer
                                             group by customernumber
                                             having count(*) > 1)
                    order by customernumber",
    display_name => marktext('Double customernumbers'),
    name => 'no_double_customernumbers',
    display_cols => ['id', 'customernumber', 'name'],
 instructions => marktext(
                   'Please make all customer numbers unique'),
   columns => ['customernumber'],
    table => 'customer',
    appname => 'sql-ledger',
    min_version => '2.7',
    max_version => '3.0'
    );

push @tests,__PACKAGE__->new(
    test_query => "select *
                    from vendor
                   where vendornumber is null",
    display_name => marktext('Empty vendornumbers'),
    name => 'no_empty_vendornumbers',
    display_cols => ['id', 'vendornumber', 'name'],
 instructions => marktext(
                   'Please make sure there are no empty vendor numbers.'),
   columns => ['vendornumber'],
    table => 'vendor',
    appname => 'sql-ledger',
    min_version => '2.7',
    max_version => '3.0'
    );

push @tests,__PACKAGE__->new(
    test_query => "select *
                    from vendor
                   where vendornumber in (select vendornumber
                                              from vendor
                                             group by vendornumber
                                             having count(*) > 1)",
    display_name => marktext('Double vendornumbers'),
    name => 'no_double_vendornumbers',
    display_cols => ['id', 'vendornumber', 'name'],
 instructions => marktext(
                   'Please make all vendor numbers unique'),
   columns => ['vendornumber'],
    table => 'vendor',
    appname => 'sql-ledger',
    min_version => '2.7',
    max_version => '3.0'
    );

push @tests, __PACKAGE__->new(
    test_query => "select *
                     from employee
                    where employeenumber is null",
    display_name => marktext('Null employee numbers'),
    name => 'no_null_employeenumbers',
    display_cols => ['id', 'login', 'name', 'employeenumber'],
 instructions => marktext(
                   'Please make sure all employees have an employee number'),
   columns => ['employeenumber'],
    table => 'employee',
    appname => 'sql-ledger',
    min_version => '2.7',
    max_version => '3.0'
    );

push @tests, __PACKAGE__->new(
    test_query => "select *
                     from employee
                    where employeenumber in (select employeenumber
                                               from employee
                                              group by employeenumber
                                              having count(*) > 1)",
    display_name => marktext('Null employee numbers'),
    name => 'no_duplicate_employeenumbers',
    display_cols => ['id', 'login', 'name', 'employeenumber'],
   columns => ['employeenumber'],
 instructions => marktext(
                   'Please make all employee numbers unique'),
    table => 'employee',
    appname => 'sql-ledger',
    min_version => '2.7',
    max_version => '3.0'
    );

push @tests, __PACKAGE__->new(
    test_query => "select *
                     from ar
                    where invnumber in (select invnumber
                                          from ar
                                         group by invnumber
                                         having count(*) > 1)
                   order by invnumber",
    display_name => marktext('Non-unique invoice numbers'),
    name => 'no_duplicate_ar_invoicenumbers',
    display_cols => ['id', 'invnumber', 'transdate', 'duedate', 'datepaid',
                     'ordnumber', 'quonumber', 'approved'],
   columns => ['invnumber'],
 instructions => marktext(
                   'Please make all AR invoice numbers unique'),
    table => 'ar',
    appname => 'sql-ledger',
    min_version => '2.7',
    max_version => '3.0'
    );

# There's no AP uniqueness requirement?
push @tests, __PACKAGE__->new(
    test_query => "SELECT id, concat(invnumber,'-',row_number() over(partition by invnumber order by id)) AS invnumber,
                          dcn, description, transdate, duedate, datepaid, ordnumber, quonumber, approved
                     FROM ap
                    WHERE invnumber IN (SELECT invnumber
                                          FROM ap
                                      GROUP BY invnumber
                                        HAVING count(*) > 1)
                 ORDER BY invnumber",
    display_name => marktext('Non-unique invoice numbers detected'),
    name => 'no_duplicate_ap_invoicenumbers',
    display_cols => ['id', 'invnumber', 'transdate', 'duedate', 'datepaid',
                     'ordnumber', 'quonumber', 'approved'],
   columns => ['invnumber'],
 instructions => marktext(
                   'Contrary to SQL-ledger, LedgerSMB invoices numbers must be unique. Please review suggestions to make all AP invoice numbers unique. Conflicting entries are presented by pairs, with a suffix added to the invoice number'),
    table => 'ap',
    appname => 'sql-ledger',
    min_version => '2.7',
    max_version => '3.0'
    );

push @tests, __PACKAGE__->new(
   test_query => "select * from parts where obsolete is not true
                  and partnumber in
                  (select partnumber from parts
                  WHERE obsolete is not true
                  group by partnumber having count(*) > 1)
                  order by partnumber",
         name => 'duplicate_partnumbers',
 display_name => marktext('Unique nonobsolete partnumbers'),
 instructions => marktext(
                   'Make non-obsolete partnumbers unique'),
 display_cols => ['partnumber', 'description', 'sellprice'],
      columns => ['partnumber'],
        table => 'parts',
      appname => 'sql-ledger',
  min_version => '2.7',
  max_version => '3.0'
);


push @tests, __PACKAGE__->new(
    test_query => "select *
                     from makemodel
                    where model is null",
    display_name => marktext('Null model numbers'),
    name => 'no_null_modelnumbers',
    display_cols => ['parts_id', 'make', 'model'],
 instructions => marktext(
                   'Please make sure all modelsnumbers are non-empty'),
   columns => ['model'],
    table => 'makemodel',
    appname => 'sql-ledger',
    min_version => '2.7',
    max_version => '3.0'
    );


push @tests, __PACKAGE__->new(
    test_query => "select *
                     from makemodel
                    where make is null",
    display_name => marktext('Null make numbers'),
    name => 'no_null_makenumbers',
    display_cols => ['parts_id', 'make', 'model'],
   columns => ['make'],
    instructions => marktext(
                   'Please make sure all make numbers are non-empty'),
    table => 'makemodel',
    appname => 'sql-ledger',
    min_version => '2.7',
    max_version => '3.0'
    );


push @tests, __PACKAGE__->new(
    test_query => "select *
                     from partscustomer
                    where not exists (select 1
                                        from pricegroup
                                       where id = pricegroup_id)
                                        and pricegroup_id <> 0",
    display_name => marktext('Non-existing customer pricegroups in partscustomer'),
    name => 'partscustomer_pricegroups_exist',
    display_cols => ['parts_id', 'credit_id', 'pricegroup_id'],
 instructions => marktext(
                   'Please fix the pricegroup data in your partscustomer table (no UI available)'),
    table => 'partscustomer',
    appname => 'sql-ledger',
    min_version => '2.7',
    max_version => '3.0'
    );

push @tests, __PACKAGE__->new(
    test_query => "select *
                     from chart
                    where not charttype in ('H', 'A')",
    display_name => marktext('Unknown charttype; should be H(eader)/A(ccount)'),
    name => 'unknown_charttype',
    display_cols => ['accno', 'charttype', 'description'],
   columns => ['charttype'],
 instructions => marktext(
                   'Please fix the presented rows to either be "H" or "A"'),
    table => 'chart',
    appname => 'sql-ledger',
    min_version => '2.7',
    max_version => '3.0'
    );


push @tests, __PACKAGE__->new(
    test_query => "select *
                     from chart
                    where charttype = 'A'
                          and category not in ('A','L','E','I','Q')",
    display_name => marktext('Unknown account category (should be A(sset)/L(iability)/E(xpense)/I(ncome)/(e)Q(uity))'),
    name => 'unknown_account_category',
    display_cols => ['accno', 'category', 'description'],
   columns => ['category'],
 instructions => marktext(
                   'Please fix the pricegroup data in your partscustomer table (no UI available)'),
    table => 'chart',
    appname => 'sql-ledger',
    min_version => '2.7',
    max_version => '3.0'
    );


push @tests, __PACKAGE__->new(
    test_query => "select count(*)
                     from chart
                    where charttype = 'H'
                    having count(*) < 1",
    display_name => marktext('Unknown '),
    name => 'no_headers_defined',
    display_cols => ['accno', 'charttype', 'description'],
 instructions => marktext(
                   'Please add at least one header to your CoA which sorts before all other account numbers (in the standard SL UI)'),
    table => 'chart',
    appname => 'sql-ledger',
    min_version => '2.7',
    max_version => '3.0'
    );


push @tests, __PACKAGE__->new(
    test_query => "select *
                     from chart
                    where charttype = 'A'
                          and accno < (select min(accno)
                                        from chart
                                       where charttype = 'H')",
    display_name => marktext(''),
    name => 'insufficient_headings',
    display_cols => ['accno', 'description'],
 instructions => marktext(
                   'Please add a header to the CoA which sorts before the listed accounts (usually "0000" works) (in the standard SL UI)'),
    table => 'chart',
    appname => 'sql-ledger',
    min_version => '2.7',
    max_version => '3.0'
    );


push @tests, __PACKAGE__->new(
    test_query => "select *
                     from tax t
                     join chart c on t.chart_id = c.id
                    where c.id in (select chart_id
                                     from tax
                                 group by chart_id, validto
                                   having count(*) > 1)",
    display_name => marktext(''),
    name => 'tax_rates_unique_end_dates',
    display_cols => ['accno', 'description', 'validto', 'rate'],
 instructions => marktext(
                   'Multiple tax rates with the same end date have been detected for a tax account;'),
    table => 'tax',
    appname => 'sql-ledger',
    min_version => '2.7',
    max_version => '3.0'
    );

push @tests, __PACKAGE__->new(
    test_query => "select concat(ac.trans_id,'-',ac.id) as id,
                          ap.transdate, ap.datepaid,
                          ac.cleared-ac.transdate as delay, ap.amount,v.name,
                          ac.transdate,ac.cleared
                  from ap
                  join acc_trans ac on ap.id=ac.trans_id
                  left join vendor v on v.id=ap.vendor_id
                  where ((ac.cleared-ac.transdate > 150 or ac.cleared-ac.transdate < 0)
                         or ac.cleared < ap.datepaid and ac.id = (select max(id) from acc_trans where ap.id=acc_trans.trans_id))
                    and ac.id > 0
                  order by ac.cleared,id, ac.transdate, ap.datepaid",
  display_name => marktext('Invalid or suspect cleared delays'),
          name => 'invalid_cleared_dates',
  display_cols => ['name', 'id', 'datepaid', 'transdate', 'cleared', 'delay', 'amount'],
 instructions => marktext(
                   'Suspect or invalid cleared delays have been detected. Please review the dates in the original application'),
        table => 'ap',
      appname => 'sql-ledger',
  min_version => '2.7',
  max_version => '3.0'
);


### On the vendor side, SL doesn't use pricegroups
# push @tests, __PACKAGE__->new(
#     test_query => "select *
#                      from partsvendor
#                     where not exists (select 1
#                                         from pricegroup
#                                        where id = pricegroup_id)",
#     display_name => marktext('Non-existing vendor pricegroups in partsvendor'),
#     name => 'partsvendor_pricegroups_exist',
#     display_cols => ['parts_id', 'credit_id', 'pricegroup_id'],
#  instructions => marktext(
#                    'Please fix the pricegroup data in your partsvendor table (no UI available)'),
#     table => 'partsvendor',
#     appname => 'sql-ledger',
#     min_version => '2.7',
#     max_version => '3.0'
#     );

    return @tests;
}

__PACKAGE__->meta->make_immutable;

1;
