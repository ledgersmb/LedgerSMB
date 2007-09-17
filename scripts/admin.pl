#!/usr/bin/perl
package LedgerSMB::Scripts::admin;

require 'lsmb-request.pl';

use LedgerSMB::Template;
use LedgerSMB::DBObject::Admin;

sub new_user {
    
    # uses the same page as create_user, only pre-populated.
    my ($class, $request) = @_;
    my $admin = LedgerSMB::DBObject::Admin->new(base=>$request, copy=>'all');
    
    if ($request->type() == 'POST') {
        
        # do the save stuff
        
        my $entity = $admin->save_user();

        
        my $template = LedgerSMB::Template->new( user => $user, 
    	template => 'Admin/edit_user', language => $user->{language}, 
            format => 'HTML', path=>'UI');
    
        $template->render($entity);
    } else {
    
        my $template = LedgerSMB::Template->new( user => $user, 
    	template => 'Admin/edit_user', language => $user->{language}, 
            format => 'HTML', path=>'UI');
    
        $template->render();
    }
}

sub edit_user {
    
    # uses the same page as create_user, only pre-populated.
    my ($class, $request) = @_;
    my $admin = LedgerSMB::DBObject::Admin->new(base=>$request, copy=>'user_id');
    
    my $edited_user = $admin->get_entire_user();
    my $all_roles = $admin->role_list();
    
    my $template = LedgerSMB::Template->new( user => $user, 
	template => 'Admin/edit_user', language => $user->{language}, 
        format => 'HTML', path=>'UI');
    
    $template->render($edited_user, $all_roles);
}

sub edit_group {
    
    my ($class, $request) = @_;
    my $admin = LedgerSMB::DBObject::Admin->new(base=>$request, copy=>'all');
    
    my $all_roles = $admin->role_list();
    my $group = $admin->get_group();
    
    my $template = LedgerSMB::Template->new( user => $user, 
	template => 'Admin/edit_group', language => $user->{language}, 
        format => 'HTML', path=>'UI');
        
    $template->render($all_roles);    
}

sub create_group {
    
    my ($class, $request) = @_;
    my $admin = LedgerSMB::DBObject::Admin->new(base=>$request, copy=>'all');
    
    my $all_roles = $admin->role_list();
    
    my $template = LedgerSMB::Template->new( user => $user, 
	template => 'Admin/edit_group', language => $user->{language}, 
        format => 'HTML', path=>'UI');
        
    $template->render($all_roles);
}

sub delete_group {
    
    my ($class, $request) = @_;
    
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
    
    my ($class, $request) = @_;
    
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

sub new_user {
    
    my ($class, $request) = @_;
    
    my $template = LedgerSMB::Template->new( user=>$user, 
        template=>'Admin/new_user', language=>$user->{language},
        format=>'HTML', path=>'UI');
    
    $template->render();
}

sub new_group {
    
    my ($class, $request) = @_;
    
    my $template = LedgerSMB::Template->new( user=>$user, 
        template=>'Admin/new_group', language=>$user->{language},
        format=>'HTML', path=>'UI');
    
    $template->render();
}

sub __default {
    
    my ($class, $request) = @_;
    
    # check for login
    my $template;
        $template = LedgerSMB::Template->new( user=>$user, 
            template=>'Admin/main', language=>$user->{language},
            format=>'HTML', path=>'UI');
    $template->render();
}

1;