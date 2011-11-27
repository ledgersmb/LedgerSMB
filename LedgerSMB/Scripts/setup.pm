
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
use strict;

sub __default {

    my ($request) = @_;
    my $template = LedgerSMB::Template->new(
            path => 'UI/setup',
            template => 'credentials',
	    format => 'HTML',
    );
    $template->render($request);
}

=over

=item login

Processes the login and examines the database to determine appropriate steps to
take.

=cut

sub login {
    use LedgerSMB::Locale;
    my ($request) = @_;
    $request->{_locale}->new('en');
    my $creds = LedgerSMB::Auth::get_credentials();
    if (!$request->{database}){
        $request->error($request->{_locale}->text('No database specified'));
    }
    my $database = LedgerSMB::Database->new(
               {username => $creds->{login},
            company_name => $request->{database},
                password => $creds->{password}}
    );
    my $version_info = $database->get_info();
    $request->{login_name} = $version_info->{username};
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
         
         } elsif ($version_info->{version} eq '1.3') {
             $request->{message} = $request->{_locale}->text(
                 'LedgerSMB 1.3 found'   
             );
             $request->{operation} = $request->{_locale}->text(
                    'Rebuild/Upgrade?'
             );
             $request->{next_action} = 'rebuild_modules';
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
    my $template = LedgerSMB::Template->new(
            path => 'UI/setup',
            template => 'confirm_operation',
	    format => 'HTML',
    );
    $template->render($request);

}

=item backup_db

Backs up a full db

=cut

sub backup_db {
    my $request = shift @_;
    $request->{backup} = 'db';
    _begin_backup($request);
}

=item backup_roles

