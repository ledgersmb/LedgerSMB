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

use Locale::Country;
use LedgerSMB::Auth;
use LedgerSMB::Database;
use LedgerSMB::App_State;
use LedgerSMB::Upgrade_Tests;
use strict;

my $logger = Log::Log4perl->get_logger('LedgerSMB::Scripts::setup');

sub _set_dbh {
    my ($dbh) = @_;
    $LedgerSMB::App_State::DBH=$dbh;
}

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
    $logger->trace("\$request=$request \$request->{dbh}=$request->{dbh} request=".Data::Dumper::Dumper(\$request));
    my $creds = LedgerSMB::Auth::get_credentials('setup');
    if (!$request->{database}){
        $request->error($request->{_locale}->text('No database specified'));
    }
    my $database = LedgerSMB::Database->new(
               {username => $creds->{login},
            company_name => $request->{database},
                password => $creds->{password}}
    );
    my $server_info = $database->server_version;
    
    my $version_info = $database->get_info();
    if(!$request->{dbh}){$request->{dbh}=$database->{dbh};}#allow upper stack to disconnect dbh when leaving
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
         
         } elsif ($version_info->{version} eq '1.4') {
             $request->{message} = $request->{_locale}->text(
                 'LedgerSMB 1.4 found'   
             );
             $request->{operation} = $request->{_locale}->text(
                    'Rebuild/Upgrade?'
             );
             $request->{next_action} = 'rebuild_modules';
         } elsif ($version_info->{version} eq '1.3') {
             $request->{message} = $request->{_locale}->text(
                 'LedgerSMB 1.3 found'   
             );
             $request->{operation} = $request->{_locale}->text(
                    'Upgrade?'
             );
             $request->{next_action} = 'upgrade';
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

    my $creds = LedgerSMB::Auth::get_credentials('setup');
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

    $backupfile or $request->error($request->{_locale}->text('Error creating backup file'));

    if ($request->{backup_type} eq 'email'){
        my $csettings = $LedgerSMB::Company_Config::settings;
	my $mail = new LedgerSMB::Mailer(
		from          => $LedgerSMB::Sysconfig::backup_email_from,
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
        unlink $backupfile;
        my $template = LedgerSMB::Template->new(
            path => 'UI/setup',
            template => 'complete',
            format => 'HTML',
        );
        $template->render($request);
    } elsif ($request->{backup_type} eq 'browser'){
        binmode(STDOUT, ':bytes');
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
        unlink $backupfile;
    } else {
        $request->error($request->{_locale}->text("Don't know what to do with backup"));
    }
 
}
   

=item migrate_sl

Beginning of an SQL-Ledger 2.7/2.8 migration.

=cut

sub migrate_sl{
    my ($request) = @_;
    my $creds = LedgerSMB::Auth::get_credentials('setup');
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
    _set_dbh($dbh);
    $dbh->do('ALTER SCHEMA public RENAME TO sl28');
    $dbh->do('CREATE SCHEMA PUBLIC');
    # Copying contrib script loading for now
    my $rc = 0;
    my $temp = $LedgerSMB::Sysconfig::tempdir;
     my @contrib_scripts = qw(tsearch2 tablefunc);

     for my $contrib (@contrib_scripts){
         my $rc2;
         $rc2=system("psql -f $ENV{PG_CONTRIB_DIR}/$contrib.sql >> $temp/dblog_stdout 2>>$temp/dblog_stderr");
         $rc ||= $rc2
     }
     my $rc2 = system("psql -f sql/Pg-database.sql >> $temp/dblog_stdout 2>>$temp/dblog_stderr");
     
     $rc ||= $rc2;

    $database->load_modules('LOADORDER');
    $database->process_roles('Roles.sql');
    my $dbtemplate = LedgerSMB::Template->new(
        user => {}, 
        path => 'sql/upgrade',
        template => 'sl2.8-1.3',
        no_auto_output => 1,
        format_options => {extension => 'sql'},
        output_file => 'sl2.8-1.3-upgrade',
        format => 'TXT' );
    $dbtemplate->render($request);
    $rc2 = system("psql -f $temp/sl2.8-1.3-upgrade.sql >> $temp/dblog_stdout 2>>$temp/dblog_stderr");
    $rc ||= $rc2;

    $request->{dbh} = DBI->connect("dbi:Pg:dbname=$request->{database}");
    _set_dbh($request->{dbh});

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

=item _get_linked_accounts

Returns an array of hashrefs with keys ('id', 'accno', 'desc') identifying
the accounts.

Assumes a connected database.

=cut

sub _get_linked_accounts {
    my ($request, $link) = @_;
    my @accounts;

    my $sth = $request->{dbh}->prepare("select id, accno, description
                                          from chart
                                         where link = '$link'");
    $sth->execute();
    while (my $row = $sth->fetchrow_hashref('NAME_lc')) {
        push @accounts, { accno => $row->{accno},
                          desc => "$row->{accno} - $row->{description}",
                          id => $row->{id}
        };
    }

    return @accounts;
}


=item upgrade 

Beginning of the upgrade from 1.2 logic

=cut

sub upgrade{
    my ($request) = @_;
    my $creds = LedgerSMB::Auth::get_credentials('setup');
    my $database = LedgerSMB::Database->new(
               {username => $creds->{login},
            company_name => $request->{database},
                password => $creds->{password}}
    );
    my $dbinfo = $database->get_info();

    # ENVIRONMENT NECESSARY
    $ENV{PGUSER} = $creds->{login};
    $ENV{PGPASSWORD} = $creds->{password};
    $ENV{PGDATABASE} = $request->{database};

    # Credentials set above via environment variables --CT
    $request->{dbh} = DBI->connect("dbi:Pg:dbname=$request->{database}");
    _set_dbh($request->{dbh});
    $request->{dbh}->{AutoCommit} = 0;
    my $locale = $request->{_locale};

    for my $check (LedgerSMB::Upgrade_Tests->get_tests()){
        next if ($check->min_version lt $dbinfo->{version}) or 
                ($check->max_version gt $dbinfo->{version});
        my $sth = $request->{dbh}->prepare($check->test_query);
        $sth->execute();
        if ($sth->rows > 0){ # Check failed --CT
             _failed_check($request, $check, $sth);
             return;
        }
    }

    @{$request->{ar_accounts}} = _get_linked_accounts($request, "AR");
    @{$request->{ap_accounts}} = _get_linked_accounts($request, "AP");
    unshift @{$request->{ar_accounts}}, {};
    unshift @{$request->{ap_accounts}}, {};

    @{$request->{countries}} = ();
    foreach my $iso2 (all_country_codes()) {
        push @{$request->{countries}}, { code    => uc($iso2),
                                         country => code2country($iso2) };
    }
    @{$request->{countries}} =
        sort { $a->{country} cmp $b->{country} } @{$request->{countries}};
    unshift @{$request->{countries}}, {};


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
    for (@{$check->display_cols}){
        $header->{$_} = $_;
    }
    while (my $row = $sth->fetchrow_hashref('NAME_lc')){
          warn $check;
          $row->{$check->column} = 
                    { input => {
                                name => $check->column . "_$row->{id}",
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
    $hiddens->{edit} = $check->column;
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
           columns  => $check->display_cols,
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
    my $creds = LedgerSMB::Auth::get_credentials('setup');
    # ENVIRONMENT NECESSARY
    $ENV{PGUSER} = $creds->{login};
    $ENV{PGPASSWORD} = $creds->{password};
    $ENV{PGDATABASE} = $request->{database};

    # Credentials set above via environment variables --CT
    $request->{dbh} = DBI->connect("dbi:Pg:dbname=$request->{database}");
    _set_dbh($request->{dbh});
    $request->{dbh}->{AutoCommit} = 0;
    my $locale = $request->{_locale};

    my $table = $request->{dbh}->quote_identifier($request->{table});
    my $edit = $request->{dbh}->quote_identifier($request->{edit});
    my $sth = $request->{dbh}->prepare(
            "UPDATE $table SET $edit = ? where id = ?"
    );
    
    for my $count (1 .. $request->{count}){
        warn $count;
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
    my $creds = LedgerSMB::Auth::get_credentials('setup');
    my $rc=0;


    # ENVIRONMENT NECESSARY
    $ENV{PGUSER} = $creds->{login};
    $ENV{PGPASSWORD} = $creds->{password};
    $ENV{PGDATABASE} = $request->{database};

    my $database = LedgerSMB::Database->new(
               {username => $creds->{login},
            company_name => $request->{database},
                password => $creds->{password}}
    );
    $rc=$database->create_and_load();#TODO what if createdb fails?
    $logger->info("create_and_load rc=$rc");
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
           _render_new_user($request);
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
    _render_new_user($request);
}


=item skip_coa

Entry point when on the CoA selection screen the 'Skip' button
is being pressed.  This allows the user to load a CoA later.

The CoA loaded at a later time may be a self-defined CoA, i.e. not
one distributed with the LSMB standard distribution.  The 'Skip'
button facilitates that scenario.

=cut

sub skip_coa {
    my ($request) = @_;

    _render_new_user($request);
}


=item _render_new_user

Renders the new user screen. Common functionality to both the
select_coa and skip_coa functions.

=cut

sub _render_new_user {
    my ($request) = @_;

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

    my $creds = LedgerSMB::Auth::get_credentials('setup');
    
    # ENVIRONMENT NECESSARY
    $ENV{PGUSER} = $creds->{login};
    $ENV{PGPASSWORD} = $creds->{password};
    $ENV{PGDATABASE} = $request->{database};




    $request->{dbh} = DBI->connect("dbi:Pg:dbname=$request->{database}");
    _set_dbh($request->{dbh});
    $request->{dbh}->{AutoCommit} = 0;

    @{$request->{salutations}} 
    = $request->call_procedure(procname => 'person__list_salutations' ); 
    
    @{$request->{countries}} 
    = $request->call_procedure(procname => 'location_list_country' ); 
    for my $country (@{$request->{countries}}){
        if (lc($request->{coa_lc}) eq lc($country->{short_name})){
           $request->{country_id} = $country->{id};
        }
    }
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



=item save_user

Saves the administrative user, and then directs to the login page.

=cut

sub save_user {
    my ($request) = @_;
    $request->{entity_class} = 3;
    $request->{name} = "$request->{last_name}, $request->{first_name}";
    use LedgerSMB::Entity::Person::Employee;
    use LedgerSMB::Entity::User;
    use LedgerSMB::PGDate;
    my $creds = LedgerSMB::Auth::get_credentials('setup');
    $request->{dbh} = DBI->connect("dbi:Pg:dbname=$request->{database}",
                                   $creds->{login},
                                   $creds->{password});
    _set_dbh($request->{dbh});
    $request->{dbh}->{AutoCommit} = 0;
    $LedgerSMB::App_State::DBH = $request->{dbh};
    $request->{control_code} = $request->{employeenumber};
    $request->{dob} = LedgerSMB::PGDate->from_input($request->{dob});
    my $emp = LedgerSMB::Entity::Person::Employee->new(%$request);
    $emp->save;
    $request->{entity_id} = $emp->entity_id;
    my $user = LedgerSMB::Entity::User->new(%$request);
    if (8 == $user->create){ # Told not to import but user exists in db
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
        return;
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

   rebuild_modules($request);
   
}

=item run_upgrade

Runs the actual upgrade script.

=cut

sub run_upgrade {
    my ($request) = @_;
    my $creds = LedgerSMB::Auth::get_credentials('setup');
    my $database = LedgerSMB::Database->new(
               {username => $creds->{login},
            company_name => $request->{database},
                password => $creds->{password}}
    );
    my $rc;
    my $rc2;
    my $temp = $LedgerSMB::Sysconfig::tempdir;

    # ENVIRONMENT NECESSARY
    $ENV{PGUSER} = $creds->{login};
    $ENV{PGPASSWORD} = $creds->{password};
    $ENV{PGDATABASE} = $request->{database};

    # Credentials set above via environment variables --CT
    $request->{dbh} = DBI->connect("dbi:Pg:dbname=$request->{database}");
    _set_dbh($request->{dbh});
    my $dbh = $request->{dbh};
    my $dbinfo = $database->get_info();
    $dbh->do('ALTER SCHEMA public RENAME TO lsmb12');
    $dbh->do('CREATE SCHEMA PUBLIC');
    $database->exec_script({script => "$database->{source_dir}sql/Pg-database.sql",
                            log    => "$temp/dblog"});
    $database->load_modules('LOADORDER');
    $database->process_roles('Roles.sql');
    my $dbtemplate = LedgerSMB::Template->new(
        user => {}, 
        path => 'sql/upgrade',
        template => "$dbinfo->{version}-1.4",
        no_auto_output => 1,
        format_options => {extension => 'sql'},
        output_file => 'to_1.4-upgrade',
        format => 'TXT' );
    $dbtemplate->render($request);
    $rc2 = system("psql -f $temp/to_1.4-upgrade.sql >> $temp/dblog_stdout 2>>$temp/dblog_stderr");
    $rc ||= $rc2;

    $request->{dbh} = DBI->connect("dbi:Pg:dbname=$request->{database}");
    _set_dbh($request->{dbh});

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
    my $creds = LedgerSMB::Auth::get_credentials('setup');
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
    #avoid msg commit ineffective with AutoCommit enabled
    $request->{dbh} = DBI->connect("dbi:Pg:dbname=$request->{database}",$creds->{login},$creds->{password},{AutoCommit=>0});
    _set_dbh($request->{dbh});
    my $dbh = $request->{dbh};
    my $sth = $dbh->prepare(
          'UPDATE defaults SET value = ? WHERE setting_key = ?'
    );
    $sth->execute($request->{dbversion}, 'version');
    $sth->finish;
    $dbh->commit;
    #$dbh->disconnect;#upper stack will disconnect
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
