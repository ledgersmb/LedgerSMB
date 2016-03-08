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
extends 'Test::BDD::Cucumber::Extension';



has db_name => (is => 'rw', default => $ENV{PGDATABASE});
has username => (is => 'rw', default => $ENV{PGUSER});
has password => (is => 'rw', default => $ENV{PGPASSWORD});
has host => (is => 'rw', default => 'localhost');
has template_db_name => (is => 'rw', default => 'standard-template');
has admin_user_name => (is => 'rw', default => 'test-user-admin');
has admin_user_password => (is => 'rw', default => 'password');

has db => (is => 'rw');
has super_dbh => (is => 'rw');
has template_created => (is => 'rw', default => 0);
has last_scenario_stash => (is => 'rw');
has last_feature_stash => (is => 'rw');


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

    my $emp = LedgerSMB::Entity::Person::Employee->new(
        employeenumber => 'E-001',
        control_code => 'E-001',
        dob => LedgerSMB::PGDate->from_input('2006-09-01'),
        username => $admin,
        salutation_id => 1,
        first_name => 'First',
        last_name => 'Last',
        name => 'First Last',
        ssn => '0000010',
        country_id => 232, # United States
        _DBH => $dbh,
        );
    $emp->save;

    my $user = LedgerSMB::Entity::User->new(
        entity_id => $emp->entity_id,
        username => $admin,
        _DBH => $dbh,
        );
    $user->create('password');
    my $roles;
    @$roles = map { $_->{rolname} } @{$user->list_roles};
    $user->save_roles($roles);

    $dbh->do("INSERT INTO defaults
                     VALUES ('role_prefix', 'lsmb_${template}__')");
    $dbh->commit;
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
}

sub ensure_nonexisting_company {
    my ($self, $company) = @_;

    $self->super_dbh->do(qq(DROP DATABASE IF EXISTS "$company"));
}

sub ensure_nonexisting_user {
    my ($self, $role) = @_;

    $self->super_dbh->do(qq(DROP ROLE IF EXISTS "$role"));
    ###TODO: if a database $self->last_scenario_stash->{the company}
    ### exists, verify that the user doesn't exist there and delete it
    ### if it does
}  


1;
