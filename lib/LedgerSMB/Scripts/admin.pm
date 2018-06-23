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
    my $column_heading = _column_heading($request, $column_names);
    my $rows = [];
    my $rowcount = '0';
    my $base_url = 'admin.pl?action=delete_session';
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
    return $template->render({
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

Copyright (C) 2010 LedgerSMB Core Team.  This file is licensed under the GNU
General Public License version 2, or at your option any later version.  Please
see the included License.txt for details.

=cut


1;
