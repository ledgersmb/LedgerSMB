
use v5.36;
use warnings;
use experimental 'try';

package LedgerSMB::Admin::Command::user;

=head1 NAME

LedgerSMB::Admin::Command::user - ledgersmb-admin 'user' command

=cut

use Getopt::Long qw(GetOptionsFromArray);
use LedgerSMB::Admin::Command;
use LedgerSMB::App_State;
use LedgerSMB::Company;
use LedgerSMB::Database;
use LedgerSMB::Entity::Person::Employee;
use LedgerSMB::Entity::User;
use LedgerSMB::PGDate;
use LedgerSMB::User;

use Array::PrintCols;

use Moose;
use experimental 'try'; # Work around Moose re-enabling experimenal warnings
extends 'LedgerSMB::Admin::Command';
use namespace::autoclean;

has options => (is => 'ro', default => sub { {} });

sub _get_valid_salutation {
    my ($self, $dbh) = @_;
    my $sth = $dbh->prepare('SELECT id FROM salutation WHERE salutation ilike ?');
    $sth->execute($self->options->{salutation})
        or die $dbh->errstr;
    my $value = $sth->fetchrow_hashref;
    $self->logger->error('Invalid salutation')
        if !$value;
    return $value->{id};
}

sub _get_salutation_by_id {
    my ($self, $dbh, $id) = @_;
    my $sth = $dbh->prepare('SELECT salutation FROM salutation WHERE id=?');
    $sth->execute($id)
        or die $dbh->errstr;
    my $values = $sth->fetchrow_hashref;
    return $values->{salutation};
}

sub _get_user {
    my ($self, $dbh, $_username) = @_;
    $_username //= $self->options->{username};

    # Get user by username
    my $sth =
        $dbh->prepare(q(SELECT id, entity_id FROM users WHERE username=?));
    $sth->execute($_username)
        or die $dbh->errstr;
    my ($user) = $sth->fetchrow_hashref;
    return $user;
}

sub _get_valid_country {
    my ($self, $dbh) = @_;
    return if !$self->options->{country};
    my $sth = $dbh->prepare('SELECT * FROM country WHERE name ilike ? OR short_name=?');
    $sth->execute($self->options->{country},uc $self->options->{country})
        or die $dbh->errstr;
    my $values = $sth->fetchrow_hashref;
    if ($values) {
        $self->options->{country} = $values->{name};
        return $values;
    }
    $self->logger->error('Invalid country');
    return;
}

sub _get_country_by_id {
    my ($self, $dbh, $id) = @_;
    my $sth = $dbh->prepare('SELECT * FROM country WHERE id=?');
    $sth->execute($id)
        or die $dbh->errstr;
    my $values = $sth->fetchrow_hashref;
    return $values->{name};
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
            'end-date=s' => \$self->options->{end_date},
            'is-manager!' => \$self->options->{is_manager},
            'manager=s' => \$self->options->{manager},
            'job-title=s' => \$self->options->{role},
            'is-sales!' => \$self->options->{is_sales},
            'ssn=s' => \$self->options->{ssn},
            'start-date=s' => \$self->options->{start_date},
            # person
            #'birthdate=s' => \$birthdate, # Not used?
            'country=s' => \$self->options->{country},
            'first-name=s' => \$self->options->{first_name},
            'last-name=s' => \$self->options->{last_name},
            'middle-name=s' => \$self->options->{middle_name},
            #'personal-id=s' => \$personal_id,
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
                $self->logger->error("Invalid permission '$p'");
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
                    $self->logger->error("Invalid permission '$p'");
                    $dbh->rollback;
                    return 0;
                }
                @$roles = grep { $h->{rolname} ne $_ } @$roles;
            }
        }
        $user->save_roles($roles);
    return 1;
}

