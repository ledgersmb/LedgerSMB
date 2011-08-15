
=head1 NAME

LedgerSMB::Scripts::setup

=head1 SYNOPSIS

The workflows for creating new databases, updating old ones, and running
management tasks.

=head1 METHODS

=cut

# DEVELOPER NOTES:
# This script currently is required to maintain all its own database connections
# for the reason that the database logic is fairly complex.  Most of the time
# these are maintained inside the LedgerSMB::Database package.
#
package LedgerSMB::Scripts::setup;

use LedgerSMB::Auth;
use LedgerSMB::Database;

sub __default {

    my ($request) = @_;
    $template = LedgerSMB::Template->new(
            path => 'UI/setup',
            template => 'credentials',
	    format => 'HTML',
    );
    $template->render($request);
}

=item login

Processes the login and examines the database to determine appropriate steps to
take.

=cut

sub login {
    use LedgerSMB::Locale;
    my ($request) = @_;
    $request->{_locale}->new('en');
    my $creds = LedgerSMB::Auth::get_credentials();
    my $database = LedgerSMB::Database->new(
               {username => $creds->{username},
            company_name => $request->{database},
                password => $creds->{password}}
    );
    my $version_info = $database->get_info();
    if ($version_info->{appname} eq 'sql-ledger'){
         $request->{message} = 
             $request->{_locale}->text("SQL-Ledger database detected.");
         if ($version_info->{version} =~ /^2\.[78]$/){
             $request->{operation} = $request->{_locale}->text(
                           "Would you like to migrate the database?"
                );
                $request->{next_action} = 'migrate_sl';
         } else {
             $request->{operation} = $request->{_locale}->text(
                           "Unsupported version.  Cancel?"
                );
                $request->{next_action} = 'cancel';
         }
    } elsif ($version_info->{appname} eq 'ledgersmb'){
         if ($version_info->{version} eq '1.2'){
            $request->{message} =
               $request->{_locale}->text("LedgerSMB 1.2 db found");
            $request->{operation} = $request->{_locale}->text(
                "Would you like to upgrade the database?"
            );
            $request->{next_action} = 'upgrade';
         } elsif ($version_info->{version} eq '1.3dev'){
            $request->{message} = $request->{_locale}->text(
                 'Development version found.  Please upgrade first'
            );
            $request->{operation} = $request->{_locale}->text('Cancel?');
            $request->{next_action} = 'cancel';
         } elsif ($version_info->{version} eq 'legacy'){
            $request->{message} = $request->{_locale}->text(
                 'Legacy version found.  Please upgrade first'
            );
            $request->{operation} = $request->{_locale}->text('Cancel?');
            $request->{next_action} = 'cancel';
            
         } else {
            $request->{message} = $request->{_locale}->text(
                 'Unknown version found.'
            );
            $request->{operation} = $request->{_locale}->text('Cancel?');
            $request->{next_action} = 'cancel';
         }
    } elsif (!$version_info->{exists}){
        $request->{message} = $request->{_locale}->text(
             'Database does not exist.');
        $request->{operation} = $request->{_locale}->text('Create Database?');
        $request->{next_action} = 'create_db';
    } else {
        $request->{message} = $request->{_locale}->text(
             'Unknown database found.'
        );
        $request->{operation} = $request->{_locale}->text('Cancel?');
        $request->{next_action} = 'cancel';
    }
    $template = LedgerSMB::Template->new(
            path => 'UI/setup',
            template => 'confirm_operation',
	    format => 'HTML',
    );
    $template->render($request);

}

=item migrate_sl

Beginning of an SQL-Ledger 2.7/2.8 migration.

=cut

sub migrate_sl{
    my ($request) = @_;
    my $creds = LedgerSMB::Auth::get_credentials();
    my $database = LedgerSMB::Database->new(
               {username => $creds->{username},
            company_name => $request->{database},
                password => $creds->{password}}
    );
}

=item upgrade 

Beginning of the upgrade from 1.2 logic

=cut

sub upgrade{
    my ($request) = @_;
    my $creds = LedgerSMB::Auth::get_credentials();
    my $database = LedgerSMB::Database->new(
               {username => $creds->{username},
            company_name => $request->{database},
                password => $creds->{password}}
    );
}

=item create_db

 Beginning of the new database workflow

=cut

sub create_db{
    use LedgerSMB::Sysconfig;
    my ($request) = @_;
    my $creds = LedgerSMB::Auth::get_credentials();
    $ENV{PGUSER} = $creds->{login};
    $ENV{PGPASSWORD} = $creds->{password};
    $ENV{PGDATABASE} = $request->{database};
    my $database = LedgerSMB::Database->new(
               {username => $creds->{login},
            company_name => $request->{database},
                password => $creds->{password}}
    );
    $database->create_and_load();
    $database->process_roles('Roles.sql');
    $template = LedgerSMB::Template->new(
            path => 'UI/setup',
            template => 'select_coa',
	    format => 'HTML',
    );
    $template->render($request);
    
}

=item cancel

Cancels work.  If the confirm is set to no, returns to the credential screen

=cut
sub cancel{
}

=back

=head1 COPYRIGHT

Copyright (C) 2011 LedgerSMB Core Team.  This file is licensed under the GNU 
General Public License version 2, or at your option any later version.  Please
see the included License.txt for details.

=cut


1;
