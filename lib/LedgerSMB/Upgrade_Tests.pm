
package LedgerSMB::Upgrade_Tests;

=head1 NAME

LedgerSMB::Upgrade_Tests - Upgrade tests for LedgerSMB

=head1 SYNPOPSIS

 TODO

=head1 DESCRIPTION

This module has a single function that returns upgrade tests.

=cut

use strict;
use warnings;

use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;
use List::Util qw( first );

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
    return first { $_->name eq $name } $self->_get_tests;
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

=item id_columns

Repair columns to use as ids

=cut

has id_columns => (is => 'ro', isa => 'ArrayRef[Str]', required => 0,
                   default => sub { return ['id'] });

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
    default => sub { return ['Save and Retry', 'Cancel']}, required => 0);

=item tooltips

Tooltip for each button.
Validate that buttons are enabled for each tooltip, then prepend defaults
and override with test specific labeling.

=cut

has tooltips => (is => 'ro',
    isa => 'Maybe[HashRef[Str]]', required => 0,
    default => undef,   # Force initializer call
    initializer => sub {
        my ( $self, $value, $writer_sub_ref, $attribute_meta ) = @_;
        $value //= {};
        my %defaults = ('Save and Retry' => marktext('Save the fixes provided and attempt to continue migration'),
                                'Cancel' => marktext('Cancel the <b>whole migration</b>'));
        for my $tooltip (keys %defaults) {
            $value->{$tooltip} //= $defaults{$tooltip}
                if grep( /^$tooltip/, @{$self->{buttons}});
        }
        $writer_sub_ref->($value);
    }
);

=back

=head1 Methods

=over

=item run($dbh, $cb)

Runs the verification query against the C<$dbh>, calling the callback C<$cb>
with these arguments on failure: C<$self>, C<$dbh>, C<$sth>.

Returns a falsish value on failure or trueish on success.

=cut

sub run {
    my ($self, $dbh, $cb) = @_;
    my $sth = $dbh->prepare($self->test_query)
        or die $dbh->errstr;

    $sth->execute()
        or die 'Failed to execute pre-migration check ' . $self->name . ', ' . $sth->errstr;

    if ($sth->rows > 0) {
        $cb->($self, $dbh, $sth);
        return 0;
    }
    return 1;
}

=item fix($dbh, $fix_values)

Applies data fixes. Intended to be used to resolve data-issues reported to
the callback C<$cb> of the C<run> method.

C<$fix_values> is an arrayref holding hashrefs with the keys being the names
of the columns and the values the data to be applied for that column. Columns
listed in C<id_columns> must be part of the data supplied.

=cut

sub fix {
    my ($self, $dbh, $fixes) = @_;
    my $table = $dbh->quote_identifier($self->table);

    my $query;
    my @bind_columns;
    if ($self->insert) {
        my $columns =
            join ', ',
            map { $dbh->quote_identifier($_) } @{$self->columns};
        my $values =
            join ', ', map { '?' } @{$self->columns};
        $query = qq{INSERT INTO $table ($columns) VALUES ($values)};
        @bind_columns = @{$self->columns};
    }
    else {
        my $setters =
            join ', ',
            map { $dbh->quote_identifier($_) . ' = ?' } @{$self->columns};
        $query = qq{UPDATE $table SET $setters WHERE }
        . join(' AND ',
               map { "$_ = ?" }
               map { $dbh->quote_identifier($_) }
               @{$self->id_columns});
        @bind_columns = (@{$self->columns}, @{$self->id_columns});
    }

    my $sth = $dbh->prepare($query)
        or die "Failed to compile query ($query) to apply fixes: " . $dbh->errstr;
    for my $row (@$fixes) {
        my $rv = $sth->execute(map { $row->{$_} } @bind_columns);
        if (not $rv) {
            die "Failed to execute data fix query for $self->{name}: " . $sth->errstr;
        }

        if ($rv != 1) {
            die "Upgrade query affected $rv rows while a single row was expected";
        }
    }
    $sth->finish;
    $dbh->commit;
}

