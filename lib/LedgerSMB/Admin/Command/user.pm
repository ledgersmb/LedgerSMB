package LedgerSMB::Admin::Command::user;

=head1 NAME

LedgerSMB::Admin::Command::user - ledgersmb-admin 'user' command

=cut

use strict;
use warnings;

use Getopt::Long qw(GetOptionsFromArray);
use LedgerSMB::Admin::Command;
use LedgerSMB::App_State;
use LedgerSMB::Company;
use LedgerSMB::Database;
use LedgerSMB::Entity::Person::Employee;
use LedgerSMB::Entity::User;
use LedgerSMB::PGDate;
use LedgerSMB::User;

use Moose;
extends 'LedgerSMB::Admin::Command';
use namespace::autoclean;

use Feature::Compat::Try;


has options => (is => 'ro', default => sub { {} });

sub _get_valid_salutation {
    my ($self, $dbh) = @_;
    my $sth = $dbh->prepare('SELECT * FROM salutation');
    $sth->execute
        or die $dbh->errstr;
    my ($values) = $sth->fetchall_arrayref({});
    foreach (@$values) {
        return $_->{id}
            if ( $_->{salutation} eq $self->options->{salutation})
    }
    $self->logger->error('Invalid salutation');
    return 0;
}

sub _get_user {
    my ($self, $dbh) = @_;
    my $_username = shift // $self->options->{username};

    #This ugly hack does
    my $sth =
        $dbh->prepare(q(SELECT id, entity_id FROM users WHERE username=?));
    $sth->execute($self->options->{username})
        or die $dbh->errstr;
    my ($user) = $sth->fetchrow_hashref;
    return $user;
}

sub _get_valid_country {
    my ($self, $dbh) = @_;
    return 0 if !$self->options->{country};
    my $sth = $dbh->prepare('SELECT * FROM country');
    $sth->execute
        or die $dbh->errstr;
    my ($values) = $sth->fetchall_arrayref({});
    foreach (@$values) {
        return $_->{id}
            if ( $_->{name} eq $self->options->{country})
    }
    $self->logger->error('Invalid country');
    return 0;
}

sub _option_spec {
    my ($self, $command) = @_;
    my %option_spec = ();

    if ( $command eq 'change'
      || $command eq 'create' ) {
        %option_spec = (
            # user
            'username=s' => \$self->options->{username},
            'password=s' => \$self->options->{password},
            'permission=s@' => \$self->options->{permission},
            # employee
            'dob=s' => \$self->options->{dob},
            'employeenumber=s' => \$self->options->{employeenumber},
            'end_date=s' => \$self->options->{end_date},
            'is_manager!' => \$self->options->{is_manager},
            'manager=s' => \$self->options->{manager},
            'role=s' => \$self->options->{role},
            'sales!' => \$self->options->{is_sales},
            'ssn=s' => \$self->options->{ssn},
            'start_date=s' => \$self->options->{start_date},
            # person
            #'birthdate=s' => \$birthdate, # Not used?
            'country=s' => \$self->options->{country},
            'first_name=s' => \$self->options->{first_name},
            'last_name=s' => \$self->options->{last_name},
            'middle_name=s' => \$self->options->{middle_name},
            #'personal_id=s' => \$personal_id,
            'salutation=s' => \$self->options->{salutation}
        );
        $option_spec{'no-permission=s@'} = \$self->options->{no_permission}
            if $command eq 'change';

    }
    elsif ( $command eq 'delete' ) {
        %option_spec = (
            'username=s' => \$self->options->{username}
        );
    }
    elsif ( $command eq 'list' ) {
        %option_spec = (
            'username:s' => \$self->options->{username}
        );
    }
    return %option_spec;
}

sub _add_permissions{
    my ($self, $dbh, $user) = @_;

    my $roles;
    @$roles = @{$user->{role_list}};
    if ($self->options->{permission}->[0] =~ /Full Permissions/i) {
        @$roles = map { $_->{rolname} } @{$user->list_roles};
    } else {
        foreach my $p ($self->options->{permission}->@*) {
            my ($h) = grep { lc($p) eq $_->{description} } @{$user->list_roles};
            if (!$h ) {
                $self->logger->error("Invalid role '$p'");
                $dbh->rollback;
                return 0;
            }
            push @$roles, $h->{rolname};
        }
    }
    $user->save_roles($roles);
    return 1;
}

