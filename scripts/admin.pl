#!/usr/bin/perl
package LedgerSMB::Scripts::admin;
use strict;

require 'lsmb-request.pl';

use LedgerSMB::Template;
use LedgerSMB::DBObject::Admin;
use LedgerSMB::DBObject::User;
use LedgerSMB::DBObject::Location;
use Data::Dumper;
use LedgerSMB::Setting;
use LedgerSMB::Log;

my $logger = Log::Log4perl->get_logger('LedgerSMB::Scripts::admin');

sub __edit_page {
    
    
    my ($request, $otd) = @_;
    # otd stands for Other Template Data.
    my $dcsetting = LedgerSMB::Setting->new(base=>$request, copy=>'base');
    my $default_country = $dcsetting->get('default_country'); 
    my $admin = LedgerSMB::DBObject::Admin->new(base=>$request, copy=>'list', merge =>['user_id']);
    my @all_roles = $admin->get_roles();
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
                locations=>$location->get_all($user_obj->{entity_id},"person"),
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

sub save_user {
    my ($request, $admin) = @_;
    my $admin = LedgerSMB::DBObject::Admin->new(base=>$request, copy=>'all');
    
    my $sal = $admin->get_salutations();
    
    my $entity = $admin->save_user();
    my $groups = $admin->get_roles();
    $admin->{stylesheet} = $request->{stylesheet};
    __edit_page($admin);
}

sub save_roles {
    my ($request, $admin) = @_;
    my $admin = LedgerSMB::DBObject::Admin->new(base=>$request, copy=>'all');
    $admin->{stylesheet} = $request->{stylesheet};
    $admin->save_roles();
    __edit_page($admin);
}


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

sub edit_user {
    
    # uses the same page as create_user, only pre-populated.
    my ($request) = @_;
    __edit_page($request);
}

sub edit_group {
    
    my ($request) = @_;
    my $admin = LedgerSMB::DBObject::Admin->new(base=>$request, copy=>'all');
    
    my $all_roles = $admin->role_list();
    my $user = $request->{_user};
    
    my $template = LedgerSMB::Template->new( 
        user => $user, 
        template => 'Admin/edit_group', 
        language => $user->{language}, 
        format => 'HTML', 
        path=>'UI'
    );
        
    if ($request->type() eq "POST") {

        my $role = $admin->save_role();
        return $template->render(
            {
                user=> $request->{role}, 
                roles=>$all_roles,
                user_roles=>$admin->get_user_roles($request->{role})
            }
        );
    }
    else {
        return $template->render(
            {
            roles=>$all_roles
            }
        );
    }    
}

sub create_group {
    
    my ($request) = @_;
    my $admin = LedgerSMB::DBObject::Admin->new(base=>$request, copy=>'all');
    my $user = $request->{_user};
    
    my $all_roles = $admin->get_roles();
    my $template = LedgerSMB::Template->new( 
        user => $user, 
        template => 'Admin/edit_group', 
        language => $user->{language}, 
        format => 'HTML', 
        path=>'UI'
    );
    if ($request->type() eq "POST") {
        
        my $role = $admin->save_role();
        return $template->render(
            {
                user=> $role, roles=>$all_roles
            }
        );
    }
    else {
        return $template->render({roles=>$all_roles});
    }
}

sub delete_group {
    
    my ($request) = @_;
    my $user = $request->{_user};
    
    my $admin = LedgerSMB::DBObject::Admin->new(base=>$request, copy=>'all');
    
    # requires the field modifying_user to be set.
    
    my $status = $admin->delete_group($request->{modifying_user});
    
    # status can either be 1, or an error.
    # if there's an error, $status->throw() is called by admin.pm. Or possibly
    # in the template itself.
    
    my $template = LedgerSMB::Template->new ( user=>$user, 
        template=>'Admin/delete_group', language=>$user->{language}, 
        format=>'HTML', path=>'UI');    
        
    $template->render($status);    
}

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

sub new_group {
    
    my ($request) = @_;
    my $user = $request->{_user};
    
    my $template = LedgerSMB::Template->new( user=>$user, 
        template=>'Admin/new_group', language=>$user->{language},
        format=>'HTML', path=>'UI');
    
    $template->render();
}

sub cancel {
        
    &main(@_);
}

sub __default {
    
    &main(@_);
}

sub main {
    
    my ($request) = @_;
    my $user = $request->{_user};
    
    my $template;
    
    my $user = LedgerSMB::DBObject::User->new(base=>$request, copy=>'all');
    
    my $ret = $user->get_all_users();
    
    $template = LedgerSMB::Template->new( 
        user=>$user, 
        template=>'Admin/main', 
        language=>$user->{language},
        format=>'HTML', 
        path=>'UI'
    );
    $template->render( { users=>$user->{users} } );
}

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

#eval { do "scripts/custom/admin.pl"};

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

sub delete_session {
    my ($request) = @_;
    my $admin = LedgerSMB::DBObject::Admin->new(base => $request);
    $admin->delete_session();
    list_sessions($request);
}

1;