Backs up roles only (for all db's)

=cut

sub backup_roles {
    my $request = shift @_;
    $request->{backup} = 'roles';
    _begin_backup($request);
}

# Private method, basically just passes the inputs on to the next screen.
sub _begin_backup {
    my $request = shift @_;
    my $template = LedgerSMB::Template->new(
            path => 'UI/setup',
            template => 'begin_backup',
            format => 'HTML',
    );
    $template->render($request);
};


=item run_backup

Runs the backup.  If backup_type is set to email, emails the 

=cut

sub run_backup {
    use LedgerSMB::Company_Config;

    my $creds = LedgerSMB::Auth::get_credentials();
    my $request = shift @_;

    my $database = LedgerSMB::Database->new(
               {username => $creds->{login},
            company_name => $request->{database},
                password => $creds->{password}}
    );

    my $backupfile;
    my $mimetype;

    if ($request->{backup} eq 'roles'){
       $backupfile = $database->base_backup; 
       $mimetype   = 'text/x-sql';
    } elsif ($request->{backup} eq 'db'){
       $backupfile = $database->db_backup;
       $mimetype   = 'application/octet-stream';
    } else {
        $request->error($request->{_locale}->text('Invalid backup request'));
    }

    if ($request->{backup_type} eq 'email'){
        my $csettings = $LedgerSMB::Company_Config::settings;
	my $mail = new LedgerSMB::Mailer(
		from          => $csettings->{default_email_from},
		to            => $request->{email},
		subject       => "Email of Backup",
		message       => 'The Backup is Attached',
	);
	$mail->attach(
            mimetype => $mimetype,
            filename => $backupfile,
            file     => $backupfile,
	);
        $mail->send;
    } elsif ($request->{backup_type} eq 'browser'){
        open BAK, '<', $backupfile;
        my $cgi = CGI::Simple->new();
        $backupfile =~ s/$LedgerSMB::Sysconfig::backuppath(\/)?//;
        print $cgi->header(
          -type       => $mimetype,
          -status     => '200',
          -charset    => 'utf-8',
          -attachment => $backupfile,
        );
        my $data;
        while (read(BAK, $data, 1024 * 1024)){ # Read 1MB at a time
            print $data;
        }
        exit;
    } else {
        $request->error($request->{_locale}->text("Don't know what to do with backup"));
    }
    my $template = LedgerSMB::Template->new(
            path => 'UI/setup',
            template => 'complete',
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
               {username => $creds->{login},
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
               {username => $creds->{login},
            company_name => $request->{database},
                password => $creds->{password}}
    );

    # ENVIRONMENT NECESSARY
    $ENV{PGUSER} = $creds->{login};
    $ENV{PGPASSWORD} = $creds->{password};
    $ENV{PGDATABASE} = $request->{database};

    # Credentials set above via environment variables --CT
    $request->{dbh} = DBI->connect("dbi:Pg:dbname=$request->{database}");
    $request->{dbh}->{AutoCommit} = 0;
    my $locale = $request->{_locale};

    my @pre_upgrade_checks = (
       {query => "select id, customernumber, name, address1, city, state, zipcode
                   from customer where customernumber in (SELECT customernumber from customer
                   GROUP BY customernumber
                   HAVING count(*) > 1)",
         name => $locale->text('Unique Customernumber'),
         cols => ['customernumber', 'name', 'address1', 'city', 'state', 'zip'],
         edit => 'customernumber',
        table => 'customer'},

       {query => "SELECT id, vendornumber, name, address1, city, state, zipcode
                   FROM vendor WHERE vendornumber IN 
                   (SELECT vendornumber from vendor
                   GROUP BY vendornumber
                   HAVING count(*) > 1)",
         name => $locale->text('Unique Vendornumber'),
         cols => ['vendornumber', 'name', 'address1', 'city', 'state', 'zip'],
         edit => 'vendornumber',
        table => 'vendor'},

       {query => 'SELECT * FROM employee where employeenumber IS NULL',
         name => $locale->text('No null employeenumber'),
         cols => ['login', 'name', 'employeenumber'],
         edit => 'employeenumber',
        table => 'employee'},

       {query => 'SELECT * FROM employee 
                   WHERE employeenumber IN 
                         (SELECT employeenumber FROM employee 
                        GROUP BY employeenumber
                          HAVING count(*) > 1)',
         name => $locale->text('Duplicte employee numbers'),
         cols => ['login', 'name', 'employeenumber'],
         edit => 'employeenumber',
        table => 'employee'},

       {query => "select * from parts where obsolete is not true 
                  and partnumber in 
                  (select partnumber from parts 
                  WHERE obsolete is not true
                  group by partnumber having count(*) > 1)",
         name => $locale->text('Unique nonobsolete partnumbers'),
         cols => ['partnumber', 'description', 'sellprice'],
         edit => 'partnumber',
        table => 'parts'},

       {query => 'SELECT * from ar where invnumber in (
                   select invnumber from ar
                   group by invnumber having count(*) > 1)',
         name => $locale->text('Unique AR Invoice numbers'),
         cols =>  ['invnumber', 'transdate', 'amount', 'netamount', 'paid'],
         edit =>  'invnumber',
        table =>  'ar'},
    );
    for my $check (@pre_upgrade_checks){
        my $sth = $request->{dbh}->prepare($check->{query});
        $sth->execute();
        if ($sth->rows > 0){ # Check failed --CT
             _failed_check($request, $check, $sth);
        }
    }
    my $template = LedgerSMB::Template->new(
            path => 'UI/setup',
            template => 'upgrade_info',
            format => 'HTML',
    );
    $template->render($request);
    

}

sub _failed_check{
    my ($request, $check, $sth) = @_;
    my $template = LedgerSMB::Template->new(
            path => 'UI',
            template => 'form-dynatable',
            format => 'HTML',
    );
    my $rows = [];
    my $count = 1;
    my $hiddens = {table => $check->{table},
                    edit => $check->{edit},
                database => $request->{database}};
    my $header = {};
    for (@{$check->{cols}}){
        $header->{$_} = $_;
    }
    while (my $row = $sth->fetchrow_hashref('NAME_lc')){
          $row->{$check->{'edit'}} = 
                    { input => {
                                name => "$check->{edit}_$row->{id}",
                                value => $row->{$check->{'edit'}},
                                type => 'text',
                                size => 15,
                    },
          };
          push @$rows, $row;
          $hiddens->{"id_$count"} = $row->{id},
          ++$count;
    }
    $hiddens->{count} = $count;
    my $buttons = [
           { type => 'submit',
             name => 'action',
            value => 'fix_tests',
             text => $request->{_locale}->text('Save and Retry'),
            class => 'submit' },
    ];
    $template->render({
           form     => $request,
           heading  => $header,
           columns  => $check->{cols},
           rows     => $rows,
           hiddens  => $hiddens,
           buttons  => $buttons
    });
}

=item fix_tests

Handles input from the failed test function and then re-runs the migrate db 
script.

=cut

sub fix_tests{
    my ($request) = @_;
    my $creds = LedgerSMB::Auth::get_credentials();
    # ENVIRONMENT NECESSARY
    $ENV{PGUSER} = $creds->{login};
    $ENV{PGPASSWORD} = $creds->{password};
    $ENV{PGDATABASE} = $request->{database};

    # Credentials set above via environment variables --CT
    $request->{dbh} = DBI->connect("dbi:Pg:dbname=$request->{database}");
    $request->{dbh}->{AutoCommit} = 0;
    my $locale = $request->{_locale};

    my $table = $request->{dbh}->quote_identifier($request->{table});
    my $edit = $request->{dbh}->quote_identifier($request->{edit});
    my $sth = $request->{dbh}->prepare(
            "UPDATE $table SET $edit = ? where id = ?"
    );
    
    for my $count (1 .. $request->{count}){
        my $id = $request->{"id_$count"};
        $sth->execute($request->{"$request->{edit}_$id"}, $id) ||
            $request->error($sth->errstr);
    }
    $request->{dbh}->commit;
    upgrade($request);
}

=item create_db

 Beginning of the new database workflow

=cut

sub create_db{
    use LedgerSMB::Sysconfig;
    my ($request) = @_;
    my $creds = LedgerSMB::Auth::get_credentials();


    # ENVIRONMENT NECESSARY
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

    #COA Directories
    opendir(COA, 'sql/coa');
    my @coa = grep !/^(\.|[Ss]ample.*)/, readdir(COA);
    closedir(COA); 

    $request->{coa_lcs} =[];
    foreach my $lcs (sort @coa){
         push @{$request->{coa_lcs}}, {code => $lcs};
    } 

    my $template = LedgerSMB::Template->new(
            path => 'UI/setup',
            template => 'select_coa',
	    format => 'HTML',
    );
    $template->render($request);
    
}

=item select_coa

Selects and loads the COA.

There are three distinct input scenarios here:

coa_lc and chart are set:  load the coa file specified (sql/coa/$coa_lc/$chart)
coa_lc set, chart not set:  select the chart
coa_lc not set:  Select the coa location code

=cut

sub select_coa {
    use LedgerSMB::Sysconfig;
    use DBI;
    my ($request) = @_;

    if ($request->{coa_lc} =~ /\.\./){
       $request->error($request->{_locale}->text('Access Denied'));
    }
    if ($request->{coa_lc}){
        if ($request->{chart}){
           my $creds = LedgerSMB::Auth::get_credentials();
       
           # ENVIRONMENT NECESSARY
           $ENV{PGUSER} = $creds->{login};
           $ENV{PGPASSWORD} = $creds->{password};
           $ENV{PGDATABASE} = $request->{database};

           my $database = LedgerSMB::Database->new(
                      {username => $creds->{login},
                   company_name => $request->{database},
                       password => $creds->{password}}
           );
           my $logfile = $LedgerSMB::tempdir . "/dblog";

           $database->exec_script(
                    {script => "sql/coa/$request->{coa_lc}/chart/$request->{chart}", 
                    logfile => $logfile}
           );
           if (-f "sql/coa/$request->{coa_lc}/gifi/$request->{chart}"){
                 $database->exec_script(
                    {script => "sql/coa/$request->{coa_lc}/gifi/$request->{chart}",
                    logfile => $logfile}
                );
            }


            # One thing to remember here is that the setup.pl does not get the
            # benefit of the automatic db connection.  So in order to build this
            # form, we have to manage that ourselves. 
            #
            # However we get the benefit of having had to set the environment
            # variables for the Pg connection above, so don't need to pass much
            # info. 
            #
            # Also I am opting to use the lower-level call_procedure interface
            # here in order to avoid creating objects just to get argument
            # mapping going. --CT

            $request->{dbh} = DBI->connect("dbi:Pg:dbname=$request->{database}");
            $request->{dbh}->{AutoCommit} = 0;

           @{$request->{salutations}} 
            = $request->call_procedure(procname => 'person__list_salutations' ); 
          
           @{$request->{countries}} 
            = $request->call_procedure(procname => 'location_list_country' ); 

           my $locale = $request->{_locale};

           @{$request->{perm_sets}} = (
               {id => '0', label => $locale->text('Manage Users')},
               {id => '1', label => $locale->text('Full Permissions')},
           );

           my $template = LedgerSMB::Template->new(
                   path => 'UI/setup',
                   template => 'new_user',
	           format => 'HTML',
           );
           $template->render($request);
        } else {
            opendir(COA, "sql/coa/$request->{coa_lc}/chart");
            my @coa = sort (grep !/^(\.|[Ss]ample.*)/, readdir(COA));
            $request->{charts} = [];
            for my $chart (sort @coa){
                push @{$request->{charts}}, {name => $chart};
            }
       }
    } else {
        #COA Directories
        opendir(COA, 'sql/coa');
        my @coa = sort(grep !/^(\.|[Ss]ample.*)/, readdir(COA));
        closedir(COA); 

        $request->{coa_lcs} =[];
        foreach my $lcs (sort {$a cmp $b} @coa){
             push @{$request->{coa_lcs}}, {code => $lcs};
        } 
    }
    my $template = LedgerSMB::Template->new(
            path => 'UI/setup',
            template => 'select_coa',
	    format => 'HTML',
    );
    $template->render($request);
}

=item save_user

Saves the administrative user, and then directs to the login page.

=cut

sub save_user {
    use LedgerSMB::DBObject::Admin;
    my ($request) = @_;
    my $creds = LedgerSMB::Auth::get_credentials();
    $request->{dbh} = DBI->connect("dbi:Pg:dbname=$request->{database}",
                                   $creds->{login},
                                   $creds->{password});
    $request->{dbh}->{AutoCommit} = 0;
    my $user = LedgerSMB::DBObject::Admin->new({base => $request});
    if (8 == $user->save_user){ # Told not to import but user exists in db
        $request->{notice} = $request->{_locale}->text(
                       'User already exists. Import?'
        );


       @{$request->{salutations}} 
        = $request->call_procedure(procname => 'person__list_salutations' ); 
          
       @{$request->{countries}} 
        = $request->call_procedure(procname => 'location_list_country' ); 

       my $locale = $request->{_locale};

       @{$request->{perm_sets}} = (
           {id => '0', label => $locale->text('Manage Users')},
           {id => '1', label => $locale->text('Full Permissions')},
       );
        my $template = LedgerSMB::Template->new(
                path => 'UI/setup',
                template => 'new_user',
         format => 'HTML',
        );
        $template->render($request);
        exit;        
    }
    if ($request->{perms} == 1){
         for my $role (
                $request->call_procedure(procname => 'admin__get_roles')
         ){
             $request->call_procedure(procname => 'admin__add_user_to_role',
                                      args => [ $request->{username}, 
                                                $role->{rolname}
                                              ]);
         }
    } elsif ($request->{perms} == 0) {
        $request->call_procedure(procname => 'admin__add_user_to_role',
                                 args => [ $request->{username},
                                           "lsmb_$request->{database}__".
                                            "users_manage",
                                         ]
        );
    } else {
        $request->error($request->{_locale}->text('No Permissions Assigned'));
   }
   $request->{dbh}->commit;
   
    my $template = LedgerSMB::Template->new(
            path => 'UI/setup',
            template => 'complete',
	    format => 'HTML',
    );
    $template->render($request);
}

=item run_upgrade

Runs the actual upgrade script.

=cut

sub run_upgrade {
    my ($request) = @_;
    my $creds = LedgerSMB::Auth::get_credentials();
    my $database = LedgerSMB::Database->new(
               {username => $creds->{login},
            company_name => $request->{database},
                password => $creds->{password}}
    );

    # ENVIRONMENT NECESSARY
    $ENV{PGUSER} = $creds->{login};
    $ENV{PGPASSWORD} = $creds->{password};
    $ENV{PGDATABASE} = $request->{database};

    # Credentials set above via environment variables --CT
    $request->{dbh} = DBI->connect("dbi:Pg:dbname=$request->{database}");
    my $dbh = $request->{dbh};
    $dbh->do('ALTER SCHEMA public RENAME TO lsmb12');
    $dbh->do('CREATE SCHEMA PUBLIC');

    $database->load_modules('LOADORDER');
    $database->process_roles('Roles.sql');
    my $dbtemplate = LedgerSMB::Template->new(
        user => {}, 
        path => 'sql/upgrade',
        template => '1.2-1.3',
        no_auto_output => 1,
        format_options => {extension => 'sql'},
        output_file => '1.2-1.3-upgrade',
        format => 'TXT' );
    $dbtemplate->render($request);
    $rc2 = system("psql -f $temp/1.2-1.3-upgrade.sql >> $temp/dblog_stdout 2>>$temp/dblog_stderr");
    $rc ||= $rc2;

    $request->{dbh} = DBI->connect("dbi:Pg:dbname=$request->{database}");

   @{$request->{salutations}} 
    = $request->call_procedure(procname => 'person__list_salutations' ); 
          
   @{$request->{countries}} 
    = $request->call_procedure(procname => 'location_list_country' ); 

   my $locale = $request->{_locale};

   @{$request->{perm_sets}} = (
       {id => '0', label => $locale->text('Manage Users')},
       {id => '1', label => $locale->text('Full Permissions')},
   );
    my $template = LedgerSMB::Template->new(
                   path => 'UI/setup',
                   template => 'new_user',
                   format => 'HTML',
     );
     $template->render($request);
}

=item cancel

Cancels work.  Returns to login screen.

=cut
sub cancel{
    __default(@_);
}

=item rebuild_modules

This method rebuilds the modules and sets the version setting in the defaults
table to the version of the LedgerSMB request object.  This is used when moving
between versions on a stable branch (typically upgrading)

=cut

sub rebuild_modules {
    my ($request) = @_;
    my $creds = LedgerSMB::Auth::get_credentials();
    my $database = LedgerSMB::Database->new(
               {username => $creds->{login},
            company_name => $request->{database},
                password => $creds->{password}}
    );

    # ENVIRONMENT NECESSARY
    $ENV{PGUSER} = $creds->{login};
    $ENV{PGPASSWORD} = $creds->{password};
    $ENV{PGDATABASE} = $request->{database};
    
    $database->load_modules('LOADORDER');
    $database->process_roles('Roles.sql');
    # Credentials set above via environment variables --CT
    $request->{dbh} = DBI->connect("dbi:Pg:dbname=$request->{database}");
    my $dbh = $request->{dbh};
    my $sth = $dbh->prepare(
          'UPDATE defaults SET value = ? WHERE setting_key = ?'
    );
    $sth->execute($request->{dbversion}, 'version');
    $sth->finish;
    $dbh->commit;
    $dbh->disconnect;
    my $template = LedgerSMB::Template->new(
            path => 'UI/setup',
            template => 'complete',
            format => 'HTML',
    );
    $template->render($request);

}

=back

=head1 COPYRIGHT

Copyright (C) 2011 LedgerSMB Core Team.  This file is licensed under the GNU 
General Public License version 2, or at your option any later version.  Please
see the included License.txt for details.

=cut


1;