sub _remove_permissions{
    my ($self, $dbh, $user) = @_;

        my $roles;
        @$roles = @{$user->{role_list}};
        if ($self->options->{no_permission}->[0] =~ /Full Permissions/i) {
            $roles = [];
        } else {
            foreach my $p ($self->options->{no_permission}) {
                my ($h) = grep { lc($p) eq $_->{description} } @{$user->list_roles};
                if (!$h ) {
                    $self->logger->error("Invalid role '$p'");
                    $dbh->rollback;
                    return 0;
                }
                @$roles = grep { $h->{rolname} ne $_ } @$roles;
                warn np $roles;
            }
        }
        $user->save_roles($roles);
    return 1;
}

sub change {
    my ($self, $dbh, $options, @args) = @_;

    my %options = ();
    Getopt::Long::Configure(qw(bundling require_order));
    GetOptionsFromArray(\@args, \%options, $self->_option_spec('change'));
    return 1 if !$self->options->{username};

    my $_user = $self->_get_user($dbh);
    if (!$_user) {
        my $username = $self->options->{username};
        $self->logger->error("User '$username' does not exists");
        $dbh->rollback;
        return 1;
    }

    local $LedgerSMB::App_State::User = {};
    local $LedgerSMB::App_State::DBH = $dbh;
    my $user = LedgerSMB::Entity::User->get($_user->{entity_id});
    my $emp = LedgerSMB::Entity::Person::Employee->get($_user->{entity_id});

    if ( $self->options->{password} ) {
        $user->reset_password($self->options->{password});
    }
    my $needs_save = 0;
    for my $setting (qw(country dob employeenumber end_date first_name
                        is_manager last_name manager middle_name role sales
                        salutation ssn start_date)) {
        if ($self->options->{$setting}) {
            $emp->{$setting} = $self->options->{$setting};
            $needs_save = 1;
        }
    }

    $emp->save if $needs_save;
    # Add permissions
    return 1 if ($self->options->{permission}
                 and not $self->_add_permissions($dbh, $user));
    # Remove permissions
    return 1 if ($self->options->{no_permission}
                 and not $self->_remove_permissions($dbh, $user));

    $dbh->commit if not $dbh->{AutoCommit};
    $dbh->disconnect;
    $self->logger->warn('User successfully changed');

    return 0;
}

sub create {
    my ($self, $dbh, $options, @args) = @_;

    my %options = ();
    Getopt::Long::Configure(qw(bundling require_order));
    GetOptionsFromArray(\@args, \%options, $self->_option_spec('create'));
    if (!$self->options->{username} || !$self->options->{password}){
        $self->logger->error('Missing username or password');
        return 1;
    }

    if ($self->_get_user($dbh)) {
        my $username = $self->options->{username};
        $self->logger->error("User '$username' already exists");
        $dbh->rollback;
        return 1;
    }
    my $emp = $self->_create_employee(dbh => $dbh);
    if (!$emp) {
        $self->logger->error('Invalid employee');
        $dbh->rollback;
        return 1;
    }
    my $user = $self->_create_user(
        dbh => $dbh,
        entity_id => $emp->entity_id,
        username => $self->options->{username},
        password => $self->options->{password}
    );
    if (!$user) {
        $self->logger->error('Invalid user');
        $dbh->rollback;
        return 1;
    }
    #TODO: Fix validity
    my $ident_username=$dbh->quote_identifier($self->options->{username});
    $dbh->do(qq(ALTER USER $ident_username VALID UNTIL 'infinity'));

    # Add permissions
    return 1
        if ($self->options->{permission}
            and not $self->_add_permissions($dbh, $user));
    # Remove permissions
    return 1
        if ($self->options->{no_permission}
            and not $self->_remove_permissions($dbh, $user));

    $dbh->commit if ! $dbh->{AutoCommit};
    $dbh->disconnect;
    $self->logger->warn('User successfully created');

    return 0;
}

sub _create_employee {
    my ($self, %args) = @_;

    my $dbh = $args{dbh};

    # Validate
    my $salutation_id = $self->_get_valid_salutation($dbh);
    return undef if !$salutation_id;

    $self->logger->error('Missing country')
        if !$self->options->{country};
    my $country_id = $self->_get_valid_country($dbh);
    return undef if !$country_id;

    if (not $self->options->{first_name}
        or not $self->options->{last_name}){
        $self->logger->error('Missing first or last name');
        return undef;
    }
    my $_manager = $self->_get_user($dbh, $self->options->{manager});

    local $LedgerSMB::App_State::User = {};
    my $emp = LedgerSMB::Entity::Person::Employee->new(
        _dbh => $dbh,
        $self->options->%*,

        country_id => $country_id,
        salutation_id => $salutation_id,
        control_code => $self->options->{employeenumber},
        manager_id => $_manager->{entity_id},
        dob => LedgerSMB::PGDate->from_input($self->options->{dob}),
        name => ($self->options->{first_name} . ' ' .
                 ($self->options->{middle_name} ?
                  $self->options->{middle_name} . ' ' : '') .
                 $self->options->{last_name}),
    );
    $emp->save;

    return $emp;
}

