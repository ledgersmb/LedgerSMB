=head1 NAME

Pherkin::Extension::LedgerSMB

=head1 SYNOPSIS

LedgerSMB super-user connection to the PostgreSQL cluster and test
company management routines

=cut

package Pherkin::Extension::LedgerSMB;

use strict;
use warnings;

use LedgerSMB::Company;
use LedgerSMB::Company::Configuration;
use LedgerSMB::Database;
use LedgerSMB::PGDate;
use LedgerSMB::Entity::Person::Employee;
use LedgerSMB::Entity::User;

use Beam::Wire;
use List::Util qw(any);
use Log::Log4perl qw(:easy);
use Test::BDD::Cucumber::Extension;

use LedgerSMB::Sysconfig;

my $wire = Beam::Wire->new( config => LedgerSMB::Sysconfig->ini2wire );

use Moose;
use namespace::autoclean;
extends 'Test::BDD::Cucumber::Extension';

has db_name => (is => 'rw', default => $ENV{PGDATABASE});
has username => (is => 'rw', default => $ENV{PGUSER});
has password => (is => 'rw', default => $ENV{PGPASSWORD});
has host => (is => 'rw', default => $ENV{PGHOST} // 'localhost');
has template_db_name => (is => 'rw', default => 'std-template');
has admin_user_name => (is => 'rw', default => 'test-user-admin');
has admin_user_password => (is => 'rw', default => 'password');
has wire => (is => 'ro', default => sub { $wire });

has db => (is => 'rw');
has super_dbh => (is => 'rw',
                  predicate => '_has_super_dbh');
has admin_dbh => (is => 'rw', lazy => 1,
                  builder => '_build_admin_dbh',
                  clearer => '_clear_admin_dbh',
                  predicate => '_has_admin_dbh',
    );
has admin_conn => (is => 'rw', lazy => 1,
                   builder => '_build_admin_conn');

has template_created => (is => 'rw', default => 0);
has last_scenario_stash => (is => 'rw');
has last_feature_stash => (is => 'rw');

has databases_created => (is => 'ro', default => sub { [] });

sub _build_admin_dbh {
    my ($self) = @_;

    my $db = LedgerSMB::Database->new(
        connect_data => {
            dbname    => $self->last_scenario_stash->{"the company"},
            user      => $self->admin_user_name,
            password  => $self->admin_user_password,
            host      => $self->host,
        },
        schema    => 'xyz');

    my $dbh = $db->connect({ PrintError => 0,
                             RaiseError => 1,
                             AutoCommit => 1,
                           });
    $dbh->do(q{set client_min_messages = 'warning'});

    return $dbh;
}

sub _build_admin_conn {
    my $self = shift;

    return LedgerSMB::Company->new( dbh => $self->admin_dbh );
}


sub step_directories {
    return [ 'ledgersmb_steps/' ];
}


my $startup_pid = $$;
my $job_name = '';

sub pre_execute {
    if (not Log::Log4perl->initialized()) {
        Log::Log4perl->easy_init($OFF);
    }
}

sub post_execute {
    my ($self) = @_;

    my $t2_harness_job_name = $ENV{T2_HARNESS_JOB_NAME} // '';
    if ($$ != $startup_pid || $job_name eq $t2_harness_job_name) {
        my $db = LedgerSMB::Database->new(
            connect_data => {
                dbname   => $self->db_name,
                user     => $self->username,
                password => $self->password,
                host     => $self->host,
            },
            schema   => 'xyz');

        my $dbh = $db->connect({ PrintError => 0,
                                 RaiseError => 1,
                                 AutoCommit => 1,
                               });
        $dbh->do(q{set client_min_messages = 'warning'});

        for my $db (@{$self->databases_created}, $self->template_db_name) {
            $dbh->do(q{drop database if exists }
                     . $dbh->quote_identifier($db));
        }
        $dbh->disconnect;
    }
}

sub pre_feature {
    my ($self, $feature, $stash) = @_;

    my $t2_harness_job_name = $ENV{T2_HARNESS_JOB_NAME} // '';
    if ($$ != $startup_pid || $job_name ne $t2_harness_job_name) {
        $job_name = $t2_harness_job_name;
        $self->template_db_name($self->template_db_name . "-$$" . "-" . $job_name);
        $self->admin_user_name($self->admin_user_name . "-$$" . "-" . $job_name);
    }
    my $db = LedgerSMB::Database->new(
        connect_data => {
            dbname   => $self->db_name,
            user     => $self->username,
            password => $self->password,
            host     => $self->host,
        },
        schema   => 'xyz');

    my $dbh = $db->connect({ PrintError => 0,
                             RaiseError => 1,
                             AutoCommit => 1,
                           });
    $dbh->do(q{set client_min_messages = 'warning'});

    $self->db($db);
    $self->super_dbh($dbh);
    $stash->{ext_lsmb} = $self;
    $self->last_feature_stash($stash);
}

sub post_feature {
    my ($self, $feature, $stash) = @_;

    $self->last_feature_stash(undef);
    $self->super_dbh->disconnect
        if $self->_has_super_dbh;
    $self->admin_dbh->disconnect
        if $self->_has_admin_dbh;
}


sub pre_scenario {
    my ($self, $scenario, $feature_stash, $stash) = @_;

    $self->last_scenario_stash($stash);

    $stash->{ext_lsmb} = $self;
    $stash->{"the admin"} = $self->admin_user_name;
    $stash->{"the admin password"} = $self->admin_user_password;

    if ($self->last_feature_stash->{"the company"}
        && any { $_ eq '@one-db' } @{$scenario->tags}) {
        $stash->{"the company"} = $self->last_feature_stash->{"the company"};
    }
}


sub post_scenario {
    my ($self) = @_;

    $self->last_scenario_stash(undef);
}


my $emp_counter = 0;

sub create_employee {
    my $self = shift;
    my %args = @_;

    my $dbh = $args{dbh} // $self->admin_dbh;
    my $employeenumber = 'E-' . ($emp_counter++);

    local $LedgerSMB::App_State::User = {};
    my $emp = LedgerSMB::Entity::Person::Employee->new(
        employeenumber => $employeenumber,
        control_code => $employeenumber,
        dob => LedgerSMB::PGDate->from_input('2006-09-01', dateformat => 'YYYY-MM-DD' ),
        salutation_id => 1,
        first_name => 'First',
        last_name => 'Last'.$emp_counter,
        name => 'First Last',
        ssn => '1' . $emp_counter,
        country_id => 232, # United States
        _dbh => $dbh,
        );
    $emp->save;

    return $emp;
}

my $user_counter = 0;

sub create_user {
    my $self = shift;
    my %args = @_;

    my $dbh = $args{dbh} // $self->admin_dbh;
    my $username = $args{username} //
        $self->db_name . '_user' . ($user_counter++);

    $self->super_dbh->do(qq(DROP ROLE IF EXISTS "$username"));
    my $user = LedgerSMB::Entity::User->new(
        entity_id => $args{entity_id},
        username => $username,
        _dbh => $dbh,
        );
    $user->create($args{password} // 'password', { language => 'en' });
    my $ident_username=$dbh->quote_identifier($username);
    $dbh->do(qq(ALTER USER $ident_username VALID UNTIL 'infinity'));

    return $user;
}


sub create_template {
    my ($self) = @_;

    my $template = $self->template_db_name;
    my $admin = $self->admin_user_name;
    $self->super_dbh->do(qq(DROP DATABASE IF EXISTS "$template"));
    $self->super_dbh->do(qq(DROP ROLE IF EXISTS "$admin"));

    my $db = LedgerSMB::Database->new(
        connect_data => {
            dbname   => $self->template_db_name,
            user     => $self->username,
            password => $self->password,
            host     => $self->host,
        },
        schema   => 'xyz');

    $db->create_and_load;
    my $c = LedgerSMB::Company->new(
        dbh => $db->connect(),
        )->configuration;
     my $fn = './locale/coa/us/General.xml';
    open my $fh, '<:encoding(UTF-8)', $fn
        or die "Failed to open $fn: $!";
    $c->from_xml($fh);
    $c->dbh->commit;
    $c->dbh->disconnect;
    close $fh
        or warn "Error closing $fn: $!";

    # NOTE: $db is connected with the template, *not* with the
    #  test database (which means we can't use $self->super_dbh!)
    my $dbh = $db->connect({ PrintError => 0,
                             RaiseError => 1,
                             AutoCommit => 0 });
    $dbh->do(q{set client_min_messages = 'warning'});

    # Disable the toaster for more immediate page interaction
    $dbh->do(q|insert into defaults values ('__disableToaster', 'yes')|);
    # Set up sequence randomization
    $dbh->do(q|
do
$$
declare
   r record;
begin
  for r in
     select s.oid as seqoid
       from pg_class s
       join pg_namespace sn on s.relnamespace = sn.oid
      where relkind = 'S'
  loop
     perform setval(r.seqoid, nextval(r.seqoid)+(RANDOM()*1000+1)::int);
  end loop;
end;
$$;
             |);

    $dbh->do(q|
UPDATE business_unit_class SET active = true WHERE id = 2; -- project
INSERT INTO business_unit (class_id, control_code, description)
                   VALUES (2, 'P01', 'Project 01');
             |);

    my $emp = $self->create_employee(dbh => $dbh);
    my $user = $self->create_user(dbh => $dbh,
                                  entity_id => $emp->entity_id,
                                  username => $admin);

    my $roles;
    @$roles = map { $_->{rolname} } @{$user->list_roles};
    $user->save_roles($roles);

    $dbh->do("INSERT INTO defaults
                     VALUES ('role_prefix', 'lsmb_${template}__')");
    $dbh->commit if ! $dbh->{AutoCommit};
    $dbh->disconnect;

    $self->template_created(1);
}


sub ensure_template {
    my ($self) = @_;

    $self->create_template
        unless $self->template_created;
}


sub create_from_template {
    my ($self, $company) = @_;

    my $template = $self->template_db_name;
    $self->ensure_nonexisting_company($company);
    $self->super_dbh->do(qq(CREATE DATABASE "$company" TEMPLATE "$template"));

    $self->last_feature_stash->{"the company"} = $company;
    $self->last_scenario_stash->{"the company"} = $company;
    $self->_clear_admin_dbh;

    push @{$self->databases_created}, $company;
}

sub ensure_nonexisting_company {
    my ($self, $company) = @_;

    $self->_clear_admin_dbh;
    $self->super_dbh->do(qq(DROP DATABASE IF EXISTS "$company"));
}

sub ensure_nonexisting_user {
    my ($self, $role) = @_;

    $self->super_dbh->do(qq(DROP ROLE IF EXISTS "$role"));
    ###TODO: if a database $self->last_scenario_stash->{the company}
    ### exists, verify that the user doesn't exist there and delete it
    ### if it does
}

sub assert_closed_posting_date {
    my ($self, $date) = @_;

    sleep 1; # wait for any handling to finish
    my $sth = $self->admin_dbh->prepare(
        qq|
   INSERT INTO gl (transdate, person_id)
        VALUES (?, (SELECT entity_id FROM users WHERE username = ?))
     RETURNING id
|);

    my $rv = eval {
        $sth->execute($date,
                      $self->last_scenario_stash->{"the admin user"});
        1;
    };

    die "Posting on $date incorrectly accepted"
        if $rv;
}

sub post_transaction {
    my ($self, $posting_date, $lines) = @_;

    my $acc_sth = $self->admin_dbh->prepare(
        qq|
SELECT id
  FROM account
 WHERE accno = ?
|);

    for my $line (@$lines) {
        $line->{amount_bc} =
            ($line->{credit_bc} || 0) - ($line->{debit_bc} || 0);
        $line->{amount_tc} =
            ($line->{credit_tc} || 0) - ($line->{debit_tc} || 0)
            if exists $line->{credit_tc} || exists $line->{debit_tc};
        delete $line->{$_} for (qw/ credit_bc credit_tc debit_bc debit_tc /);

        next if $line->{account_id};

        $acc_sth->execute($line->{accno})
            or die "Failed to retrieve account '$line->{accno}': "
                   . $acc_sth->errstr;
        my ($account_id) = $acc_sth->fetchrow_array();
        $line->{account_id} = $account_id;
    }

    my $trans_sth = $self->admin_dbh->prepare(
        qq|
INSERT INTO gl(transdate, person_id)
     VALUES (?, (SELECT entity_id FROM users WHERE username = ?))
  RETURNING id
|);
    $trans_sth->execute($posting_date,
                        $self->last_scenario_stash->{"the admin user"})
        or die "Failed to create 'gl' table row: " . $trans_sth->errstr;
    my ($trans_id) = $trans_sth->fetchrow_array();

    my $line_sth = $self->admin_dbh->prepare(
        qq|
INSERT INTO acc_trans(trans_id, transdate, chart_id, amount_bc, curr, amount_tc)
     VALUES (?, ?, ?, ?, ?, ?)
|);
    for my $line (@$lines) {
        $line_sth->execute($trans_id, $posting_date,
                           $line->{account_id}, $line->{amount_bc},
                           $line->{curr} // 'USD',
                           $line->{amount_tc} // $line->{amount_bc})
            or die "Failed to insert 'acc_trans' table row: " . $line_sth->errstr;
    }
}


my $part_count = 0;

sub create_part {
    my ($self, $props) = @_;

    local $LedgerSMB::App_State::DBH = $self->admin_dbh;
    my $cfg = LedgerSMB::Company::Configuration->new(dbh => $self->admin_dbh);
    my @accounts = $cfg->coa_nodes->get(filter => q{not is_heading});
    my %accno_ids = map { $_->{accno} => $_->{id} } @accounts;

    $props->{partnumber} //= 'P-' . ($part_count++);
    my $dbh = $self->admin_dbh;
    my @keys;
    my @values;
    my @placeholders;

    $props->{$_} = ($accno_ids{$props->{$_}} =~ s/^A-//r)
       for grep { m/accno/ } keys %$props;

    for my $key (keys %$props) {
        push @values, $props->{$key};
        $key =~ s/accno$/accno_id/g;
        push @keys, $key;
        push @placeholders, '?';
    }
    my $keys = join ',', @keys;
    my $placeholders = join ',', @placeholders;

    $dbh->do(qq|
      INSERT INTO parts ($keys)
        VALUES ($placeholders)
|, undef, @values);

    return $props->{partnumber};
}

my $vc_counter = 0;

sub create_vc {
    my ($self, $vc, $vc_name) = @_;
    my $control_code = uc(substr($vc,0,1)) . '-' . ($vc_counter++);
    my $admin_dbh = $self->admin_dbh;
    my $company = LedgerSMB::Entity::Company->new(
        country_id   => 1,
        control_code => $control_code,
        legal_name   => $vc_name,
        name         => $vc_name,
        entity_class => ($vc eq 'vendor' ? 1 : 2),
        _dbh         => $admin_dbh,
        );
    $company = $company->save;

    local $LedgerSMB::App_State::DBH = $admin_dbh;
    my $cfg = LedgerSMB::Company::Configuration->new(dbh => $self->admin_dbh);
    my @accounts = $cfg->coa_nodes->get(filter => q{not is_heading});
    my %accno_ids = map {
        $_->{accno} => ($_->{id} =~ s/^A-//r)
    } @accounts;

    LedgerSMB::Entity::Credit_Account->new(
        entity_id        => $company->entity_id,
        entity_class     => ($vc eq 'vendor' ? 1 : 2),
        _dbh             => $admin_dbh,
        ar_ap_account_id => $accno_ids{($vc eq 'vendor' ? '2100' : '1200')},
        meta_number      => $vc_name,
        curr             => 'USD',
        )->save;

    my $vc_key = ($vc eq 'vendor') ? 'the vendor' : 'the customer';
    return {
        $vc_key       => $vc_name,
#        'the company' => $control_code,
    };
}


__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
