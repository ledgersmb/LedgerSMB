package LedgerSMB::DBObject::Admin;

=head1 NAME

LedgerSMB::DBObject::Admin - User/group management for LedgerSMB

=head1 SYNOPSIS

User/group management for LedgerSMB

=head1 INHERITS

=over

=item Universal

=item LedgerSMB

=item LedgerSMB::DBObject

=back

=head1 METHODS

=over

=cut


use base qw(LedgerSMB::PGOld);

use LedgerSMB::Entity::Person::Employee;
use LedgerSMB::DBObject::User;
use Log::Log4perl;
use strict;
use warnings;

my $logger = Log::Log4perl->get_logger("LedgerSMB::DBObject::Admin");

=item list_sessions

returns a list of active sessions, when they were last used, and how many
discretionary locks they hold.  The list is also attached to the
active_sessions hash value.  No inputs required or used.

=cut

sub list_sessions {
   my $self = shift @_;
   my @sessions = $self->call_dbmethod(funcname => 'admin__list_sessions');
   $self->{active_sessions} = \@sessions;
   return @sessions;
}

=item delete_session

Deletes a session identified by the session_id hashref.

=cut

sub delete_session {
   my $self = shift @_;
   my @sessions = $self->call_dbmethod(funcname => 'admin__drop_session');
}

=item save_roles

Saves the roles assigned to a user.
Each role is specified as a hashref true value, where the key is the full name
of the role (i.e. starting with lsmb_[dbname]__).

=cut

sub save_roles {

    my $self = shift @_;

    my $user = LedgerSMB::DBObject::User->new( { base=>$self, copy=>'all' } );
    $user->get();
    $self->{modifying_user} = $user->{user}->{username};
    my @roles = $self->call_dbmethod( funcname => "admin__get_roles" );
    my @user_roles = $self->call_dbmethod(funcname => "admin__get_roles_for_user");
    my %active_roles;
    for my $role (@user_roles) {
       $active_roles{"$role->{admin__get_roles_for_user}"} = 1;
    }

    my $status;

    for my $r ( @roles) {
        my $role = $r->{rolname};
        my $reqrole = $role;

        if ( $active_roles{$role} && $self->{$reqrole} ) {
            # do nothing.
            ;
        }
        elsif ($active_roles{$role} && !($self->{$reqrole} )) {

            # do remove function
            $status = $self->call_procedure(funcname => "admin__remove_user_from_role",
                args=>[ $self->{modifying_user}, $role ] );
        }
        elsif ($self->{$reqrole} and !($active_roles{$role} )) {

            # do add function
            $status = $self->call_procedure(funcname=> "admin__add_user_to_role",
               args=>[ $self->{modifying_user}, $role ]
            );
        }
    }
}

=item get_salutations

Returns a list of salutation records from the db for the dropdowns.

=cut

sub get_salutations {
    my $self = shift;
    return $self->call_dbmethod(funcname => 'person__list_salutations');
}


=item get_roles

Returns a list of role names with the following format:

{role => $full_role_name, description => $short_role_name}

The short role name is the full role name with the prefix removed (i.e. without
the lsmb_[dbname]__ prefix).

=cut

sub get_roles {
    my $self = shift @_;
    my $company = shift; # optional
    my @s_rows = $self->call_procedure(funcname =>'admin__get_roles');
    my @rows;

    $company = $self->{company} if ! defined $company;
    $logger->debug("get_roles: company = $company");
    $logger->debug("get_roles: self = " . Data::Dumper::Dumper($self));
    for my $role (@s_rows) {
        my $rolname = $role->{'rolname'};
        my $description = $rolname;
        $description =~ s/lsmb_//;
        $description =~ s/${company}__//
            if defined $company;
        $description =~ s/_/ /g;
        push @rows, { name => $rolname, description => #"lsmb_$company\_"  #
                          $description
        };
    }
    return \@rows;
}

=back

=head1 COPYRIGHT

Copyright (c) 2009, the LedgerSMB Core Team.  This is licensed under the GNU
General Public License, version 2, or at your option any later version.  Please
see the accompanying License.txt for more information.

=cut

1;
