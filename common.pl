#
######################################################################
# LedgerSMB Accounting and ERP

# http://www.ledgersmb.org/
#
# Copyright (C) 2006
# This work contains copyrighted information from a number of sources all used
# with permission.
#
# This file contains source code included with or based on SQL-Ledger which
# is Copyright Dieter Simader and DWS Systems Inc. 2000-2005 and licensed
# under the GNU General Public License version 2 or, at your option, any later
# version.  For a full list including contact information of contributors,
# maintainers, and copyright holders, see the CONTRIBUTORS file.
#
#####################################################################
#
# Common script handling routines for menu.pl, admin.pl, login.pl
#
#####################################################################

use LedgerSMB::Sysconfig;

sub redirect {
    use List::Util qw(first);

    my ( $script, $argv ) = split( /\?/, $form->{callback} );

    my @common_attrs = qw(
      dbh login favicon stylesheet titlebar password custom_db_fields vc header
    );

    if ( !$script ) {    # http redirect to login.pl if called w/no args
        print "Location: login.pl\n";
        print "Content-type: text/html\n\n";
        return;
    }
    if (first { $_ eq $script } @{LedgerSMB::Sysconfig::newscripts}){
        print "Location: $form->{callback}\n";
        print "Content-type: text/html\n\n";
        return;
    }
    $form->error(
        $locale->text(
            __FILE__ . ':' . __LINE__ . ':' . $script . ':' . "Invalid Redirect"
        )
    ) unless first { $_ eq $script } @{LedgerSMB::Sysconfig::scripts};

    my %temphash;
    for (@common_attrs) {
        $temphash{$_} = $form->{$_};
    }
    $temphash{action} = $form->{action};

    undef $form;
    $form = new Form($argv);

    for (@common_attrs) {
        $form->{$_} = $temphash{$_};
    }
    $form->{action} ||= $temphash{action}; # default to old action if not set

    $form->{script} = $script;

    if ( !%myconfig ) {    # needed for login
        %myconfig = %{ LedgerSMB::User->fetch_config( $form ) };
    }
    if ( !$form->{dbh} and ( $script ne 'admin.pl' ) ) {
        $form->db_init( \%myconfig );
    }

    require "bin/$script";

    &{ $form->{action} };

}

1;
