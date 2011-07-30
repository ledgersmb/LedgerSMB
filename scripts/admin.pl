#!/usr/bin/perl
package LedgerSMB::Scripts::admin;
use strict;

=pod

=head1 NAME

LedgerSMB:Scripts::admin

=head1 SYNOPSIS

This module provides the workflow scripts for managing users and permissions.
    
=head1 METHODS
        
=over   
        
=cut

require 'lsmb-request.pl';

use LedgerSMB::Template;
use LedgerSMB::DBObject::Admin;
use LedgerSMB::DBObject::User;
use LedgerSMB::DBObject::Location;
use Data::Dumper;
use LedgerSMB::Setting;
use LedgerSMB::Log;

# I don't really like the code in this module.  The callbacks are per form which
# means there is no semantic difference between different buttons that can be 
# clicked.  This results in a lot of code with a lot of conditionals which is
# both difficult to read and maintain.  In the future, this should be revisited
# and rewritten.  It makes the module too closely tied to the HTML.  --CT

my $logger = Log::Log4perl->get_logger('LedgerSMB::Scripts::admin');


sub __edit_page {
    
    
    my ($request, $otd) = @_;
    # otd stands for Other Template Data.
    my $dcsetting = LedgerSMB::Setting->new(base=>$request, copy=>'base');
    my $default_country = $dcsetting->get('default_country'); 
    my $admin = LedgerSMB::DBObject::Admin->new(base=>$request, copy=>'list', merge =>['user_id']);
    my @all_roles = $admin->get_roles($request->{company});
    my $user_obj = LedgerSMB::DBObject::User->new(base=>$request, copy=>'list', merge=>['user_id','company']);
    $user_obj->{company} = $request->{company};
    $user_obj->get($request->{user_id});
    my $user = $request->{_user};
    my $template = LedgerSMB::Template->new( 
        user => $request->{_user}, 
        template => 'Admin/edit_user', 
        language => $user->{language}, 
        format => 'HTML', 
        path=>'UI'
    );
    my $location = LedgerSMB::DBObject::Location->new(base=>$request);
    my $template_data = 
            {
                user=>$user_obj, 
                roles=>@all_roles,
                countries=>$admin->get_countries(),
                user_roles=>$user_obj->{roles},
                salutations=>$admin->get_salutations(),
                contact_classes=>$admin->get_contact_classes(),
                locations=>$user->{employee}->{locations},
                default_country => $dcsetting->{value},
                admin => $admin,
                stylesheet => $request->{stylesheet},
            };
    
    for my $key (keys(%{$otd})) {
        
        $template_data->{$key} = $otd->{$key};
    }
    my $template = LedgerSMB::Template->new( 
        user => $request->{_user}, 
        template => 'Admin/edit_user', 
        language => $user->{language}, 
        format => 'HTML', 
        path=>'UI'
    );
    $template->render($template_data);
}

=item save_user

Saves the user information, including name, etc.

This is also used to effect an administrative password reset or create new 
users.  However, if the import value is set to 1, it will not set the password.

The reasoning here is that we don't really want to set passwords when we are 
importing db cluster users into LedgerSMB.  If that needs to be done it can be
a separate stage.

=cut

sub save_user {
    my ($request, $admin) = @_;
    if ($request->{import} == "1"){
         delete $request->{password};
    }
    my $admin = LedgerSMB::DBObject::Admin->new(base=>$request, copy=>'all');
    
    my $sal = $admin->get_salutations();
    
    my $entity = $admin->save_user();
    if ($entity == 8){ # Duplicate user
          $request->{import} = 1;
          $request->{reimport} = 1;
          my $template = LedgerSMB::Template->new( 
                  user => $request->{_user}, 
              template => 'Admin/edit_user', 
              language => $request->{_user}->{language}, 
                format => 'HTML', 
                   path=>'UI'
          );
          my $dcsetting = LedgerSMB::Setting->new(base=>$request, copy=>'base');
          my $default_country = $dcsetting->get('default_country'); 
          $template->render(
            {
                user=>{user => $request, employee => $request}, 
                countries=>$admin->get_countries(),
                salutations=>$admin->get_salutations(),
                contact_classes=>$admin->get_contact_classes(),
                default_country => $dcsetting->{value},
                admin => $admin,
                stylesheet => $request->{stylesheet},
            }
          );
          return;
    }
    my $groups = $admin->get_roles();
    $admin->{stylesheet} = $request->{stylesheet};
    $admin->{user_id} = $admin->{user}->{id};
    __edit_page($admin);
}

=item save_roles

Saves the role assignments for a given user

=cut

sub save_roles {
    my ($request, $admin) = @_;
    my $admin = LedgerSMB::DBObject::Admin->new(base=>$request, copy=>'all');
    $admin->{stylesheet} = $request->{stylesheet};
    $admin->save_roles();
    __edit_page($admin);
}