=item force($dbh)

=cut

sub force {
    my ($self, $dbh) = @_;

    for my $force_query ( @{$self->{force_queries}}) {
        $dbh->do($force_query)
            or die q{Failed to run 'force' data cleaning query};
    }
    $dbh->commit;

    return;
}

=item query_selectable_values($dbh)

Returns an arrayref with the keys being the names of the columns and the
values arrays of hashes. Each hash has two keys (C<text> and C<value>);
the C<value>s are the allowable values for the given column in C<$fix_values>
when calling C<fix()>.

=cut

sub query_selectable_values {
    my ($self, $dbh) = @_;

    return {} unless $self->selectable_values;

    my %query_values;
    for my $column (@{$self->columns // []}) {
        my $query = $self->selectable_values->{$column};
        next unless $query;

        my $sth = $dbh->prepare($query)
            or die 'Invalid query for drop-down data in ' . $self->name;

        $sth->execute()
            or die 'Failed to query for drop-down data in ' . $self->name;
        $query_values{$column} = $sth->fetchall_arrayref({});
    }
    return \%query_values;
}

sub _get_tests {
    my ($request) = @_;

    my @tests;

# 1.2-1.3 tests

push @tests, __PACKAGE__->new(
        test_query =>
           q{select count(*) as customer_count
              from customer
             where (select count(*)
                      from chart
                     where 'AR' = ANY(string_to_array(link,':'))) > 0
            having count(*) = 0},
 display_name => marktext('AR account available when customers defined'),
 instructions => marktext(
                   q(When customers are defined, an AR account must be defined,
 however, your setup doesn't. Please go back and define one.)),
         name => 'customers_require_ar',
 display_cols => [],
      columns => [],
        table => 'customer',
      appname => 'ledgersmb',
  min_version => '1.2',
  max_version => '1.2'
);

push @tests, __PACKAGE__->new(
        test_query =>
           q{select count(*) as vendor_count
              from vendor
             where (select count(*)
                      from chart
                     where 'AP' = ANY(string_to_array(link,':'))) > 0
            having count(*) = 0},
 display_name => marktext('AP account available when vendors defined'),
 instructions => marktext(
                   q(When vendors are defined, an AP account must be defined,
 however, your setup doesn't. Please go back and define one.)),
         name => 'vendors_require_ap',
 display_cols => [],
      columns => [],
        table => 'vendor',
      appname => 'ledgersmb',
  min_version => '1.2',
  max_version => '1.2'
);


push @tests, __PACKAGE__->new(
        test_query =>
           'select id, customernumber, name, address1, city, state, zipcode
                   from customer where customernumber in
                    (SELECT customernumber from customer
                   GROUP BY customernumber
                   HAVING count(*) > 1)',
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
           'select id, vendornumber, name, address1, city, state, zipcode
                   from vendor where vendornumber in
                    (SELECT vendornumber from vendor
                   GROUP BY vendornumber
                   HAVING count(*) > 1)',
 display_name => marktext('Unique Vendornumber'),
 instructions => marktext(
                   'Please make all vendor numbers unique'),
         name => 'unique_vendornumber',
 display_cols => ['vendornumber', 'name', 'address1', 'city', 'state', 'zip'],
      columns => ['vendornumber'],
        table => 'customer',
      appname => 'ledgersmb',
  min_version => '1.2',
  max_version => '1.2'
);

push @tests, __PACKAGE__->new(
   test_query => 'SELECT * FROM employee WHERE employeenumber IS NULL',
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
   test_query => q{SELECT login, name, employeenumber FROM employee
                   WHERE not name ~ '[[:alnum:]_]'::text},
         name => 'minimal_employee_name_requirements',
 display_name => marktext('Employee name doesn\'t meet minimal requirements (e.g. non-empty, alphanumeric)'),
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
   test_query => 'SELECT login, name, employeenumber FROM employee
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
   test_query => 'select partnumber, description, sellprice
                  from parts where obsolete is not true
                  and partnumber in
                  (select partnumber from parts
                  WHERE obsolete is not true
                  group by partnumber having count(*) > 1)
                  order by partnumber',
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
   test_query => 'SELECT invnumber, transdate, amount, netamount, paid
                   from ar where invnumber in (
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
   test_query => 'select trans_id, chart_id, transdate
                  from acc_trans WHERE amount IS NULL',
 display_name => marktext('No NULL Amounts'),
         name => 'no_null_ac_amounts',
 display_cols => ['trans_id', 'chart_id', 'transdate'],
   id_columns => ['trans_id'],
 instructions => marktext(
                   'There are NULL values in the amounts column of your
source database. Please either find professional help to migrate your
database, or delete the offending rows through PgAdmin III or psql'),
      appname => 'ledgersmb',
  min_version => '1.2',
  max_version => '1.3'
);

push @tests, __PACKAGE__->new(
   test_query => 'select meta_number, class, description, name, eca.id as id
                     from entity_credit_account eca
                     join entity_class ec on eca.entity_class = ec.id
                     join entity e on eca.entity_id = e.id
                   where exists
                       (select meta_number from entity_credit_account eca2
                         where eca.meta_number = eca2.meta_number
                               and eca.entity_class = eca2.entity_class
                        group by meta_number having count(*) > 1)
                   order by meta_number',
 display_name => marktext('No duplicate meta_numbers'),
         name => 'no_meta_number_dupes',
 display_cols => [ 'meta_number', 'class', 'description', 'name' ],
      columns => ['meta_number'],
        table => 'entity_credit_account',
 instructions => marktext('Make sure all meta numbers are unique.'),
      appname => 'ledgersmb',
  min_version => '1.3',
  max_version => '1.3'
);

push @tests, __PACKAGE__->new(
   test_query => q{select distinct gifi_accno from chart
                   where not exists (select 1
                                       from gifi
                                      where gifi.accno = chart.gifi_accno)
                         and gifi_accno is not null
                         and gifi_accno !~ '^\s*$'},
 display_name => marktext('GIFI accounts not in "gifi" table'),
         name => 'missing_gifi_table_rows',
 display_cols => [ 'gifi_accno' ],
        table => 'chart',
 instructions => marktext('Please use the 1.2 UI to add the GIFI accounts'),
      appname => 'ledgersmb',
  min_version => '1.2',
  max_version => '1.2'
    );

push @tests, __PACKAGE__->new(
        test_query =>
           q{select count(*) as customer_count
              from customer
             where (select count(*)
                      from chart
                     where 'AR' = ANY(string_to_array(link,':'))) > 0
            having count(*) = 0},
 display_name => marktext('AR account available when customers defined'),
 instructions => marktext(
                   q(When customers are defined, an AR account must be defined,
 however, your setup doesn't. Please go back and define one.)),
         name => 'customers_require_ar',
 display_cols => [],
      columns => [],
        table => 'customer',
      appname => 'sql-ledger',
  min_version => '2.7',
  max_version => '3.0'
);

push @tests, __PACKAGE__->new(
        test_query =>
           q{select count(*) as vendor_count
              from vendor
             where (select count(*)
                      from chart
                     where 'AP' = ANY(string_to_array(link,':'))) > 0
            having count(*) = 0},
 display_name => marktext('AP account available when vendors defined'),
 instructions => marktext(
                   q(When vendors are defined, an AP account must be defined,
 however, your setup doesn't. Please go back and define one.)),
         name => 'vendors_require_ap',
 display_cols => [],
      columns => [],
        table => 'vendor',
      appname => 'ledgersmb',
  min_version => '2.7',
  max_version => '3.0'
);



push @tests, __PACKAGE__->new(
   test_query => q{select distinct gifi_accno as accno from chart
                   where not exists (select 1
                                       from gifi
                                      where gifi.accno = chart.gifi_accno)
                         and gifi_accno is not null
                         and charttype <> 'H'
                         and gifi_accno !~ '^\s*$'},
 display_name => marktext('GIFI accounts not in "gifi" table'),
         name => 'missing_gifi_table_rows',
 display_cols => [ 'accno', 'description' ],
        table => 'gifi',
       insert => 1,
      columns => ['description'],
   id_columns => ['accno'],
 instructions => marktext('Please add the missing GIFI accounts'),
      appname => 'sql-ledger',
  min_version => '2.7',
  max_version => '3.0'
);

push @tests, __PACKAGE__->new(
   test_query => q{select distinct gifi_accno from account
                   where not exists (select 1
                                       from gifi
                                      where gifi.accno = account.gifi_accno)
                         and gifi_accno is not null
                         and gifi_accno !~ '^\s*$'},
 display_name => marktext('GIFI accounts not in "gifi" table'),
         name => 'missing_gifi_table_rows',
 display_cols => [ 'gifi_accno' ],
        table => 'account',
 instructions => marktext('Please use the 1.3 UI to add the GIFI accounts'),
      appname => 'ledgersmb',
  min_version => '1.3',
  max_version => '1.3'
);

push @tests, __PACKAGE__->new(
   test_query => q{select chart_id, account
                     from cr_coa_to_account ccta
                    where chart_id in (select crcoa.chart_id
                                        from cr_coa_to_account crcoa
                                       where ccta.chart_id = crcoa.chart_id
                                    group by crcoa.chart_id
                                      having count(crcoa.chart_id) > 1)},
 display_name => marktext('Accounts marked for recon -- once'),
         name => 'non_duplicate_recon_accounts_marker',
 display_cols => [ 'chart_id', 'account' ],
        table => 'cr_coa_to_account',
 instructions => marktext('Please use pgAdmin3 or psql to remove the duplicates'),
      appname => 'ledgersmb',
  min_version => '1.3',
  max_version => '1.3'
);

push @tests, __PACKAGE__->new(
   test_query => q{select chart_id, account
                     from cr_coa_to_account ccta
                    where not exists (select 1
                                       from account
                                      where account.id = ccta.chart_id)},
 display_name => marktext('Accounts marked for recon exist'),
         name => 'recon_accounts_exist',
 display_cols => [ 'chart_id', 'account' ],
        table => 'cr_coa_to_account',
 instructions => marktext(q(Please use pgAdmin3 or psql to look up the 'chart_id' value in the 'account' table and change it to an existing value)),
      appname => 'ledgersmb',
  min_version => '1.3',
  max_version => '1.3'
);

push @tests, __PACKAGE__->new(
   test_query => q{select name, contact from customer
                   where arap_accno_id is null
                   order by name},
 display_name => marktext('Empty AR account'),
         name => 'no_null_ar_accounts',
 display_cols => [ 'name', 'contact' ],
 instructions => marktext(q(Please go into the SQL-Ledger UI and correct the empty AR accounts)),
      appname => 'sql-ledger',
  min_version => '2.7',
  max_version => '3.0'
   );

push @tests, __PACKAGE__->new(
   test_query => q{select name, contact from vendor
                   where arap_accno_id is null
                   order by name},
 display_name => marktext('Empty AP account'),
         name => 'no_null_ap_accounts',
 display_cols => [ 'name', 'contact' ],
 instructions => marktext(q(Please go into the SQL-Ledger UI and correct the empty AP accounts)),
      appname => 'sql-ledger',
  min_version => '2.7',
  max_version => '3.0'
   );

push @tests,__PACKAGE__->new(
    test_query => q{ select category, accno, description
                    from chart
                   where charttype = 'A'
                     and category not in ('A', 'L', 'Q', 'I', 'E')},
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
    test_query => q{select accno, description, link
                    from chart
                   where charttype = 'A'
                     and link ~ '(^|:)(AR|AP|IC)(:|\$)'
                     and link ~ '(AR|AP|IC)[^:]'},
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
    test_query => q{select accno, description, link
                    from chart c
                   where charttype = 'A'
                     and 0 = (select count(*)
                            from chart cn
                           where cn.charttype = 'H'
                             and cn.accno < c.accno)},
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
    test_query => 'select id, customernumber, name
                    from customer
                   where customernumber is null',
    display_name => marktext('Empty customernumbers'),
    name => 'no_empty_customernumbers',
    display_cols => ['customernumber', 'name'],
 instructions => marktext(
                   'Please make sure there are no empty customer numbers.'),
   columns => ['customernumber'],
    table => 'customer',
    appname => 'sql-ledger',
    min_version => '2.7',
    max_version => '3.0'
    );

    push @tests,__PACKAGE__->new(
        test_query => q{select id, 'auto-business-' || id as description, 0 as discount from (
                          select distinct id from (
                                    select business_id as id from customer
                              union select business_id from vendor
                          ) a
                           where id is not null
                             and id <> 0
                             and id not in (select id from business)
                        order by id
                      ) a},
      display_name => marktext('Empty businesses'),
              name => 'no_businesses',
      display_cols => ['description', 'discount'],
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
          tooltips => {
            'Force' => marktext('This will <b>remove</b> the business references in <u>vendor</u> and <u>customer</u> tables')
          }
        );


push @tests, __PACKAGE__->new(
    test_query => 'SELECT id, name, business_id
                     FROM vendor
                    WHERE business_id NOT IN (SELECT id
                     FROM business)
                      AND business_id <> 0
                 ORDER BY name',
    display_name => marktext('Vendor not in a business'),
    name => 'no_business_for_vendor',
    display_cols => ['name', 'business_id'],
    columns => ['business_id'],
 instructions => marktext(
                   'LedgerSMB vendors must be assigned to a valid business.<br>
Please review the selection or select the proper business from the list'),
selectable_values => { business_id => q{SELECT concat(description,' -- ',discount) AS text, id as value
                                        FROM business
                                        ORDER BY id}},
    table => 'vendor',
    appname => 'sql-ledger',
    min_version => '2.7',
    max_version => '3.0'
    );

push @tests, __PACKAGE__->new(
    test_query => 'SELECT id, name, business_id
                     FROM customer
                    WHERE business_id NOT IN (SELECT id
                                              FROM business)
                      AND business_id <> 0
                 ORDER BY name',
    display_name => marktext('Customer not in a business'),
    name => 'no_business_for_customer',
    display_cols => ['name', 'business_id'],
    columns => ['business_id'],
 instructions => marktext(
                   'LedgerSMB customers must be assigned to a valid business.<br>
Please review the selection or select the proper business from the list'),
selectable_values => { business_id => q{SELECT concat(description,' -- ',discount) AS text, id as value
                                        FROM business
                                        ORDER BY id}},
    table => 'customer',
    appname => 'sql-ledger',
    min_version => '2.7',
    max_version => '3.0'
    );

push @tests,__PACKAGE__->new(
    test_query => 'select id, customernumber, name
                    from customer
                   where customernumber in (select customernumber
                                              from customer
                                             group by customernumber
                                             having count(*) > 1)
                    order by customernumber',
    display_name => marktext('Double customernumbers'),
    name => 'no_double_customernumbers',
    display_cols => ['customernumber', 'name'],
 instructions => marktext(
                   'Please make all customer numbers unique'),
   columns => ['customernumber'],
    table => 'customer',
    appname => 'sql-ledger',
    min_version => '2.7',
    max_version => '3.0'
    );

push @tests,__PACKAGE__->new(
    test_query => 'select id, vendornumber, name
                    from vendor
                   where vendornumber is null',
    display_name => marktext('Empty vendornumbers'),
    name => 'no_empty_vendornumbers',
    display_cols => ['vendornumber', 'name'],
 instructions => marktext(
                   'Please make sure there are no empty vendor numbers.'),
   columns => ['vendornumber'],
    table => 'vendor',
    appname => 'sql-ledger',
    min_version => '2.7',
    max_version => '3.0'
    );

push @tests,__PACKAGE__->new(
    test_query => 'select id, vendornumber, name
                    from vendor
                   where vendornumber in (select vendornumber
                                              from vendor
                                             group by vendornumber
                                             having count(*) > 1)',
    display_name => marktext('Double vendornumbers'),
    name => 'no_double_vendornumbers',
    display_cols => ['vendornumber', 'name'],
 instructions => marktext(
                   'Please make all vendor numbers unique'),
   columns => ['vendornumber'],
    table => 'vendor',
    appname => 'sql-ledger',
    min_version => '2.7',
    max_version => '3.0'
    );

push @tests, __PACKAGE__->new(
    test_query => 'select id, login, name, employeenumber
                     from employee
                    where employeenumber is null',
    display_name => marktext('Null employee numbers'),
    name => 'no_null_employeenumbers',
    display_cols => ['login', 'name', 'employeenumber'],
 instructions => marktext(
                   'Please make sure all employees have an employee number'),
   columns => ['employeenumber'],
    table => 'employee',
    appname => 'sql-ledger',
    min_version => '2.7',
    max_version => '3.0'
    );

push @tests, __PACKAGE__->new(
    test_query => 'select id, login, name, employeenumber
                     from employee
                    where employeenumber in (select employeenumber
                                               from employee
                                              group by employeenumber
                                              having count(*) > 1)',
    display_name => marktext('Null employee numbers'),
    name => 'no_duplicate_employeenumbers',
    display_cols => ['login', 'name', 'employeenumber'],
   columns => ['employeenumber'],
 instructions => marktext(
                   'Please make all employee numbers unique'),
    table => 'employee',
    appname => 'sql-ledger',
    min_version => '2.7',
    max_version => '3.0'
    );

push @tests, __PACKAGE__->new(
    test_query => 'select id, invnumber, transdate, duedate, datepaid,
                     ordnumber, quonumber, approved
                     from ar
                    where invnumber in (select invnumber
                                          from ar
                                         group by invnumber
                                         having count(*) > 1)
                   order by invnumber',
    display_name => marktext('Non-unique invoice numbers'),
    name => 'no_duplicate_ar_invoicenumbers',
    display_cols => ['invnumber', 'transdate', 'duedate', 'datepaid',
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
    test_query => q{SELECT id, concat(invnumber,'-',row_number() over(partition by invnumber order by id)) AS invnumber,
                          dcn, description, transdate, duedate, datepaid, ordnumber, quonumber, approved
                     FROM ap
                    WHERE invnumber IN (SELECT invnumber
                                          FROM ap
                                      GROUP BY invnumber
                                        HAVING count(*) > 1)
                 ORDER BY invnumber},
    display_name => marktext('Non-unique invoice numbers detected'),
    name => 'no_duplicate_ap_invoicenumbers',
    display_cols => ['invnumber', 'transdate', 'duedate', 'datepaid',
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
   test_query => 'select partnumber, description, sellprice
                  from parts where obsolete is not true
                  and partnumber in
                  (select partnumber from parts
                  WHERE obsolete is not true
                  group by partnumber having count(*) > 1)
                  order by partnumber',
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
    test_query => 'select parts_id, make, model
                     from makemodel
                    where model is null',
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
    test_query => 'select parts_id, make, model
                     from makemodel
                    where make is null',
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
    test_query => 'select parts_id, customer_id, pricegroup_id
                     from partscustomer
                    where not exists (select 1
                                        from pricegroup
                                       where id = pricegroup_id)
                      and pricegroup_id <> 0',
    display_name => marktext('Non-existing customer pricegroups in partscustomer'),
    name => 'partscustomer_pricegroups_exist',
    display_cols => ['parts_id', 'customer_id', 'pricegroup_id'],
 instructions => marktext(
                   'Please fix the pricegroup data in your partscustomer table (no UI available)'),
    table => 'partscustomer',
    appname => 'sql-ledger',
    min_version => '2.7',
    max_version => '3.0'
    );

push @tests, __PACKAGE__->new(
    test_query => q{select accno, charttype, description
                     from chart
                    where not charttype in ('H', 'A')},
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
    test_query => q{select accno, category, description
                     from chart
                    where charttype = 'A'
                          and category not in ('A','L','E','I','Q')},
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
    test_query => q{select count(*)
                     from chart
                    where charttype = 'H'
                    having count(*) < 1},
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
    test_query => q{select accno, description
                     from chart
                    where charttype = 'A'
                          and accno < (select min(accno)
                                        from chart
                                       where charttype = 'H')},
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
    test_query => 'select accno, description, validto, rate
                     from tax t
                     join chart c on t.chart_id = c.id
                    where c.id in (select chart_id
                                     from tax
                                 group by chart_id, validto
                                   having count(*) > 1)',
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
    test_query => q(SELECT ac.trans_id, ac.id, ac.chart_id, ac.memo, ac.amount, xx.description,
                          ch.description as account, ch.accno, ch.link, ch.charttype, ch.category, ac.cleared, approved
                     FROM acc_trans ac
                     JOIN (
                               SELECT g.id, g.description FROM gl g
                         UNION SELECT a.id, n.name        FROM ar a JOIN customer n ON n.id = a.customer_id
                         UNION SELECT a.id, n.name        FROM ap a JOIN vendor n   ON n.id = a.vendor_id
                     ) xx ON xx.id = ac.trans_id
                     JOIN chart ch ON (ac.chart_id = ch.id)
                    WHERE ( ch.category NOT IN ( 'A', 'L', 'Q' )
                         OR ch.link NOT LIKE '%paid' )
                      AND ac.cleared IS NOT NULL
                      AND ac.approved
                 ORDER BY trans_id, ac.id, accno, transdate),
  display_name => marktext('Unneeded Reconciliations'),
          name => 'reconciliation_on_unrelated_accounts',
  display_cols => ['trans_id', 'memo', 'amount', 'description',
                   'accno', 'account', 'link', 'category', 'cleared', 'approved'],
       columns => ['cleared'],
    id_columns => ['trans_id', 'id'],
  instructions => marktext(
                   'Pre-migration checks found reconciliations on income or expense accounts or accounts that have not been marked for receipts/payment. Reconciliations should be on asset, liability or equity accounts only.<br>
Void the clearing date in the dialog shown or go back to SQL-Ledger if you feel that you need to adjust more before migrating.'),
           buttons => ['Save and Retry', 'Cancel', 'Force'],
          tooltips => {
               'Force' => marktext('This will <b>keep</b> the transactions but will <b>ignore</b> the non-necessary reconciliations'),
          },
     force_queries => [q(UPDATE acc_trans ac SET cleared = NULL
                         WHERE chart_id in ( SELECT id
                                               FROM chart c
                                              WHERE c.category NOT IN ( 'A', 'L' )
                                                 OR c.link NOT LIKE '%paid' )
                           AND ac.cleared IS NOT NULL
                           AND ac.approved;)],
             table => 'acc_trans',
           appname => 'sql-ledger',
       min_version => '2.7',
       max_version => '3.0'
);

    return @tests;
}

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012-2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


__PACKAGE__->meta->make_immutable;


1;
