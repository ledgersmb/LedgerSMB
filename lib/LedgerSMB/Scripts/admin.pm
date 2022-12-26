package LedgerSMB::Scripts::admin;

use strict;
use warnings;

=head1 NAME

LedgerSMB:Scripts::admin - web entry points for user and perms management

=head1 DESCRIPTION

This module provides the workflow scripts for managing users and permissions.

=head1 METHODS

=over

=cut

use LedgerSMB::DBObject::Admin;
use LedgerSMB::DBObject::User;
use LedgerSMB::Entity::User;
use LedgerSMB::Report::Listings::User;
use LedgerSMB::Template::UI;


use Log::Any;

# I don't really like the code in this module.  The callbacks are per form which
# means there is no semantic difference between different buttons that can be
# clicked.  This results in a lot of code with a lot of conditionals which is
# both difficult to read and maintain.  In the future, this should be revisited
# and rewritten.  It makes the module too closely tied to the HTML.  --CT

my $logger = Log::Any->get_logger(category => 'LedgerSMB::Scripts::admin');


=item list_users

=cut

sub list_users {
    my ($request) = @_;
    my $report = LedgerSMB::Report::Listings::User->new(%$request);
    return $request->render_report($report);
}


=item delete_user

=cut

sub delete_user {
    my ($request) = @_;
    my ($user) = $request->call_procedure(
        funcname => 'admin__get_user',
        args => [ $request->{id} ]
        );
    $request->call_procedure(
        funcname => 'admin__delete_user',
        args => [ $user->{username}, 1 ] # delete the role too
        );

    return list_users($request);
}


=item edit_user

=cut

sub edit_user {
    my ($request) = @_;
    my ($user) = $request->call_procedure(
        funcname => 'admin__get_user',
        args => [ $request->{id} ]
        );
    my $user_data = LedgerSMB::Entity::User->get($user->{entity_id});
    my $template = LedgerSMB::Template::UI->new_UI;
    return $template->render($request, 'Contact/divs/user', {
        stand_alone => 1,
        user        => $user_data,
        request     => $request,
        roles       => $user_data->list_roles,
    });
}


=item list_sessions

Displays a list of open sessions.  No inputs required or used.

=cut

sub list_sessions {
    my ($request) = @_;
    my $admin = LedgerSMB::DBObject::Admin->new(%$request);
    my @sessions = $admin->list_sessions();
    my $column_names = {
        id => 'ID',
        username => 'Username',
        last_used => 'Last Used',
        locks_active => 'Transactions Locked'
    };
    my $columns = [
        map {
            { type => 'text',
              col_id => $_,
              name => $column_names->{$_}
            }  } qw(id username last_used locks_active) ];
    my $base_url = 'admin.pl?action=delete_session';
    push @$columns,
        {
            type => 'href',
            col_id => 'drop',
            href_base => "$base_url&session_id=",
            name => ''
        };
    for my $s (@sessions) {
        $s->{drop} = '[' . $request->{_locale}->text('delete') . ']';
        $s->{row_id} = $s->{id};
    }
    my $template = LedgerSMB::Template::UI->new_UI;
    return $template->render($request, 'Reports/display_report', {
        name    => $request->{_locale}->text('Active Sessions'),
        columns => $columns,
        rows    => \@sessions,
    });
}

=item delete_session

Deletes the session specified by $request->{session_id}

=cut

sub delete_session {
    my ($request) = @_;
    my $admin = LedgerSMB::DBObject::Admin->new(%$request);
    $admin->delete_session();
    return list_sessions($request);
}

=back

=cut

# apply locale settings to column headings and add sort urls if necessary.
sub _column_heading {
    my $self = shift;
    my ($names, $sortby) = @_;
    my %sorturls;

    if ($sortby) {
        %sorturls = map
        { $_ => $sortby->{href}."=$_"} @{$sortby->{columns}};
    }

    foreach my $attname (keys %$names) {

        # process 2 cases - simple name => value, and complex name => hash
        # pairs. The latter is used to include urls in column headers.

        if (ref $names->{$attname} eq 'HASH') {
            my $t = $self->{_locale}->maketext($names->{$attname}{text});
            $names->{$attname}{text} = $t;
        } else {
            my $t = $self->{_locale}->maketext($names->{$attname});
            if (defined $sorturls{$attname}) {
                $names->{$attname} =
                {
                    text => $t,
                     href => $sorturls{$attname}
                };
            } else {
                $names->{$attname} = $t;
            }
        }
    }

    return $names;
}


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2010 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
