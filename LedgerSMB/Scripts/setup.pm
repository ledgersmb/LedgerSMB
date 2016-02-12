=head1 NAME

LedgerSMB::Scripts::setup

=head1 SYNOPSIS

The workflows for creating new databases, updating old ones, and running
management tasks.

=head1 METHODS

=over

=cut

# DEVELOPER NOTES:
# This script currently is required to maintain all its own database connections
# for the reason that the database logic is fairly complex.  Most of the time
# these are maintained inside the LedgerSMB::Database package.
#
package LedgerSMB::Scripts::setup;

use strict;
use warnings;

use Locale::Country;
use LedgerSMB::Auth;
use LedgerSMB::Database;
use LedgerSMB::DBObject::Admin;
use LedgerSMB::DBObject::User;
use LedgerSMB::App_State;
use LedgerSMB::Upgrade_Tests;
use LedgerSMB::Sysconfig;
use LedgerSMB::Template::DB;
use LedgerSMB::Setting;
use Try::Tiny;

my $logger = Log::Log4perl->get_logger('LedgerSMB::Scripts::setup');

=item no_db

Existence of this sub causes requests passed to this module /not/ to be
pre-connected to the database.

=cut

sub no_db {
    return 1;
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

sub _get_database {
    my ($request) = @_;
    my $creds = LedgerSMB::Auth::get_credentials('setup');

    return LedgerSMB::Database->new(
                username => $creds->{login},
                password => $creds->{password},
                  dbname => $request->{database},
    );
}


sub _init_db {
    my ($request) = @_;
    my $database = _get_database($request);
    local $@;
    $request->{dbh} = eval {
        $database->connect({PrintError => 0, AutoCommit => 0 })
    } if ! defined $request->{dbh};
    $LedgerSMB::App_State::DBH = $request->{dbh};

    return $database;
}

=item login

Processes the login and examines the database to determine appropriate steps to
take.

=cut

my @login_actions_dispatch_table =
    ( { appname => 'sql-ledger',
        version => '2.7',
        message => "SQL-Ledger database detected.",
        operation => "Would you like to migrate the database?",
        next_action => 'upgrade' },
      { appname => 'sql-ledger',
        version => '2.8',
        message => "SQL-Ledger database detected.",
        operation => "Would you like to migrate the database?",
        next_action => 'upgrade' },
      { appname => 'sql-ledger',
        version => undef,
        message => "Unsupported SQL-Ledger version detected.",
        operation => "Cancel.",
        next_action => 'cancel' },
      { appname => 'ledgersmb',
        version => '1.2',
        message => "LedgerSMB 1.2 db found.",
        operation => "Would you like to upgrade the database?",
        next_action => 'upgrade' },
      { appname => 'ledgersmb',
        version => '1.3dev',
        message => 'Development version found.  Please upgrade manually first',
        operation => 'Cancel?',
        next_action => 'cancel' },
      { appname => 'ledgersmb',
        version => 'legacy',
        message => 'Legacy version found.  Please upgrade first',
        operation => 'Cancel?',
        next_action => 'cancel' },
      { appname => 'ledgersmb',
        version => '1.3',
        message => "LedgerSMB 1.3 db found.",
        operation => "Would you like to upgrade the database?",
        next_action => 'upgrade' },
      { appname => 'ledgersmb',
        version => '1.4',
        message => "LedgerSMB 1.4 db found.",
        operation => 'Rebuild/Upgrade?',
        next_action => 'rebuild_modules' },
      { appname => 'ledgersmb',
        version => '1.5',
        message => "LedgerSMB 1.5 db found.",
        operation => 'Rebuild/Upgrade?',
        next_action => 'rebuild_modules' },
      { appname => 'ledgersmb',
        version => undef,
        message => "Unsupported LedgerSMB version detected.",
        operation => "Cancel.",
        next_action => 'cancel' } );


sub login {
    use LedgerSMB::Locale;
    my ($request) = @_;
    if (!$request->{database}){
        list_databases($request);
        return;
    }
    my $database = _get_database($request);
    my $server_info = $database->server_version;

    my $version_info = $database->get_info();

    _init_db($request);
    sanity_checks($database);
    $request->{login_name} = $version_info->{username};
    if ($version_info->{status} eq 'does not exist'){
        $request->{message} = $request->{_locale}->text(
             'Database does not exist.');
        $request->{operation} = $request->{_locale}->text('Create Database?');
        $request->{next_action} = 'create_db';
    } else {
    my $dispatch_entry;

    foreach $dispatch_entry (@login_actions_dispatch_table) {
        if ($version_info->{appname} eq $dispatch_entry->{appname}
           && ($version_info->{version} eq $dispatch_entry->{version}
               || ! defined $dispatch_entry->{version})) {
        my $field;

        foreach $field (qw|operation message next_action|) {
            $request->{$field} =
               $request->{_locale}->maketext($dispatch_entry->{$field});
        }
        last;
        }
    }


    if (! defined $request->{next_action}) {
        $request->{message} = $request->{_locale}->text(
        'Unknown database found.'
        );
        $request->{operation} = $request->{_locale}->text('Cancel?');
        $request->{next_action} = 'cancel';
    } elsif ($request->{next_action} eq 'rebuild_modules') {
            # we found the current version
            # check we don't have stale migrations around
            my $dbh = $database->connect({PrintError=>0, AutoCommit=>0});
            my $sth = $dbh->prepare(qq(
                SELECT count(*)<>0
                  FROM defaults
                 WHERE setting_key = 'migration_ok' and value = 'no'
              ));
            $sth->execute();
            my ($has_stale_migration) = $sth->fetchrow_array();
            if ($has_stale_migration) {
                $request->{operation} = 'Restore old version?';
                $request->{message} = 'Failed migration found';
                $request->{next_action} = 'revert_migration';
            }
        }
    }
    my $template = LedgerSMB::Template->new(
            path => 'UI/setup',
            template => 'confirm_operation',
        format => 'HTML',
    );
    $template->render($request);

}

=item sanity_checks
Checks for common setup issues and errors if admin tasks cannot be completed/

=cut

sub sanity_checks {
    my ($database) = @_;
    `psql --help` || die LedgerSMB::App_State::Locale->text(
                                 'psql not found.'
                              );
}

=item list_databases
Lists all databases as hyperlinks to continue operations.

=cut

sub list_databases {
    my ($request) = @_;
    my $database = _get_database($request);
    my @results = $database->list_dbs;
    $request->{dbs} = [];
    for my $r (@results){
       push @{$request->{dbs}}, {row_id => $r, db => $r };
    }
    my $template = LedgerSMB::Template->new(
            path => 'UI/setup',
            template => 'list_databases',
        format => 'HTML',
    );
    $template->render($request);
}

=item list_users
Lists all users in the selected database

=cut

sub list_users {
    my ($request) = @_;
    _init_db($request);
    my $user = LedgerSMB::DBObject::User->new($request);
    my $users = $user->get_all_users;
    $request->{users} = [];
    for my $u (@$users) {
        push @{$request->{users}}, {row_id => $u->{id}, name => $u->{username} };
    }
    my $template = LedgerSMB::Template->new(
        path => 'UI/setup',
        template => 'list_users',
        format => 'HTML',
    );
    $template->render($request);
}

=item copy_db

Copies db to the name of $request->{new_name}

=cut

sub copy_db {
    my ($request) = @_;
    my $database = _get_database($request);
    my $rc = $database->copy($request->{new_name})
           || die 'An error occurred. Please check your database logs.' ;
    my $dbh = LedgerSMB::Database->new(
           {%$database, (company_name => $request->{new_name})}
    )->connect({ PrintError => 0, AutoCommit => 0 });
    $dbh->prepare("SELECT setting__set('role_prefix',
                               coalesce((setting_get('role_prefix')).value, ?))"
    )->execute("lsmb_$database->{company_name}__");
    $dbh->commit;
    $dbh->disconnect;
    complete($request);
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

    my $request = shift @_;
    my $database = _get_database($request);

    my $backupfile;
    my $mimetype;

    if ($request->{backup} eq 'roles'){
       my @t = localtime(time);
       $t[4]++;
       $t[5] += 1900;
       $t[3] = substr( "0$t[3]", -2 );
       $t[4] = substr( "0$t[4]", -2 );
       my $date = "$t[5]-$t[4]-$t[3]";

       $backupfile = $database->backup_globals(
                      tempdir => $LedgerSMB::Sysconfig::backuppath,
                         file => "roles_${date}.sql"
       );
       $mimetype   = 'text/x-sql';
    } elsif ($request->{backup} eq 'db'){
       $backupfile = $database->backup;
       $mimetype   = 'application/octet-stream';
    } else {
        $request->error($request->{_locale}->text('Invalid backup request'));
    }

    $backupfile or $request->error($request->{_locale}->text('Error creating backup file'));

    if ($request->{backup_type} eq 'email'){
        # suppress warning of single usage of $LedgerSMB::Sysconfig::...
        no warnings 'once';

        my $csettings = $LedgerSMB::Company_Config::settings;
        my $mail = new LedgerSMB::Mailer(
            from          => $LedgerSMB::Sysconfig::backup_email_from,
            to            => $request->{email},
            subject       => "Email of Backup",
            message       => 'The Backup is Attached',
            );
        $mail->attach(
            mimetype => $mimetype,
            filename => 'ledgersmb-backup.sqlc',
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
          -attachment => 'ledgersmb-backup-' . time . ".sqlc",
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

=item revert_migration

=cut

sub revert_migration {
    my ($request) = @_;
    my $database = _get_database($request);
    my $dbh = $database->connect({PrintError => 0, AutoCommit => 0});
    my $sth = $dbh->prepare(qq(
         SELECT value
           FROM defaults
          WHERE setting_key = 'migration_src_schema'
      ));
    $sth->execute();
    my ($src_schema) = $sth->fetchrow_array();
    $dbh->rollback();
    $dbh->begin_work();
    $dbh->do("DROP SCHEMA public CASCADE");
    $dbh->do("ALTER SCHEMA $src_schema RENAME TO public");
    $dbh->commit();

    my $template = LedgerSMB::Template->new(
        path => 'UI/setup',
        template => 'complete_migration_revert',
        format => 'HTML',
           );

    $template->render($request);
}

=item _get_template_directories

Returns set of template directories available.

=cut

sub _get_template_directories {
    my $subdircount = 0;
    my @dirarray;
    my $locale = $LedgerSMB::App_State::Locale;
    opendir ( DIR, $LedgerSMB::Sysconfig::templates) || die $locale->text("Error while opening directory: [_1]",  "./".$LedgerSMB::Sysconfig::templates);
    while( my $name = readdir(DIR)){
        next if ($name =~ /\./);
        if (-d $LedgerSMB::Sysconfig::templates.'/'.$name) {
            push @dirarray, {text => $name, value => $name};
        }
    }
    closedir(DIR);
    return \@dirarray;
}

=item template_screen

Shows the screen for loading templates.  This should appear before loading
the user.  $request->{only_templates} will be passed on to the saving routine
so that further workflow can be aborted.

=cut

sub template_screen {
    my ($request) = @_;
    $request->{template_dirs} = _get_template_directories();
    LedgerSMB::Template->new(
           path => 'UI/setup',
           template => 'template_info',
           format => 'HTML',
    )->render($request);
}

=item load_templates

This bulk loads the templates.  Expectated inputs are template_dir and
optionally only_templates (which if true returns to the confirmation screen
and not the user creation screen.

=cut

sub load_templates {
    my ($request) = @_;
    my $dir = $LedgerSMB::Sysconfig::templates . '/' . $request->{template_dir};
    _init_db($request);
    my $dbh = $request->{dbh};
    opendir(DIR, $dir);
    while (readdir(DIR)){
       next unless -f "$dir/$_";
       my $dbtemp = LedgerSMB::Template::DB->get_from_file("$dir/$_");
       $dbtemp->save;
    }
    return _render_new_user($request) unless $request->{only_templates};
    return complete($request);
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
    $sth->finish();

    return @accounts;
}


=item upgrade_settigs

=cut

my %info_applicable_for_upgrade = (
    'default_ar' => [ 'ledgersmb/1.2',
              'sql-ledger/2.7', 'sql-ledger/2.8' ],
    'default_ap' => [ 'ledgersmb/1.2',
              'sql-ledger/2.7', 'sql-ledger/2.8' ],
    'default_country' => [ 'ledgersmb/1.2',
               'sql-ledger/2.7', 'sql-ledger/2.8']
    );

=item applicable_for_upgrade

Checks settings for applicability for a given upgrade, for the form.

=cut

sub applicable_for_upgrade {
    my ($info, $upgrade) = @_;

    foreach my $check (@{$info_applicable_for_upgrade{$info}}) {
    return 1
        if $check eq $upgrade;
    }

    return 0;
}

=item upgrade_info

Displays the upgrade information screen,

=cut

sub upgrade_info {
    my ($request) = @_;
    my $database = _init_db($request);
    my $dbinfo = $database->get_info();
    my $upgrade_type = "$dbinfo->{appname}/$dbinfo->{version}";


    if (applicable_for_upgrade('default_ar', $upgrade_type)) {
    @{$request->{ar_accounts}} = _get_linked_accounts($request, "AR");
    unshift @{$request->{ar_accounts}}, {}
            unless scalar(@{$request->{ar_accounts}}) == 1;
    }

    if (applicable_for_upgrade('default_ap', $upgrade_type)) {
    @{$request->{ap_accounts}} = _get_linked_accounts($request, "AP");
    unshift @{$request->{ap_accounts}}, {}
            unless scalar(@{$request->{ap_accounts}}) == 1;
    }

    if (applicable_for_upgrade('default_country', $upgrade_type)) {
    @{$request->{countries}} = ();
    foreach my $iso2 (all_country_codes()) {
        push @{$request->{countries}}, { code    => uc($iso2),
                         country => code2country($iso2) };
    }
    @{$request->{countries}} =
        sort { $a->{country} cmp $b->{country} } @{$request->{countries}};
    unshift @{$request->{countries}}, {};
    }

    my $retval = 0;
    foreach my $key (keys %info_applicable_for_upgrade) {
    $retval++
        if applicable_for_upgrade($key, $upgrade_type);
    }
    return $retval;
}

=item upgrade


=cut

my %upgrade_run_step = (
    'sql-ledger/2.7' => 'run_sl_migration',
    'sql-ledger/2.8' => 'run_sl_migration',
    'ledgersmb/1.2' => 'run_upgrade',
    'ledgersmb/1.3' => 'run_upgrade'
    );

sub upgrade {
    my ($request) = @_;
    my $database = _init_db($request);
    my $dbinfo = $database->get_info();
    my $upgrade_type = "$dbinfo->{appname}/$dbinfo->{version}";

    $request->{dbh}->{AutoCommit} = 0;
    my $locale = $request->{_locale};

    for my $check (LedgerSMB::Upgrade_Tests->get_tests()){
        next if ($check->min_version gt $dbinfo->{version})
        || ($check->max_version lt $dbinfo->{version})
        || ($check->appname ne $dbinfo->{appname});
        my $sth = $request->{dbh}->prepare($check->test_query);
        $sth->execute()
        or die "Failed to execute pre-migration check " . $check->name;
        if ($sth->rows > 0){ # Check failed --CT
             _failed_check($request, $check, $sth);
             return;
        }
    $sth->finish();
    }

    if (upgrade_info($request) > 0) {
    my $template = LedgerSMB::Template->new(
            path => 'UI/setup',
            template => 'upgrade_info',
            format => 'HTML',
        );

        $request->{upgrade_action} = $upgrade_run_step{$upgrade_type};
        $template->render($request);
    } else {
        $request->{dbh}->rollback();
        $request->{dbh}->begin_work();

        __PACKAGE__->can($upgrade_run_step{$upgrade_type})->($request);
    }

}

sub _failed_check {
    my ($request, $check, $sth) = @_;
    my $template = LedgerSMB::Template->new(
            path => 'UI',
            template => 'form-dynatable',
            format => 'HTML',
    );
    my $rows = [];
    my $count = 1;
    my $hiddens = {table => $check->table,
                    edit => $check->column,
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
                                value => $row->{$check->column},
                                type => 'text',
                                size => 15,
                    },
          };
          push @$rows, $row;
          $hiddens->{"id_$count"} = $row->{id},
          ++$count;
    }
    $sth->finish();

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
           headers  => [$check->display_name, $check->instructions],
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

    _init_db($request);
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
    $sth->finish();
    $request->{dbh}->commit;
    $request->{dbh}->begin_work;
    upgrade($request);
}

=item create_db

 Beginning of the new database workflow

=cut

sub create_db {
    my ($request) = @_;
    my $rc=0;

    my $database = _get_database($request);
    $rc=$database->create_and_load();
    $logger->info("create_and_load rc=$rc");

    select_coa($request);
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

    my ($request) = @_;

    if ($request->{coa_lc} =~ /\.\./){
       $request->error($request->{_locale}->text('Access Denied'));
    }
    if ($request->{coa_lc}){
        if ($request->{chart}){
           my $database = _get_database($request);

           $database->load_coa( {
               country => $request->{coa_lc},
               chart => $request->{chart} });

           template_screen($request);
           return;
        } else {
            opendir(CHART, "sql/coa/$request->{coa_lc}/chart");
            @{$request->{charts}} =
                map +{ name => $_ },
                sort(grep !/^(\.|[Ss]ample.*)/,
                      readdir(CHART));
            closedir(CHART);
       }
    } else {
        #COA Directories
        opendir(COA, 'sql/coa');
        @{$request->{coa_lcs}} =
            map +{ code => $_ },
            sort(grep !/^(\.|[Ss]ample.*)/,
                 readdir(COA));
        closedir(COA);
    }

    my $template = LedgerSMB::Template->new(
            path => 'UI/setup',
            template => 'select_coa',
        format => 'HTML',
    );
    $template->render($request);
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

    template_screen($request);
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


    _init_db($request);
    $request->{dbh}->{AutoCommit} = 0;

    @{$request->{salutations}}
    = $request->call_procedure(funcname => 'person__list_salutations' );

    @{$request->{countries}}
    = $request->call_procedure(funcname => 'location_list_country' );
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
    $request->requires(qw(first_name last_name ssn employeenumber));
    $request->{entity_class} = 3;
    $request->{name} = "$request->{last_name}, $request->{first_name}";
    use LedgerSMB::Entity::Person::Employee;
    use LedgerSMB::Entity::User;
    use LedgerSMB::PGDate;

    _init_db($request);
    $request->{dbh}->{AutoCommit} = 0;

    $request->{control_code} = $request->{employeenumber};
    $request->{dob} = LedgerSMB::PGDate->from_input($request->{dob});
    my $emp = LedgerSMB::Entity::Person::Employee->new(%$request);
    $emp->save;
    $request->{entity_id} = $emp->entity_id;
    my $user = LedgerSMB::Entity::User->new(%$request);
    my $duplicate = 0;
    try { $user->create($request->{password}); }
    catch {
        if ($_ =~ /duplicate user/i){
           $duplicate = 1;
           $request->{notice} = $request->{_locale}->text(
                       'User already exists. Import?'
            );
           $request->{pls_import} = 1;

           @{$request->{salutations}}
            = $request->call_procedure(funcname => 'person__list_salutations' );

           @{$request->{countries}}
              = $request->call_procedure(funcname => 'location_list_country' );

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
       } else {
           die $_;
       }
    };
    return if $duplicate;
    if ($request->{perms} == 1){
         for my $role (
                $request->call_procedure(funcname => 'admin__get_roles')
         ){
             $request->call_procedure(funcname => 'admin__add_user_to_role',
                                      args => [ $request->{username},
                                                $role->{rolname}
                                              ]);
         }
    } elsif ($request->{perms} == 0) {
        $request->call_procedure(funcname => 'admin__add_user_to_role',
                                 args => [ $request->{username},
                                           "lsmb_$request->{database}__".
                                            "users_manage",
                                         ]
        );
   }
   $request->{dbh}->commit;
   $request->{dbh}->begin_work;

   rebuild_modules($request);
}


=item process_and_run_upgrade_script

=cut

sub process_and_run_upgrade_script {
    my ($request, $database, $src_schema, $template) = @_;
    my $dbh = $database->connect({ PrintError => 0, AutoCommit => 0 });
    my $temp = $database->loader_log_filename();
    my $rc;

    $dbh->do("CREATE SCHEMA $LedgerSMB::Sysconfig::db_namespace")
    or die "Failed to create schema $LedgerSMB::Sysconfig::db_namespace (" . $dbh->errstr . ")";
    $dbh->commit;
    $dbh->begin_work;

    $database->load_base_schema({
    log     => $temp . "_stdout",
    errlog  => $temp . "_stderr"
                });
    $database->load_modules('LOADORDER', {
    log     => $temp . "_stdout",
    errlog  => $temp . "_stderr"
                });

    $dbh->do(qq(
       INSERT INTO defaults (setting_key, value)
                     VALUES ('migration_ok', 'no')
     ));
    $dbh->do(qq(
       INSERT INTO defaults (setting_key, value)
                     VALUES ('migration_src_schema', '$src_schema')
     ));
    $dbh->commit;
    $dbh->begin_work;

    my $dbtemplate = LedgerSMB::Template->new(
        user => {},
        path => 'sql/upgrade',
        template => $template,
        no_auto_output => 1,
        format_options => {extension => 'sql'},
        output_file => 'upgrade',
        format => 'TXT' );
    $dbtemplate->render($request);
    $database->run_file(
        file =>  $LedgerSMB::Sysconfig::tempdir . "/upgrade.sql",
        log => $temp . "_stdout",
        errlog => $temp . "_stderr"
        );


    my $sth = $dbh->prepare(qq(select value='yes'
                                 from defaults
                                where setting_key='migration_ok'));
    $sth->execute();
    my ($success) = $sth->fetchrow_array();
    $sth->finish();

    $request->error(qq(Upgrade failed;
           logs can be found in
           ${temp}_stdout and ${temp}_stderr))
    if ! $success;

    $dbh->do("delete from defaults where setting_key like 'migration_%'");

    # If users are added to the user table, and appropriat roles created, this
    # then grants the base_user permission to them.  Note it only affects users
    # found also in pg_roles, so as to avoid errors.  --CT
    $dbh->do("SELECT admin__add_user_to_role(username, lsmb__role('base_user'))
                from users WHERE username IN (select rolname from pg_roles)");

    $dbh->commit;
    $dbh->begin_work;
}


=item run_upgrade



=cut

sub run_upgrade {
    my ($request) = @_;
    my $database = _init_db($request);

    my $dbh = $request->{dbh};
    my $dbinfo = $database->get_info();
    my $v = $dbinfo->{version};
    $v =~ s/\.//;
    $dbh->do("ALTER SCHEMA $LedgerSMB::Sysconfig::db_namespace RENAME TO lsmb$v");

    process_and_run_upgrade_script($request, $database, "lsmb$v",
                   "$dbinfo->{version}-1.4");

    if ($v ne '1.2'){
    $request->{only_templates} = 1;
    }
    my $templates = LedgerSMB::Setting->get('templates');
    if ($templates){
       $request->{template_dir} = $templates;
       load_templates($request);
    } else {
       template_screen($request);
    }
}

=item run_sl_migration


=cut

sub run_sl_migration {
    my ($request) = @_;
    my $database = _init_db($request);
    my $rc = 0;

    my $dbh = $request->{dbh};
    $dbh->do('ALTER SCHEMA public RENAME TO sl28');
    # process_and_run_upgrade_script commits the transaction

    process_and_run_upgrade_script($request, $database, "sl28",
                   'sl2.8-1.4');

    create_initial_user($request);
}


=item create_initial_user

=cut

sub create_initial_user {
    my ($request) = @_;

   my $database = _init_db($request) unless $request->{dbh};
   @{$request->{salutations}}
    = $request->call_procedure(funcname => 'person__list_salutations' );

   @{$request->{countries}}
    = $request->call_procedure(funcname => 'location_list_country' );

   my $locale = $request->{_locale};

   @{$request->{perm_sets}} = (
       {id => '0', label => $locale->text('Manage Users')},
       {id => '1', label => $locale->text('Full Permissions')},
       {id => '-1', label => $locale->text('No changes')},
   );
    my $template = LedgerSMB::Template->new(
                   path => 'UI/setup',
                   template => 'new_user',
                   format => 'HTML',
     );
     $template->render($request);
}

=item edit_user_roles

=cut

sub edit_user_roles {
    my ($request) = @_;

    _init_db($request)
        unless $request->{dbh};

    my $admin = LedgerSMB::DBObject::Admin->new($request);
    my $all_roles = $admin->get_roles($request->{database});

    my $user_obj = LedgerSMB::DBObject::User->new($request);
    $user_obj->get($request->{id});

    # LedgerSMB::DBObject::User doesn't retrieve the username
    # field from the users table (nor any of the other values from it,
    # really) and there's no stored procedure to do so.
    # The name 'admin__get_user' is already taken, but takes the entity_id
    # as its argument... So, we're going brute force here, for 1.4
    my @user_rec = grep { $_->{id} == $request->{id} }
          @{$user_obj->get_all_users};

    $user_obj->{username} = $user_rec[0]->{username};

    my $template = LedgerSMB::Template->new(
        user => $request->{_user},
        template => 'edit_user',
        format => 'HTML',
        path=>'UI/setup',
    );
    my $template_data = {
                        request => $request,
                           user => $user_obj,
                          roles => $all_roles,
            };

    $template->render($template_data);
}

=item save_user_roles

=cut

sub save_user_roles {
    my ($request) = @_;

    _init_db($request);
    $request->{user_id} = $request->{id};
    my $admin = LedgerSMB::DBObject::Admin->new(base => $request, copy=>'all');
    my $roles = [];
    for my $r (grep { $_ =~ m/lsmb_(.+)__/ } keys %$request) {
        push @$roles, $r;
    }
    $admin->save_roles($roles);

    edit_user_roles($request);
}


=item reset_password

=cut

sub reset_password {
    my ($request) = @_;

    _init_db($request);
    my $user = LedgerSMB::DBObject::User->new(base => $request, copy=>'all');
    my $result = $user->save();

    $request->{password} = '';

    edit_user_roles($request);
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
    my $database = _init_db($request);

    $database->upgrade_modules('LOADORDER', $LedgerSMB::VERSION)
        or die "Upgrade failed.";

    complete($request);
}

=item complete

Gets the info and adds shows the complete screen.

=cut

sub complete {
    my ($request) = @_;
    my $database = _init_db($request);
    my $temp = $database->loader_log_filename();
    $request->{lsmb_info} = $database->stats();
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