sub change {
    my ($self, $dbh, $options, @args) = @_;

    try {
        my %options = ();
        Getopt::Long::Configure(qw(bundling require_order));
        GetOptionsFromArray(\@args, \%options, $self->_option_spec('change'));
        if (! $self->options->{username}) {
            $self->logger->error('Missing option --username');
            return 1;
        }

        my $_user = $self->_get_user($dbh);
        if (!$_user) {
            my $username = $self->options->{username};
            $self->logger->error("User '$username' does not exists");
            return 1;
        }

        local $LedgerSMB::App_State::DBH = $dbh;
        my $user = LedgerSMB::Entity::User->get($_user->{entity_id});
        my $emp = LedgerSMB::Entity::Person::Employee->get($_user->{entity_id});
        my $_country = $self->_get_valid_country($dbh);

        if ( $self->options->{password} ) {
            $user->reset_password($self->options->{password});
        }
        my $needs_save = 0;
        for my $setting (qw(dob employeenumber end_date first_name
                            is_manager last_name manager middle_name role sales
                            salutation ssn start_date)) {
            if ($self->options->{$setting}) {
                $emp->{$setting} = $self->options->{$setting};
                $needs_save = 1;
            }
        }
        if ($self->options->{country}) {
            $emp->{country} = $_country->{name};
            $emp->{country_id} = $_country->{id};
            $needs_save = 1;
        }

        $emp->save if $needs_save;

        # Add permissions
        return 1 if ($self->options->{permission}
                     and not $self->_add_permissions($dbh, $user));

        # Remove permissions
        return 1 if ($self->options->{no_permission}
                     and not $self->_remove_permissions($dbh, $user));

        $dbh->commit;
        $dbh->disconnect;
        $dbh = undef;
        $self->logger->warn('User successfully changed');

        return 0;
    }
    catch ($e) {
        $self->logger->error("Unhandled error caught during user modification: $e");
    }
    finally {
        if ($dbh) {
            $dbh->rollback;
            $dbh->disconnect;
        }
    }
}

