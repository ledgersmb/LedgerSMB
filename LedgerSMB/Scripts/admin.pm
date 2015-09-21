package LedgerSMB::Scripts::admin;

use strict;
use warnings;

=pod

=head1 NAME

LedgerSMB:Scripts::admin

=head1 SYNOPSIS

This module provides the workflow scripts for managing users and permissions.

=head1 METHODS

=over

=cut

use LedgerSMB::Template;
use LedgerSMB::DBObject::Admin;
use LedgerSMB::DBObject::User;
use LedgerSMB::Setting;
use Log::Log4perl;

# I don't really like the code in this module.  The callbacks are per form which
# means there is no semantic difference between different buttons that can be
# clicked.  This results in a lot of code with a lot of conditionals which is
# both difficult to read and maintain.  In the future, this should be revisited
# and rewritten.  It makes the module too closely tied to the HTML.  --CT

my $logger = Log::Log4perl->get_logger('LedgerSMB::Scripts::admin');


sub __edit_page {


    my ($request, $otd) = @_;
    # otd stands for Other Template Data.
    my $dcsetting = LedgerSMB::Setting->new( {base=>$request, copy=>'base'} );
    my $default_country = $dcsetting->get('default_country');
    my $admin = LedgerSMB::DBObject::Admin->new({base=>$request, copy=>'list', merge =>['user_id']});
    my @all_roles = $admin->get_roles($request->{company});
    my $user_obj = LedgerSMB::DBObject::User->new({base=>$request, copy=>'list', merge=>['user_id','company']});
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
    my @countries = $admin->get_countries();
    my @salutations = $admin->get_salutations();
    my $template_data =
            {
                           user => $user_obj,
                          roles => @all_roles,
                      countries => $admin->get_countries(),
                     user_roles => $user_obj->{roles},
                default_country => $dcsetting->{value},
                          admin => $admin,
                     stylesheet => $request->{stylesheet},
                    salutations => \@salutations,
            };


    for my $key (keys(%{$otd})) {

        $template_data->{$key} = $otd->{$key};
    }
    $template->render($template_data);
}

=item save_roles

Saves the role assignments for a given user

=cut

sub save_roles {
    my ($request, $admin) = @_;
    $admin = LedgerSMB::DBObject::Admin->new({base=>$request, copy=>'all'});
    $admin->{stylesheet} = $request->{stylesheet};
    $admin->save_roles();
    __edit_page($admin);
}

=item delete_user

Deletes a user and returns to search results.

=cut

sub delete_user {
    my ($request) = @_;
    my $admin = LedgerSMB::DBObject::Admin->new({base => $request});
    $admin->delete_user($request->{delete_user});
    delete $request->{username};
    search_users($request);
}

=item list_sessions

Displays a list of open sessions.  No inputs required or used.

=cut

sub list_sessions {
    my ($request) = @_;
    my $admin = LedgerSMB::DBObject::Admin->new({base => $request});
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
    my $admin = LedgerSMB::DBObject::Admin->new({base => $request});
    $admin->delete_session();
    list_sessions($request);
}

###TODO-LOCALIZE-DOLLAR-AT
eval { do "scripts/custom/admin.pl"};

=back

=head1 COPYRIGHT

Copyright (C) 2010 LedgerSMB Core Team.  This file is licensed under the GNU
General Public License version 2, or at your option any later version.  Please
see the included License.txt for details.

=cut


1;
