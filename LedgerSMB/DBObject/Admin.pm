package LedgerSMB::DBObject::Admin;

=head1 NAME

LedgerSMB::DBObject::Admin 

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


use base qw(LedgerSMB::DBObject);

use LedgerSMB::Location;
use LedgerSMB::Contact;
use LedgerSMB::DBObject::Employee;
use LedgerSMB::DBObject::User;
use LedgerSMB::Log;
use strict;

my $logger = Log::Log4perl->get_logger("LedgerSMB::DBObject::Admin");

#[18:00:31] <aurynn> I'd like to split them employee/user and roles/prefs
#[18:00:44] <aurynn> edit/create employee and add user features if needed.

# Deleting "save" method.  There is no point to a routine that only raises
# an error given that it is not inherited.  An error will be raised in a way
# which is more developer-friendly.   --CT


=item save_user

Saves a user optionally with location and contact data.

If the password or import hash values is set, will not save contact or address
information.

This API is not fully documented at this time because it is expected that it will
be broken down into more manageable chunks in future versions.  Please do not 
count on the behavior.

=cut

sub save_user {

    # This really should be split out into multiple routines for saving
    # addresses, contact info, and the like.  It's hard to follow and document
    # a long function like this.  Oh well, to be part of the next version 
    # refactoring.  --CT
    
    my $self = shift @_;

    # I deleted some assignments which didn't play well with strict mode
    # and by my reading probably broke things. --CT

    my $employee = LedgerSMB::DBObject::Employee->new( base=>$self);
    
    $employee->save();
    
    my $user = LedgerSMB::DBObject::User->new(base=>$self, copy=>'list',
        merge=>[
            'username',
            'password',
            'is_a_user',
            'user_id',
            'import',
        ]
    );
    $user->{entity_id} = $employee->{entity_id};
    if ($user->save() == 8){ # Duplicate User exception --CT
        return 8;
    }
    $self->{user} = $user;
    $self->{employee} = $employee;

    if ($self->{password} or $self->{import}){
       return $self->{dbh}->commit;
    }
    # The location handling here is really brittle.....
    # In the future, we need to have a coding standard that says that for
    # objects, the parent is responsible for the child, and accept a data tree
    # instead of a sort of ravioli architecture.  --CT.
    my $loc = LedgerSMB::DBObject::Location->new(base=>$self, copy=>'list', 
        merge=>[
            'address1',
            'address2',
            'city',
            'state',
            'zipcode',
            'country',
            'companyname',            
        ]
    );
     
    $loc->{type} = 'person';
    $loc->save();
    $employee->set_location($loc->{id});
    $loc->(person=>$employee);
    my $workphone = LedgerSMB::Contact->new(base=>$self);
    my $homephone = LedgerSMB::Contact->new(base=>$self);
    my $email = LedgerSMB::Contact->new(base=>$self);
    
    $workphone->set(person=>$employee, class=>1, contact=>$self->{workphone});
    $homephone->set(person=>$employee, class=>11, contact=>$self->{homephone});
    $email->set(person=>$employee, class=>12, contact=>$self->{email});
    $workphone->save();
    $homephone->save();
    $email->save();
    $self->{dbh}->commit;
    
}

=item search_users

Returns a list of users matching search criteria, and attaches that list to the 
user_results hash value.

Search criteria:

=over

=item username

=item first_name

=item last_name

=item ssn

=item dob

=back

Undef matches all values.  All matches exact except username which allows for
partial matches.

=cut

sub search_users {
   my $self = shift @_;
   my @users = $self->exec_method(funcname => 'admin__search_users');
   $self->{user_results} = \@users;
   return @users;
}

=item list_sessions

returns a list of active sessions, when they were last used, and how many 
discretionary locks they hold.  The list is also attached to the
active_sessions hash value.  No inputs required or used.

=cut

sub list_sessions {
   my $self = shift @_;
   my @sessions = $self->exec_method(funcname => 'admin__list_sessions');
   $self->{active_sessions} = \@sessions;
   return @sessions;
}

=item delete_session 

Deletes a session identified by the session_id hashref.

=cut

sub delete_session {
   my $self = shift @_;
   my @sessions = $self->exec_method(funcname => 'admin__drop_session');
   return $self->{dbh}->commit;
}

=item save_roles 

Saves the roles assigned to a user.
Each role is specified as a hashref true value, where the key is the full name
of the role (i.e. starting with lsmb_[dbname]__).

=cut

sub save_roles {
    
    my $self = shift @_;
    
    my $user = LedgerSMB::DBObject::User->new( base=>$self, copy=>'all' );
    $user->get();
    $self->{modifying_user} = $user->{user}->{username};
    my @roles = $self->exec_method( funcname => "admin__get_roles" );
    my @user_roles = $self->exec_method(funcname => "admin__get_roles_for_user");
    my %active_roles;
    for my $role (@user_roles) {
       
       # These are our user's roles.
       print STDERR "Have $role->{admin__get_roles_for_user}\n";
        
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
            $status = $self->call_procedure(procname => "admin__remove_user_from_role",
                args=>[ $self->{modifying_user}, $role ] );
        }
        elsif ($self->{$reqrole} and !($active_roles{$role} )) {
            
            # do add function
            $status = $self->call_procedure(procname => "admin__add_user_to_role",
               args=>[ $self->{modifying_user}, $role ] 
            );
        }         
    }
    $self->{dbh}->commit;
}

=item get_salutations

Returns a list of salutation records from the db for the dropdowns.

=cut

sub get_salutations {
    
    my $self = shift;

    # Adding SQL queries like this into the code directly is bad practice. --CT
    my $sth = $self->{dbh}->prepare("SELECT * FROM salutation ORDER BY id ASC");
    
    $sth->execute();
    
    # Returns a list of hashrefs
    return $sth->fetchall_arrayref( {} );
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
    my @s_rows = $self->call_procedure(procname=>'admin__get_roles');
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

=item get_countries

Returns a reference to an array of hashrefs including the country data in the db.

Sets the same reference to the countries hash value.

=cut

sub get_countries {
    
    my $self = shift @_;
    
    @{$self->{countries}} 
          =$self->exec_method(funcname => 'location_list_country'); 
	# returns an array of hashrefs.
    return $self->{countries};
}

=item get_contact_classes

Returns a list of hashrefs ({id =>, class =>}) relating to the contact classes.

=cut

sub get_contact_classes {
    
    my $self = shift @_;

    # There are a couple problems here:
    # 1)  It's best to mix Perl and SQL as little as possible.  Mixing gets 
    # around our centralized sql injection prevention measures.  While this 
    # query poses no direct risk there, it's a bad habit to be in.
    # 
    # 2)  Lack of ordering means drop down list orders could change in the future
    # which is nprobably not very good.
    # --CT
    my $sth = $self->{dbh}->prepare("select id, class as name from contact_class");
    my $code = $sth->execute();
    return $sth->fetchall_arrayref({});
}

=back

=head1 COPYRIGHT

Copyright (c) 2009, the LedgerSMB Core Team.  This is licensed under the GNU 
General Public License, version 2, or at your option any later version.  Please 
see the accompanying License.txt for more information.

=cut

1;