=item new_user 

Displays a new user form.  No inputs used.

=cut

sub new_user {
    
    # uses the same page as create_user, only pre-populated.
    #my ($request) = @_;
    my $request = shift @_;
    my $admin = LedgerSMB::DBObject::Admin->new(base=>$request, copy=>'all');
    
    my $sal = $admin->get_salutations();
    
    my $groups = $admin->get_roles();
    my $user = $request->{_user};
    
    $logger->debug("scripts/admin.pl new_user: \$user = " . Data::Dumper::Dumper($user));
    
        my $template = LedgerSMB::Template->new( 
            user => $user, 
    	    template => 'Admin/edit_user',
    	    language => $user->{language}, 
            format => 'HTML', 
            path=>'UI'
        );
    
        $template->render(
            {
                salutations=>$sal,
                roles=>$groups,
                countries=>$admin->get_countries(),
                stylesheet => $request->{stylesheet},
            }
        );
}

=item edit_user

Displays the screen for editing a user.  user_id must be set to prepopulate.

=cut

sub edit_user {
    
    # uses the same page as create_user, only pre-populated.
    my ($request) = @_;
    __edit_page($request);
}

=item delete_user

Deletes a user and returns to search results.

=cut

# XXX Rewrite! --CT
sub delete_user {
    
    my ($request) = @_;
    my $user = $request->{_user};
    
    my $admin = LedgerSMB::DBObject::Admin->new(base=>$request, copy=>'all');
    
    # requires the field modifying_user to be set.
    
    my $status = $admin->delete_user($request->{modifying_user});
    
    # status can either be 1, or an error.
    # if there's an error, $status->throw() is called by admin.pm. Or possibly
    # in the template itself.
    
    my $template = LedgerSMB::Template->new ( user=>$user, 
        template=>'Admin/delete_user', language=>$user->{language}, 
        format=>'HTML', path=>'UI');
        
    $template->render($status);
}

=item save_contact

Saves contact information and returns to the edit user screen.

=cut

sub save_contact {
    
    my $request = shift @_;
    
    # Only ever a post, but check anyway
    if ($request->type eq "POST") {
        
        if ($request->{cancel}) {
            
            # If we have a cancel request, we just go back to edit_page.
            return __edit_page($request);
        }
        
        # We have a contact ID, ie, something we made up.
        my $c_id = $request->{contact_id};
        my $u_id = $request->{user_id};
        my $user_obj = LedgerSMB::DBObject::User->new(base=>$request, copy=>'list', merge=>['user_id','company']);
        $user_obj->get($u_id);
        
        # so we have a user object.
        # ->{contacts} is an arrayref to the list of contacts this user has
        # $request->{contact_id} is a reference to this structure.
        
        $user_obj->save_contact($c_id, $request->{contact_class}, $request->{contact});
        
        __edit_page($request,{});
    }
}

=item delete_contact 

Deletes contact information and returns to edit user screen

=cut

sub delete_contact {
    
    
    my $request = shift @_;
    
    # Only ever a post, but check anyway
    if ($request->type eq "POST") {
        
        if ($request->{cancel}) {
            
            # If we have a cancel request, we just go back to edit_page.
            return __edit_page($request);
        }
        
        # We have a contact ID, ie, something we made up.
        my $c_id = $request->{contact_id};
        my $u_id = $request->{user_id};
        my $user = LedgerSMB::DBObject::User->new(base=>$request, copy=>'user_id');
        $user->get($u_id);
        
        # so we have a user object.
        # ->{contacts} is an arrayref to the list of contacts this user has
        # $request->{contact_id} is a reference to this structure.
        
        $user->delete_contact($c_id);
        # Boom. Done.
        # Now, just call the main edit user page.
        
        __edit_page($request,undef,);
    }
}

=item save_location

Saves location information and returns to the edit user screen.

=cut

sub save_location {
    
    my $request = shift @_;
    my $user = $request->{_user};
    
    # Only ever a post, but check anyway
    if ($request->type eq "POST") {
        
        if ($request->{cancel}) {
            
            # If we have a cancel request, we just go back to edit_page.
            return __edit_page($request);
        }
        
        if ($request->{cancel}) {
            
            # If we have a cancel request, we just go back to edit_page.
            return __edit_page($request);
        }
        
        my $u_id = $request->{user_id}; # this is an entity_id
        my $user_obj = LedgerSMB::DBObject::User->new(base=>$request, copy=>'user_id');
        my $location = LedgerSMB::DBObject::Location->new(base=>$request, copy=>'all');
        $user_obj->get($request->{user_id});
        # So there's a pile of stuff we need.
        # lineone
        # linetwo
        # linethree
        # city
        # state
        # zipcode
        # country
        # u_id isn't an entity_it, though.
        $location->{user_id} = $user_obj->{user}->{entity_id};
        my $id = $location->save("person");
        # Done and done.
        
        __edit_page($request,{location=>$location});
    }
}