sub _create_user {
    my ($self, %args) = @_;

    my $dbh = $args{dbh};
    my $_username = $args{username};
    my $ident_username=$dbh->quote_identifier($_username);

    $dbh->do(qq(DROP ROLE IF EXISTS $ident_username));
    my $user = LedgerSMB::Entity::User->new(
        entity_id => $args{entity_id},
        username => $_username,
        _dbh => $dbh,
        );
    $user->create($args{password});
    $dbh->do(qq(ALTER USER $ident_username VALID UNTIL 'infinity'));

    return $user;
}

# What about all the data attached to this user?
# Marked inactive would be better?
sub delete {
    my ($self, $dbh, $options, @args) = @_;

    my %options = ();
    Getopt::Long::Configure(qw(bundling require_order));
    GetOptionsFromArray(\@args, \%options, $self->_option_spec('delete'));
    return 1 if !$self->options->{username};

    my $user = $self->_get_user($dbh);
    if (!$user) {
        my $username = $self->options->{username};
        $self->logger->error("User '$username' does not exists");
        $dbh->rollback;
        return 1;
    }
    my $d =
        $dbh->do('DELETE FROM person WHERE entity_id = ?',
                 {}, $user->{entity_id})
        && $dbh->do('DELETE FROM employees WHERE entity_id= ?',
                    {}, $user->{entity_id})
        && $dbh->do('DELETE FROM users WHERE id = ?', {}, $user->{id});

    if ($d) {
        $dbh->commit if ! $dbh->{AutoCommit};
        $dbh->disconnect;
        $self->logger->info('User successfully deleted');
        return 0;
    }
    $dbh->rollback;
        $dbh->disconnect;
        $self->logger->error('User delete failed');
    return 1;
}

sub list {
    my ($self, $dbh, $options, @args) = @_;
    my $user;

    ## no critic (ProhibitFormats)
format LANG =
@<<<<<<@<<<<<<<<<<<<<<<@<<<<<<<<<<<<<<<<<<
$user->{id},$user->{username},$user->{created}
.
format LANG_TOP =
------------------------------------------
Id     Username        Created
------------------------------------------
.

    local $^ = 'LANG_TOP';
    local $~ = 'LANG';
    for $user (
        sort { $a->{username} cmp $b->{username} }
        LedgerSMB::User->get_all_users( { dbh => $dbh } )
        ) {
        write;
    }

    $dbh->disconnect;
    return 0;
}

sub _before_dispatch {
    my ($self, $options, @args) = @_;

    my $db_uri = (@args) ? $args[0] : undef;
    $self->db(
        LedgerSMB::Database->new(
            connect_data => {
                $self->config->get('connect_data')->%*,
                $self->connect_data_from_arg($db_uri)->%*,
            },
            schema       => $self->config->get('schema'),
        ));
    return ($self->db->connect({ AutoCommit => 0 }), $options, @args);
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 SYNOPSIS

   ledgersmb-admin user list <db-uri>
   ledgersmb-admin user create <db-uri> [options]
   ledgersmb-admin user delete <db-uri>
   ledgersmb-admin user change <db-uri>

=head1 DESCRIPTION

This command manages users in the database identified by C<db-uri>.

=head1 SUBCOMMANDS

=head2 list <db-uri>

Lists users in the database identified by C<db-uri>.

=head2 create <db-uri>

Creates user C<user> in the database identified by C<db-uri>.

=head3 OPTIONS

=over

=item username

User name of the created or changed user

=item password

Password

=item start_date

Start date of the employee

=item end_date

Ending date of the employee

=item dob

Date of birth

=item role

Role(s) to affect to the user.

=item ssn

Social security number

=item sales

Employee is in sales

=item manager

Employee manager

=item employeenumber

Employee number

=item is_manager

Employee is a manager

=item salutation

Salutation

=item first_name

First name of the employee

=item middle_name

Middle name of the employee

=item last_name

Last name of the employee

=item country

Country name

=back

=head2 delete <db-uri>

Deletes user C<user> in the database identified by C<db-uri>.

=head3 OPTIONS

=over

=item username

User name of the created or changed user

=back

=head2 change <db-uri>

Changes user C<user> in the database identified by C<db-uri>.

=head3 OPTIONS

=over

=item All create items

=item no-role

=back

Remove a role for the user

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2022 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut
