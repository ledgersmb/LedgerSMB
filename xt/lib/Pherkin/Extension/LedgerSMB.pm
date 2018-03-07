=head1 NAME

Pherkin::Extension::LedgerSMB

=head1 SYNOPSIS

LedgerSMB super-user connection to the PostgreSQL cluster and test
company management routines

=cut

package Pherkin::Extension::LedgerSMB;

use strict;
use warnings;

use LedgerSMB::Database;
use LedgerSMB::PGDate;
use LedgerSMB::Entity::Person::Employee;
use LedgerSMB::Entity::User;
use Test::BDD::Cucumber::Extension;

use Moose;
use namespace::autoclean;
extends 'Test::BDD::Cucumber::Extension';



has db_name => (is => 'rw', default => $ENV{PGDATABASE});
has username => (is => 'rw', default => $ENV{PGUSER});
has password => (is => 'rw', default => $ENV{PGPASSWORD});
has host => (is => 'rw', default => $ENV{PGHOST} // 'localhost');
has template_db_name => (is => 'rw', default => 'standard-template');
has admin_user_name => (is => 'rw', default => 'test-user-admin');
has admin_user_password => (is => 'rw', default => 'password');

has db => (is => 'rw');
has super_dbh => (is => 'rw');
has admin_dbh => (is => 'rw', lazy => 1,
                  builder => '_build_admin_dbh',
                  clearer => '_clear_admin_dbh',
    );
has template_created => (is => 'rw', default => 0);
has last_scenario_stash => (is => 'rw');
has last_feature_stash => (is => 'rw');


sub _build_admin_dbh {
    my ($self) = @_;

    my $db = LedgerSMB::Database->new(
        dbname    => $self->last_scenario_stash->{"the company"},
        username  => $self->admin_user_name,
        password  => $self->admin_user_password,
        host      => $self->host);

    my $dbh = $db->connect({ PrintError => 0,
                             RaiseError => 1,
                             AutoCommit => 1,
                           });

    return $dbh;
}

sub step_directories {
    return [ 'ledgersmb_steps/' ];
}

sub pre_feature {
    my ($self, $feature, $stash) = @_;

    my $db = LedgerSMB::Database->new(
        dbname   => $self->db_name,
        username => $self->username,
        password => $self->password,
        host     => $self->host);

    my $dbh = $db->connect({ PrintError => 0,
                             RaiseError => 1,
                             AutoCommit => 1,
                           });

    $self->db($db);
    $self->super_dbh($dbh);
    $stash->{ext_lsmb} = $self;
    $self->last_feature_stash($stash);
}

sub post_feature {
    my ($self, $feature, $stash) = @_;

    $self->last_feature_stash(undef);
    $self->super_dbh->disconnect
        if $self->super_dbh;
}


sub pre_scenario {
    my ($self, $scenario, $feature_stash, $stash) = @_;

    $self->last_scenario_stash($stash);

    $stash->{ext_lsmb} = $self;
    $stash->{"the admin"} = $self->admin_user_name;
    $stash->{"the admin password"} = $self->admin_user_password;
    $stash->{"the company"} = $self->last_feature_stash->{"the company"}
        if $self->last_feature_stash->{"the company"};
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

    my $emp = LedgerSMB::Entity::Person::Employee->new(
        employeenumber => $employeenumber,
        control_code => $employeenumber,
        dob => LedgerSMB::PGDate->from_input('2006-09-01'),
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
    $user->create($args{password} // 'password');
    $dbh->do(qq(ALTER USER "$username" VALID UNTIL 'infinity'));

    return $user;
}


sub create_template {
    my ($self) = @_;

    my $template = $self->template_db_name;
    my $admin = $self->admin_user_name;
    $self->super_dbh->do(qq(DROP DATABASE IF EXISTS "$template"));
    $self->super_dbh->do(qq(DROP ROLE IF EXISTS "$admin"));

    my $db = LedgerSMB::Database->new(
        dbname   => $self->template_db_name,
        username => $self->username,
        password => $self->password,
        host     => $self->host);

    $db->create_and_load;
    $db->load_coa({ country => 'us',
                    chart => 'General.sql' });

    my $dbh = $db->connect({ PrintError => 0,
                             RaiseError => 1,
                             AutoCommit => 0 });

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
}

sub ensure_nonexisting_company {
    my ($self, $company) = @_;

    $self->super_dbh->do(qq(DROP DATABASE IF EXISTS "$company"));
    $self->_clear_admin_dbh;
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
        $line->{amount} = ($line->{credit} || 0) - ($line->{debit} || 0);
        delete $line->{$_} for (qw/ credit debit /);

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
INSERT INTO acc_trans(trans_id, transdate, chart_id, amount)
     VALUES (?, ?, ?, ?)
|);
    for my $line (@$lines) {
        $line_sth->execute($trans_id, $posting_date,
                           $line->{account_id}, $line->{amount})
            or die "Failed to insert 'acc_trans' table row: " . $line_sth->errstr;
    }
}

__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