=item delete_location

Deletes a location and returns to edit user screen

=cut

sub delete_location {
    
    my $request = shift @_;
    
    # Having delete come over GET perhaps isn't the best technique.
    
    if ($request->type eq "GET") {
        
        my $l_id = $request->{location_id};
        my $u_id = $request->{user_id};
        my $user_obj = LedgerSMB::DBObject::User->new(base=>$request, copy=>'user_id');
        my $location = LedgerSMB::DBObject::Location->new(base=>$request, copy=>"location_id");
        
        $location->delete("person",$l_id,$user_obj->{user}->{entity_id});
        # Boom. Done.
        # Now, just call the main edit user page.
        __edit_page($request);
    }
}

=item search_users

Displays search criteria screen

=cut

sub search_users {
    my ($request) = @_;
    my $template = LedgerSMB::Template->new(
            user => $request->{_user}, 
            template => 'Admin/user_search', 
            locale => $request->{_locale}, 
            format => 'HTML', 
            path=>'UI'
    );
    $template->render($request);
}

=item get_user_results

Displays user search results

=cut

#XXX Add delete link
sub get_user_results {
    my ($request) = @_;
    my $admin = LedgerSMB::DBObject::Admin->new(base => $request);
    my @users = $admin->search_users;
    my $template = LedgerSMB::Template->new(
            user => $request->{_user}, 
            template => 'form-dynatable', 
            locale => $request->{_locale}, 
            format => 'HTML', 
            path=>'UI'
    );
    my $columns;
    @$columns = qw(id username first_name last_name ssn dob edit);
    
    my $column_names = {
        id => 'ID',
        username => 'Username',
        first_name => 'First Name',
        last_name => 'Last Name',
        ssn => 'Tax ID',
        dob => 'Date of Birth'
    };
    my $column_heading = $template->column_heading($column_names);
    
    my $rows = [];
    my $rowcount = "0";
    my $base_url = "admin.pl?action=edit_user";
    for my $u (@users) {
        $u->{i} = $rowcount % 2;
        $u->{edit} = {
            href =>"$base_url&user_id=$u->{id}", 
            text => '[' . $request->{_locale}->text('edit') . ']',
        };
        push @$rows, $u;
        ++$rowcount;
    }
    $admin->{title} = $request->{_locale}->text('Search Results');
    $template->render({
	form    => $admin,
	columns => $columns,
	heading => $column_heading,
        rows    => $rows,
	buttons => [],
	hiddens => [],
    }); 
}

=item list_sessions

Displays a list of open sessions.  No inputs required or used.

=cut

sub list_sessions {
    my ($request) = @_;
    my $admin = LedgerSMB::DBObject::Admin->new(base => $request);
    my @sessions = $admin->list_sessions();
    my $template = LedgerSMB::Template->new(
            user => $request->{_user}, 
            template => 'form-dynatable', 
            locale => $request->{_locale}, 
            format => 'HTML', 
            path=>'UI'
    );
    my $columns;
    @$columns = qw(id username last_used locks_active drop);
    my $column_names = {
        id => 'ID',
        username => 'Username',
        last_used => 'Last Used',
        locks_active => 'Transactions Locked'
    };
    my $column_heading = $template->column_heading($column_names);
    my $rows = [];
    my $rowcount = "0";
    my $base_url = "admin.pl?action=delete_session";
    for my $s (@sessions) {
        $s->{i} = $rowcount % 2;
        $s->{drop} = {
            href =>"$base_url&session_id=$s->{id}", 
            text => '[' . $request->{_locale}->text('delete') . ']',
        };
        push @$rows, $s;
        ++$rowcount;
    }
    $admin->{title} = $request->{_locale}->text('Active Sessions');
    $template->render({
	form    => $admin,
	columns => $columns,
    heading => $column_heading,
        rows    => $rows,
	buttons => [],
	hiddens => [],
    }); 
    
}

=item delete_session

Deletes the session specified by $request->{session_id}

=cut

sub delete_session {
    my ($request) = @_;
    my $admin = LedgerSMB::DBObject::Admin->new(base => $request);
    $admin->delete_session();
    list_sessions($request);
}

eval { do "scripts/custom/admin.pl"};

=back

=head1 COPYRIGHT

Copyright (C) 2010 LedgerSMB Core Team.  This file is licensed under the GNU 
General Public License version 2, or at your option any later version.  Please
see the included License.txt for details.

=cut


1;
