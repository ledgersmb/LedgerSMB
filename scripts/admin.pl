#!/usr/bin/perl
package LedgerSMB::Scripts::admin;

require 'lsmb-request.pl';

use LedgerSMB::Template;
use LedgerSMB::DBObject::Admin;
use LedgerSMB::DBObject::User;
use Data::Dumper;

sub new_user {
    
    # uses the same page as create_user, only pre-populated.
    #my ($request) = @_;
    my $request = shift @_;
    my $admin = LedgerSMB::DBObject::Admin->new(base=>$request, copy=>'all');
    
    my $sal = $admin->get_salutations();
    
    my $groups = $admin->get_roles();
    
    if ($request->type() eq 'POST') {
        
        # do the save stuff
        
        my $entity = $admin->save_new_user();
        
        my $template = LedgerSMB::Template->new( user => $user, 
    	template => 'Admin/edit_user', language => $user->{ language }, 
            format => 'HTML', path=>'UI');
    
        $template->render(
            {   
                user=>$entity,
                salutations=>$sal,
                roles=>$groups
            }
        );
    } else {
    
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
                roles=>$groups
            }
        );
    }
}

sub edit_user {
    
    # uses the same page as create_user, only pre-populated.
    my ($request) = @_;
    my $admin = LedgerSMB::DBObject::Admin->new(base=>$request, copy=>'user_id');
    my $user = LedgerSMB::DBObject::User->new(base=>$request, copy=>'user_id');
    
    $user->get($request->{user_id});
    
    my $all_roles = $admin->get_roles();

    my $template = LedgerSMB::Template->new( 
        user => $user, 
        template => 'Admin/edit_user', 
        language => $user->{language}, 
        format => 'HTML', 
        path=>'UI'
    );
    
    if ($request->type() eq 'POST') {
        
        $admin->save_user();
        $admin->save_roles();
        $template->render(
            {
                user=>$admin->get_entire_user(),
                roles=>$all_roles,
                user_roles=>$admin->get_user_roles($request->{username})
            }
        );
    }
    else {
        $template->render(
            {
                user=>$user, 
                roles=>$all_roles,
                user_roles=>$admin->get_user_roles($request->{user})
            }
        );
    }
}

sub edit_group {
    
    my ($request) = @_;
    my $admin = LedgerSMB::DBObject::Admin->new(base=>$request, copy=>'all');
    
    my $all_roles = $admin->role_list();
    
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

#eval { do "scripts/custom/admin.pl"};

1;