sub create {
    my ($self, $dbh, $options, @args) = @_;

    try {
        my %options = ();
        Getopt::Long::Configure(qw(bundling require_order));
        GetOptionsFromArray(\@args, \%options, $self->_option_spec('create'));
        if (!$self->options->{username} || !$self->options->{password}){
            $self->logger->error('Missing --username or --password option');
            return 1;
        }

        if ($self->_get_user($dbh)) {
            my $username = $self->options->{username};
            $self->logger->error("User '$username' already exists");
            return 1;
        }
        my $emp = $self->_create_employee(dbh => $dbh);
        if (!$emp) {
            $self->logger->error('Invalid employee');
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

        $dbh->commit;
        $dbh->disconnect;
        $dbh = undef;
        $self->logger->warn('User successfully created');

        return 0;
    }
    catch ($e) {
        $self->logger->error("Unhandled exception during user creation: $e");
    }
    finally {
        if ($dbh) {
            $dbh->rollback;
            $dbh->disconnect;
        }
    }
}

sub _create_employee {
    my ($self, %args) = @_;

    my $dbh = $args{dbh};

    # Validate
    my $salutation_id;
    $salutation_id = $self->_get_valid_salutation($dbh)
        if $self->options->{salutation};
    return undef if $self->options->{salutation} && !$salutation_id;

    $self->logger->error('Missing country')
        if !$self->options->{country};
    my $_country = $self->_get_valid_country($dbh);
    return undef if !$_country;

    if (not $self->options->{first_name}
        or not $self->options->{last_name}){
        $self->logger->error('Missing first or last name');
        return undef;
    }
    my $_manager = $self->_get_user($dbh, $self->options->{manager});

    my $emp = LedgerSMB::Entity::Person::Employee->new(
        _dbh => $dbh,
        $self->options->%*,

        country_id => $_country->{id},
        salutation_id => $salutation_id,
        control_code => $self->options->{employeenumber},
        manager_id => $_manager->{entity_id},
        dob => LedgerSMB::PGDate->from_input(
            $self->options->{dob},
            format => 'YYYY-MM-DD'
        ),
        start_date => LedgerSMB::PGDate->from_input(
            $self->options->{start_date},
            format => 'YYYY-MM-DD'
        ),
        end_date => LedgerSMB::PGDate->from_input(
            $self->options->{end_date},
            format => 'YYYY-MM-DD'
        ),
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

    try {
        my %options = ();
        Getopt::Long::Configure(qw(bundling require_order));
        GetOptionsFromArray(\@args, \%options, $self->_option_spec('delete'));
        if (!$self->options->{username}) {
            $self->logger->error('Missing --username option');
            return 1;
        }


        my $user = $self->_get_user($dbh);
        if (!$user) {
            my $username = $self->options->{username};
            $self->logger->error("User '$username' does not exists");
            return 1;
        }
        my $d =
            $dbh->do('DELETE FROM person WHERE entity_id = ?',
                     {}, $user->{entity_id})
            && $dbh->do('DELETE FROM employees WHERE entity_id= ?',
                        {}, $user->{entity_id})
            && $dbh->do('DELETE FROM users WHERE id = ?', {}, $user->{id});

        if (!$d) {
            $self->logger->error('User delete failed');
            return 1;
        }
        $dbh->commit;
        $dbh->disconnect;
        $dbh = undef;
        $self->logger->info('User successfully deleted');
        return 0;
    }
    catch ($e) {
        $self->logger->error("Unhandled error during user deletion: $e");
    }
    finally {
        if ($dbh) {
            $dbh->rollback;
            $dbh->disconnect;
        }
    }
}

sub list {
    my ($self, $dbh, $options, $db_uri, $user) = @_;

    if (!defined $user) {
        my @users = LedgerSMB::User->get_all_users( { dbh => $dbh } );

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
        for $user (sort
                    {
                        $a->{username} cmp $b->{username}
                    } @users) {
            write;
        }
    }
    else {
        my $_user = $self->_get_user($dbh,$user);
        if (!$_user) {
            $self->logger->error("User '$user' does not exists");
            $dbh->rollback;
            return 1;
        }

        local $LedgerSMB::App_State::DBH = $dbh;
        $user = LedgerSMB::Entity::User->get($_user->{entity_id});
        my $emp = LedgerSMB::Entity::Person::Employee->get($_user->{entity_id});

        print STDOUT 'Username: ',$user->{username},
            ', Name: "',$self->_get_salutation_by_id($dbh,$emp->{salutation_id}), ' ',
            $emp->{first_name}, ' ',
            $emp->{middle_name} ? $emp->{middle_name} . ' ' : '',
            $emp->{last_name}, '"',
            ', Job Title: "', $emp->{role}, '", Number: ', $emp->{employeenumber},"\n",
            'BirthDate: "', $emp->{dob}, '", Started: "', $emp->{start_date}, '", Ended: "', $emp->{end_date}, "\"\n",
            'Manager: ', $emp->{is_manager} ? 'YES' : 'NO', ', Sales: ', $emp->{is_sales} ? 'YES' : 'NO',
            ', Manager user: ', $emp->{manager} // 'undef',"\n",
            'Country: ', $self->_get_country_by_id($dbh, $emp->{country_id}), ', SSN: ', $emp->{ssn} // 'undef',"\n",
            "Permissions:\n";
        $Array::PrintCols::PreSorted = 0;
        print_cols \$user->{role_list}->@*, -5, 0, 1;
    }
    $dbh->disconnect;
    return 0;
}

sub _before_dispatch {
    my ($self, $options, @args) = @_;

    my $db_uri = (@args) ? $args[0] : undef;
    my $connect_data = {
        $self->config->get('connect_data')->%*,
        $self->connect_data_from_arg($db_uri)->%*,
    };
    $self->db(
        LedgerSMB::Database->new(
            connect_data => $connect_data,
            source_dir   => $self->config->sql_directory,
            schema       => $self->config->get('schema'),
        ));
    return ($self->db->connect({ AutoCommit => 0 }), $options, @args);
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 SYNOPSIS

   ledgersmb-admin user list <db-uri> user1
   ledgersmb-admin user create <db-uri> --username user1 --password secret [options...]
   ledgersmb-admin user delete <db-uri> --username user1 [options...]
   ledgersmb-admin user change <db-uri> --username user1 [options...]

=head1 DESCRIPTION

This command manages users in the database identified by C<db-uri>.

=head1 SUBCOMMANDS

=head2 list <db-uri> <user>

Lists all users in the database identified by C<db-uri> if <user> is not specified,
otherwise list the user specified.

=head2 create <db-uri>

Creates a user in the database identified by C<db-uri>.

=head3 OPTIONS

=over

=item username C<string>

User name of the created, deleted or changed user

=item password C<string>

Password

=item start-date C<YYYY-MM-DD>

Start date of the employee as C<YYYY-MM-DD>

=item end-date C<YYYY-MM-DD>

Ending date of the employee

=item dob C<YYYY-MM-DD>

Date of birth

=item permission <list>

Permission(s) to affect to the user.

Permission can be C<Full Permissions> or a comma separated list of the following roles:

C<account_all> C<account_create> C<account_delete> C<account_edit> C<account_link_description_create>
C<ap_all> C<ap_voucher_all> C<ap_invoice_create> C<ap_invoice_create_voucher>
C<ap_transaction_all> C<ap_transaction_create> C<ap_transaction_create_voucher> C<ap_transaction_list>
C<ar_all> C<ar_invoice_create> C<ar_invoice_create_voucher> C<ar_transaction_all> C<ar_transaction_create>
C<ar_transaction_create_voucher> C<ar_transaction_list> C<ar_voucher_all> C<assembly_stock>
C<assets_administer> C<assets_approve> C<assets_depreciate> C<assets_enter> C<audit_trail_maintenance>
C<auditor> C<base_user> C<batch_create> C<batch_list> C<batch_post> C<budget_approve> C<budget_enter>
C<budget_obsolete> C<budget_view> C<business_type_all> C<business_type_create> C<business_type_edit>
C<business_units_manage> C<cash_all> C<contact_all_rights> C<contact_class_cold_lead> C<contact_class_contact>
C<contact_class_customer> C<contact_class_employee> C<contact_class_hot_lead> C<contact_class_lead>
C<contact_class_referral> C<contact_class_robot> C<contact_class_sub_contractor> C<contact_class_vendor>
C<contact_create> C<contact_delete> C<contact_edit> C<contact_read> C<draft_modify> C<draft_post>
C<employees_manage> C<exchangerate_edit> C<file_attach_eca> C<file_attach_entity> C<file_attach_order>
C<file_attach_part> C<file_attach_tx> C<file_read> C<file_upload> C<financial_reports> C<gifi_create>
C<gifi_edit> C<gl_all> C<gl_reports> C<gl_transaction_create> C<gl_voucher_create> C<inventory_adjust>
C<inventory_all> C<inventory_approve> C<inventory_receive> C<inventory_reports> C<inventory_ship>
C<inventory_transfer> C<language_create> C<language_edit> C<orders_generate> C<orders_manage>
C<orders_purchase_consolidate> C<orders_sales_consolidate> C<orders_sales_to_purchase>
C<part_create> C<part_delete> C<part_edit> C<payment_process> C<pricegroup_create> C<pricegroup_edit>
C<purchase_order_create> C<purchase_order_edit> C<purchase_order_list> C<receipt_process> C<reconciliation_all>
C<reconciliation_approve> C<reconciliation_enter> C<recurring> C<rfq_create> C<rfq_list> C<sales_order_create>
C<sales_order_edit> C<sales_order_list> C<sales_quotation_create> C<sales_quotation_list> C<sic_all>
C<sic_create> C<sic_edit> C<system_admin> C<system_settings_change> C<system_settings_list>
C<tax_form_save> C<taxes_set> C<template_edit> C<timecard_add> C<timecard_list> C<timecard_order_generate>
C<transaction_template_delete> C<translation_create> C<users_manage> C<voucher_delete> C<warehouse_create>
C<warehouse_edit> C<yearend_reopen> C<yearend_run> C<yearend_run>

=item ssn C<string>

Social security number

=item is-sales

Employee is in sales. Negatable

=item manager C<string>

Employee manager name

=item employeenumber C<string>

Employee number

=item is-manager

Employee is a manager. Negatable

=item job-title C<string>

Employee job title

=item salutation C<string>

Salutation

=item first-name C<string>

First name of the employee

=item middle-name C<string>

Middle name of the employee

=item last-name C<string>

Last name of the employee

=item country C<string>

Country name or 2 letter country abbreviation

=back

=head2 delete <db-uri> C<user>

Deletes user C<user> in the database identified by C<db-uri>.

=head3 OPTIONS

=over

=item username C<string>

User name of the created or changed user

=back

=head2 change <db-uri> C<user>

Changes user C<user> in the database identified by C<db-uri>.

=head3 OPTIONS

=over

=item All create items

=item no-permission <list>

=back

Remove a permission for the user

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2022-2023 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut
