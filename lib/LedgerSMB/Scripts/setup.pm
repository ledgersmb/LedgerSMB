
package LedgerSMB::Scripts::setup;

=head1 NAME

LedgerSMB::Scripts::setup - web entry points for database administration

=head1 DESCRIPTION

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

use strict;
use warnings;

use Digest::MD5 qw(md5_hex);
use Encode;
use File::Temp;
use HTTP::Status qw( HTTP_OK HTTP_UNAUTHORIZED );
use List::Util qw( first );
use Locale::Country;
use MIME::Base64;
use Try::Tiny;
use Version::Compare;

use LedgerSMB::App_State;
use LedgerSMB::Database;
use LedgerSMB::DBObject::Admin;
use LedgerSMB::DBObject::User;
use LedgerSMB::Magic qw( EC_EMPLOYEE HTTP_454 PERL_TIME_EPOCH );
use LedgerSMB::Mailer;
use LedgerSMB::PSGI::Util;
use LedgerSMB::Setting;
use LedgerSMB::Setup::SchemaChecks qw( html_formatter_context );
use LedgerSMB::Sysconfig;
use LedgerSMB::Template::DB;
use LedgerSMB::Upgrade_Preparation;
use LedgerSMB::Upgrade_Tests;

my $logger = Log::Log4perl->get_logger('LedgerSMB::Scripts::setup');
my $CURRENT_MINOR_VERSION;
if ( $LedgerSMB::VERSION =~ /(\d+\.\d+)./ ) {
    $CURRENT_MINOR_VERSION = $1;
}

=item no_db

Existence of this sub causes requests passed to this module /not/ to be
pre-connected to the database.

=cut

sub no_db {
    # if we switch our entrypoints to 'dbonly',
    # there are problems with the case where
    # a new database must be created.
    return 1;
}

=item no_db_actions

=cut

sub no_db_actions {
    return qw(__default);
}

=item clear_session_actions

Returns an array of actions which should have the session
(cookie) cleared before verifying the session and being
dispatched to.

=cut

sub clear_session_actions {
    return qw(__default);
}


sub __default {

    my ($request) = @_;
    my $template = LedgerSMB::Template->new_UI(
        $request,
        template => 'setup/credentials',
    );
    return $template->render($request);
}

sub _get_database {
    my ($request) = @_;
    my $creds = $request->{_auth}->get_credentials('setup');

    return [ HTTP_UNAUTHORIZED,
             [ 'WWW-Authenticate' => 'Basic realm="LedgerSMB"',
               'Content-Type' => 'text/text; charset=UTF-8' ],
             [ 'Please enter your credentials' ] ]
        if ! defined $creds->{password};

    # Ideally this regex should be configurable per instance, and possibly per admin user
    # for now we simply use a fixed regex. It will cover many if not most use cases.
    return [ HTTP_454,
             [ 'WWW-Authenticate' => 'Basic realm="LedgerSMB"',
               'Content-Type' => 'text/html; charset=UTF-8' ],
             [ "<html><body><h1 align='center'>Access to the ($request->{database}) database is Forbidden!</h1></br><h4 align='center'><a href='/setup.pl?database=$request->{database}'>return to setup</a></h4></body></html>" ] ]
        if ( $request->{database} && $request->{database} =~ /postgres|template0|template1/);

    return (undef,
            LedgerSMB::Database->new(
                username => $creds->{login},
                password => $creds->{password},
                  dbname => $request->{database},
    ));
}


sub _init_db {
    my ($request) = @_;
    my ($reauth, $database) = _get_database($request);
    return $reauth if $reauth;

    local $@ = undef;
    $request->{dbh} = eval {
        $database->connect({PrintError => 0, AutoCommit => 0 })
    } if ! defined $request->{dbh};
    $LedgerSMB::App_State::DBH = $request->{dbh};

    return $database;
}

=item login

Processes the login and examines the database to determine appropriate steps to
take.
)
=cut

=item get_dispatch_table

Returns the main dispatch table for the versions with supported upgrades

=cut

sub get_dispatch_table {
    my ($request) = @_;
    my $sl_detect = $request->{_locale}->text('SQL-Ledger database detected.');
    my $migratemsg =  $request->{_locale}->text(
               'Would you like to migrate the database?'
    );
    my $upgrademsg =  $request->{_locale}->text(
               'Would you like to upgrade the database?'
    );

    return ( { appname => 'sql-ledger',
        version => '2.7',
        slschema => 'sl27',
        message => $sl_detect,
        operation => $migratemsg,
        next_action => 'upgrade' },
      { appname => 'sql-ledger',
        version => '2.8',
        slschema => 'sl28',
        message => $sl_detect,
        operation => $migratemsg,
        next_action => 'upgrade' },
      { appname => 'sql-ledger',
        version => '3.0',
        slschema => 'sl30',
        message => $request->{_locale}->text(
                     'SQL-Ledger 3.0 database detected.'
                   ),
        operation => $migratemsg,
        next_action => 'upgrade' },
      { appname => 'sql-ledger',
        version => undef,
        message => $request->{_locale}->text(
                      'Unsupported SQL-Ledger version detected.'
                   ),
        operation => $request->{_locale}->text('Cancel'),
        next_action => 'cancel' },
      { appname => 'ledgersmb',
        version => '1.2',
        message => $request->{_locale}->text('LedgerSMB 1.2 db found.'),
        operation => $upgrademsg,
        next_action => 'upgrade' },
      { appname => 'ledgersmb',
        version => '1.3',
        message => $request->{_locale}->text('LedgerSMB 1.3 db found.'),
        operation => $upgrademsg,
        next_action => 'upgrade' },
      { appname => 'ledgersmb',
        version => '1.4',
        message => $request->{_locale}->text('LedgerSMB 1.4 db found.'),
        operation => $upgrademsg,
        # rebuild_modules will upgrade 1.4->1.5 by applying (relevant) changes
        next_action => 'rebuild_modules' },
      { appname => 'ledgersmb',
        version => '1.5',
        message => $request->{_locale}->text('LedgerSMB 1.5 db found.'),
        operation => $request->{_locale}->text('Rebuild/Upgrade?'),
        next_action => 'rebuild_modules' },
      { appname => 'ledgersmb',
        version => '1.6',
        message => $request->{_locale}->text('LedgerSMB 1.6 db found.'),
        operation => $request->{_locale}->text('Rebuild/Upgrade?'),
        next_action => 'rebuild_modules' },
      { appname => 'ledgersmb',
        version => '1.7',
        message => $request->{_locale}->text('LedgerSMB 1.7 db found.'),
        operation => $request->{_locale}->text('Rebuild/Upgrade?'),
        next_action => 'rebuild_modules' },
      { appname => 'ledgersmb',
        version => undef,
        message => $request->{_locale}->text('Unsupported LedgerSMB version detected.'),
        operation => $request->{_locale}->text('Cancel'),
        next_action => 'cancel' } );
}



sub login {
    use LedgerSMB::Locale;
    my ($request) = @_;
    if (!$request->{database}){
        return list_databases($request);
    }
    my ($reauth, $database) = _get_database($request);
    return $reauth if $reauth;

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
    }
    else {
        foreach my $dispatch_entry (get_dispatch_table($request)) {
            if ($version_info->{appname} eq $dispatch_entry->{appname}
                && ($version_info->{version} eq $dispatch_entry->{version}
                    || ! defined $dispatch_entry->{version})) {
                foreach my $field (qw|operation message next_action slschema|) {
                    $request->{$field} = $dispatch_entry->{$field};
                }
                last;
            }
        }

        if (! defined $request->{next_action}) {
            $request->{message} = $request->{_locale}->text(
                'Unknown database found.'
                ) . $version_info->{full_version};
            $request->{operation} = $request->{_locale}->text('Cancel?');
            $request->{next_action} = 'cancel';
        } elsif ($request->{next_action} eq 'rebuild_modules') {
            # we found the current version
            # check we don't have stale migrations around
            my $dbh = $request->{dbh};
            my $sth = $dbh->prepare(q(
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
    my $template = LedgerSMB::Template->new_UI(
        $request,
        template => 'setup/confirm_operation',
    );
    return $template->render($request);
}

=item sanity_checks
Checks for common setup issues and errors if admin tasks cannot be completed/

=cut

sub sanity_checks {
    my ($database) = @_;
    `psql --help` || die LedgerSMB::App_State::Locale->text(
                                 'psql not found.'
                              );
    return;
}

=item list_databases
Lists all databases as hyperlinks to continue operations.

=cut

sub list_databases {
    my ($request) = @_;
    my ($reauth, $database) = _get_database($request);
    return $reauth if $reauth;

    my @results = $database->list_dbs;
    $request->{dbs} = [];
    # Ideally we would extend DBAdmin->list_dbs to accept an argument containing a list of databases to exclude using a method similar to that shown at https://git.framasoft.org/framasoft/OCB/commit/7a6e94edd83e9e73e56d2d148e3238618
    # also, we should add a new function DBAdmin->list_dbs_this_user which only returns db's the currently auth'd user has access to. Once again the framasoft.org link shows a method of doing this
    # for now we simply use a fixed regex. It will cover many if not most use cases.
    @{$request->{dbs}} = map {+{ row_id => $_, db  => $_ }} grep { ! m/^(postgres|template0|template1)$/ } @results ;

    my $template = LedgerSMB::Template->new_UI(
        $request,
        template => 'setup/list_databases',
    );
    return $template->render($request);
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
    my $template = LedgerSMB::Template->new_UI(
        $request,
        template => 'setup/list_users',
    );
    return $template->render($request);
}

=item copy_db

Copies db to the name of $request->{new_name}

=cut

sub copy_db {
    my ($request) = @_;
    my ($reauth, $database) = _get_database($request);
    return $reauth if $reauth;

    $database->copy($request->{new_name})
           || die 'An error occurred. Please check your database logs.' ;

    return complete($request);
}


=item backup_db

Backs up a full db

=cut

sub backup_db {
    my $request = shift @_;
    $request->{backup} = 'db';
    return _begin_backup($request);
}

=item backup_roles

Backs up roles only (for all db's)

=cut

sub backup_roles {
    my $request = shift @_;
    $request->{backup} = 'roles';
    return _begin_backup($request);
}

# Private method, basically just passes the inputs on to the next screen.
sub _begin_backup {
    my $request = shift @_;
    $request->{can_email} = defined $LedgerSMB::Sysconfig::backup_email_from;
    my $template = LedgerSMB::Template->new_UI(
        $request,
        template => 'setup/begin_backup',
    );
    return $template->render($request);
};


=item run_backup

Runs the backup.  If backup_type is set to email, emails the

=cut

sub run_backup {
    use LedgerSMB::Company_Config;

    my $request = shift @_;
    my ($reauth, $database) = _get_database($request);
    return $reauth if $reauth;

    my $backupfile;
    my $mimetype;

    if ($request->{backup} eq 'roles') {
        $backupfile = $database->backup_globals;
        $mimetype = 'text/x-sql';
    }
    elsif ($request->{backup} eq 'db') {
        $backupfile = $database->backup;
        $mimetype   = 'application/octet-stream';
    }
    else {
        die $request->{_locale}->text('Invalid backup request');
    }

    $backupfile or
        die $request->{_locale}->text('Error creating backup file');

    if ($request->{backup_type} eq 'email') {

        my $mail = LedgerSMB::Mailer->new(
            from     => $LedgerSMB::Sysconfig::backup_email_from,
            to       => $request->{email},
            subject  => 'Email of Backup',
            message  => 'The Backup is Attached',
        );
        $mail->attach(
            mimetype => $mimetype,
            filename => 'ledgersmb-backup.sqlc',
            file     => $backupfile,
        );
        $mail->send;
        unlink $backupfile;
        my $template = LedgerSMB::Template->new_UI(
            $request,
            template => 'setup/complete',
        );
        return $template->render($request);
    }
    elsif ($request->{backup_type} eq 'browser') {
        my $attachment_name = 'ledgersmb-backup-' . time . '.sqlc';
        return sub {
            my $responder = shift;

            open my $bak, '<:bytes', $backupfile
                or die "Failed to open temporary backup file $backupfile: $!";
            $responder->(
                [
                 HTTP_OK,
                 [
                  'Content-Type' => $mimetype,
                  'Content-Disposition' =>
                      "attachment; filename=\"$attachment_name\""
                 ],
                 $bak  # the file-handle
                ]);
            close $bak
                or warn "Failed to close temporary backup file $backupfile: $!";
            unlink $backupfile
                or warn "Failed to unlink temporary backup file $backupfile: $!";
        };
    }
    else {
        die $request->{_locale}->text('Don\'t know what to do with backup');
    }
}

=item revert_migration

=cut

sub revert_migration {
    my ($request) = @_;
    my ($reauth, $database) = _get_database($request);
    return $reauth if $reauth;

    my $dbh = $database->connect({PrintError => 0, AutoCommit => 0});
    my $sth = $dbh->prepare(q(
         SELECT value
           FROM defaults
          WHERE setting_key = 'migration_src_schema'
      ));
    $sth->execute();
    my ($src_schema) = $sth->fetchrow_array();
    $dbh->rollback();
    $dbh->do('DROP SCHEMA public CASCADE');
    $dbh->do("ALTER SCHEMA $src_schema RENAME TO public");
    $dbh->commit();

    my $template = LedgerSMB::Template->new_UI(
        $request,
        template => 'setup/complete_migration_revert',
        );

    return $template->render($request);
}

=item _get_template_directories

Returns set of template directories available.

=cut

sub _get_template_directories {
    my $subdircount = 0;
    my @dirarray;
    my $locale = $LedgerSMB::App_State::Locale;
    opendir ( DIR, $LedgerSMB::Sysconfig::templates) || die $locale->text('Error while opening directory: [_1]',  "./$LedgerSMB::Sysconfig::templates");
    while( my $name = readdir(DIR)){
        next if ($name =~ /\./);
        if (-d "$LedgerSMB::Sysconfig::templates/$name" ) {
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
    return LedgerSMB::Template->new_UI(
        $request,
        template => 'setup/template_info',
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
    while (my $fname = readdir(DIR)){
       next unless -f "$dir/$fname";
       my $dbtemp = LedgerSMB::Template::DB->get_from_file("$dir/$fname");
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
                      'sql-ledger/2.7', 'sql-ledger/2.8', 'sql-ledger/3.0' ],
    'default_ap' => [ 'ledgersmb/1.2',
                      'sql-ledger/2.7', 'sql-ledger/2.8', 'sql-ledger/3.0' ],
    'default_country' => [ 'ledgersmb/1.2',
                           'sql-ledger/2.7', 'sql-ledger/2.8', 'sql-ledger/3.0' ],
    'slschema' => [ 'sql-ledger/2.7', 'sql-ledger/2.8', 'sql-ledger/3.0' ]
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
    my $retval = 0;

    if (applicable_for_upgrade('default_ar', $upgrade_type)) {
        @{$request->{ar_accounts}} = _get_linked_accounts($request, 'AR');
        my $n = scalar(@{$request->{ar_accounts}});
        if ($n > 1) {
            unshift @{$request->{ar_accounts}}, {};
            $retval++;
        }
        elsif ($n == 1) {
            # If there's only 1 (or none at all), don't ask the question
            $request->{default_ar} =
                (pop @{$request->{ar_accounts}})->{accno};
        }
        else {
            $request->{default_ar} = 'null';
        }
    }

    if (applicable_for_upgrade('default_ap', $upgrade_type)) {
        @{$request->{ap_accounts}} = _get_linked_accounts($request, 'AP');
        my $n = scalar(@{$request->{ap_accounts}});
        if ($n > 1) {
            unshift @{$request->{ap_accounts}}, {};
            $retval++;
        }
        elsif ($n == 1) {
            # If there's only 1 (or none at all), don't ask the question
            $request->{default_ap} =
                (pop @{$request->{ap_accounts}})->{accno};
        }
        else {
            # If there's only 1 (or none at all), don't ask the question
            $request->{default_ap} = 'null';
        }
    }

    if (applicable_for_upgrade('default_country', $upgrade_type)) {
        $retval++;
        @{$request->{countries}} = (
            {}, # empty initial row
            sort { $a->{country} cmp $b->{country} }
               map { { code    => uc($_),
                       country => code2country($_) } } all_country_codes()
            );
    }

    if (applicable_for_upgrade('slschema', $upgrade_type)) {
        $retval++;
        $request->{slschema} = 'sl' . $dbinfo->{version};
        $request->{slschema} =~ s/\.//;
    }
    $request->{lsmbversion} = $CURRENT_MINOR_VERSION;
    return $retval;
}

=item upgrade


=cut

my %upgrade_run_step = (
    'sql-ledger/2.7' => 'run_sl28_migration',
    'sql-ledger/2.8' => 'run_sl28_migration',
    'sql-ledger/3.0' => 'run_sl30_migration',
    'ledgersmb/1.2' => 'run_upgrade',
    'ledgersmb/1.3' => 'run_upgrade'
    );

sub _upgrade_test_is_applicable {
    my ($dbinfo, $test) = @_;

    return (($test->min_version le $dbinfo->{version})
            && ($test->max_version ge $dbinfo->{version})
            && ($test->appname eq $dbinfo->{appname}));
}

sub _applicable_upgrade_preparations {
    my $dbinfo = shift;

    return grep { _upgrade_test_is_applicable($dbinfo, $_) }
                  LedgerSMB::Upgrade_Preparation->get_migration_preparations;
}

sub _applicable_upgrade_tests {
    my $dbinfo = shift;

    return grep { _upgrade_test_is_applicable($dbinfo, $_) }
                  LedgerSMB::Upgrade_Tests->get_tests;
}

sub upgrade {
    my ($request) = @_;
    my $database = _init_db($request);
    my $dbinfo = $database->get_info();
    my $upgrade_type = "$dbinfo->{appname}/$dbinfo->{version}";

    $request->{dbh}->{AutoCommit} = 0;
    my $locale = $request->{_locale};

    for my $preparation (_applicable_upgrade_preparations($dbinfo)) {
        next if defined $request->{"applied_$preparation->{name}"}
             && $request->{"applied_$preparation->{name}"} eq 'On';
        my $sth = $request->{dbh}->prepare($preparation->preparation);
        my $status = $sth->execute()
            or die 'Failed to execute migration preparation ' . $preparation->{name} . ', ' . $sth->errstr;
        $request->{"applied_$preparation->{name}"} = 'On';
        $sth->finish();
    }

    for my $check (_applicable_upgrade_tests($dbinfo)) {
        next if $check->skipable
             && defined $request->{"skip_$check->{name}"}
             && $request->{"skip_$check->{name}"} eq 'On';
        my $sth = $request->{dbh}->prepare($check->test_query);
        $sth->execute()
            or die 'Failed to execute pre-migration check ' . $check->{name} . ', ' . $sth->errstr;
        if ($sth->rows > 0){ # Check failed --CT
             return _failed_check($request, $check, $sth);
        }
        $sth->finish();
    }

    if (upgrade_info($request) > 0) {
        my $template = LedgerSMB::Template->new_UI(
            $request,
            template => 'setup/upgrade_info',
        );

        $request->{upgrade_action} = $upgrade_run_step{$upgrade_type};
        return $template->render($request);
    } else {
        $request->{dbh}->rollback();

        return __PACKAGE__->can($upgrade_run_step{$upgrade_type})->($request);
    }

}

sub _failed_check {
    my ($request, $check, $sth) = @_;

    my %selectable_values = ();
    for my $column (@{$check->columns // []}) {
        if ( $check->selectable_values
             && $check->selectable_values->{$column} ) {
            my $sth = $request->{dbh}->prepare(
                $check->selectable_values->{$column});

            $sth->execute()
                or die 'Failed to query drop-down data in ' . $check->name;
            $selectable_values{$column} = $sth->fetchall_arrayref({});
        }
    }

    my $hiddens = {
       check => $check->name,
verify_check => md5_hex($check->test_query),
    database => $request->{database}
    };
    my @skip_keys = grep /^skip_/, keys %$request;
    $hiddens->{@skip_keys} = $request->{@skip_keys};

    my $rows = [];
    while (my $row = $sth->fetchrow_hashref('NAME_lc')) {
      my $count = 1+scalar(@$rows);

      for my $column (@{$check->columns // []}) {
        my $selectable_value = $selectable_values{$column};
        my $name = $column . '_' . $count;
        $row->{$column} =
           ( defined $selectable_value && @$selectable_value )
           ? { select => {
                   name => $name,
                   default_values => $row->{$column} // '',
                   id => $count,
                   options => $selectable_value,
                   default_blank => ( 1 != @$selectable_value )
           } }
           : { input => {
                   name => $name,
                   value => $row->{$column} // '',
                   type => 'text',
                   size => 15,
          } };
      };
      $hiddens->{"id_$count"} =
          join(',', map { MIME::Base64::encode(($row->{$_} // ''), '')}
                    @{$check->id_columns});
      push @$rows, $row;
    }
    $hiddens->{count} = scalar(@$rows);
    $sth->finish();

    my $heading = { map { $_ => $_ } @{$check->display_cols} };
    my %buttons = map { $_ => 1 } @{$check->buttons};
    my $enabled_buttons;
    for (
        { value => 'fix_tests', label => 'Save and Retry',
          cond => defined($check->{columns})},
        { value => 'cancel',    label => 'Cancel',
          cond => 1                         },
        { value => 'force',     label => 'Force',
          cond => $check->{force_queries}   },
        { value => 'skip',      label => 'Skip',
          cond => $check->skipable          }
    ) {
        if ( $buttons{$_->{label}} && $_->{cond}) {
            push @$enabled_buttons, {
                 type => 'submit',
                 name => 'action',
                value => $_->{value},
              tooltip => { id => 'action-' . $_->{value},
                           msg => $check->{tooltips}->{$_->{label}}
                                ? $request->{_locale}->maketext($check->{tooltips}->{$_->{label}})
                                : undef,
                           position => 'above'
                         },
                 text => $request->{_locale}->maketext($_->{label}),
                class => 'submit'
            }
        }
    }

    my $template = LedgerSMB::Template->new_UI(
        $request,
        template => 'setup/migration_step'
    );

    return $template->render({
           form               => $request,
           heading            => $heading,
           headers            => [$request->{_locale}->maketext($check->display_name),
                                  $request->{_locale}->maketext($check->instructions)],
           columns            => $check->display_cols,
           rows               => $rows,
           hiddens            => $hiddens,
           buttons            => $enabled_buttons,
           include_stylesheet => 'setup/stylesheet.css',
    });
}

=item fix_tests

Handles input from the failed test function and then re-runs the migrate db
script.

=cut

sub fix_tests{
    my ($request) = @_;

    my $database = _init_db($request);
    my $dbinfo = $database->get_info();
    my $dbh = $request->{dbh};
    $dbh->{AutoCommit} = 0;

    my @fix_tests = grep { $_->name eq $request->{check} }
        _applicable_upgrade_tests($dbinfo);

    die "Inconsistent state fixing data for $request->{check}: "
        . 'found multiple applicable tests by the same identifier'
        if @fix_tests > 1;
    die "Inconsistent state fixing data for $request->{check}: "
        . 'found no applicable tests for given identifier'
        if @fix_tests == 0;

    my $check = shift @fix_tests;
    die "Inconsistent state fixing date for $request->{check}: "
        . 'found different test by the same name while fixing data'
        if $request->{verify_check} ne md5_hex($check->test_query);

    my $table = $check->table;
    my @edits = @{$check->columns};
    # If we are inserting and id is displayed, we want to insert
    # at this exact location
    my $id_columns = join('|',@{$check->id_columns});
    my $id_displayed = $check->{insert}
                and grep( /^($id_columns)$/, @{$check->display_cols} );

    my $query;
    if ($check->{insert}) {
        my @_edits = @edits;
        unshift @_edits, @{$check->id_columns} if $id_displayed;
        my $columns = join(', ', map { $dbh->quote_identifier($_) } @_edits);
        my $values = join(', ', map { '?' } @_edits);
        $query = "INSERT INTO $table ($columns) VALUES ($values)";
    }
    else {
        my $setters =
            join(', ', map { $dbh->quote_identifier($_) . ' = ?' } @edits);
        $query = "UPDATE $table SET $setters WHERE "
               . join(' AND ',map {"$_ = ? "} @{$check->id_columns});
    }
    my $sth = $dbh->prepare($query);

    for my $count (1 .. $request->{count}){
        my @values;
        push @values, @{$check->id_columns}
            if $id_displayed;
        for my $edit (@edits) {
          push @values, $request->{"${edit}_$count"};
        }
        push @values, map { $_ ne '' ? MIME::Base64::decode($_) : undef} split(/,/,$request->{"id_$count"})
           if ! $check->{insert};

        my $rv = $sth->execute(@values) ||
            $request->error($sth->errstr);
        return LedgerSMB::PSGI::Util::internal_server_error(
            qq{Upgrade query affected $rv rows, while a single row was expected})
                if $rv != 1;
    }
    $sth->finish();
    $dbh->commit;
    return upgrade($request);
}

=item create_db

 Beginning of the new database workflow

=cut

sub create_db {
    my ($request) = @_;

    my ($reauth, $database) = _get_database($request);
    return $reauth if $reauth;

    my $version_info = $database->get_info;
    $request->{login_name} = $version_info->{username};
    if ($version_info->{status} ne 'does not exist') {
        $request->{message} = $request->{_locale}->text(
            'Database exists.');
        $request->{operation} =
            $request->{_locale}->text('Login?');
        $request->{next_action} = 'login';

        my $template = LedgerSMB::Template->new_UI(
            $request,
            template => 'setup/confirm_operation',
        );
        return $template->render($request);
    }

    my $rc = $database->create_and_load();
    $logger->info("create_and_load rc=$rc");

    return select_coa($request);
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

    if ($request->{coa_lc} and $request->{coa_lc} =~ /\.\./ ){
        die $request->{_locale}->text('Access Denied');
    }

    if ($request->{coa_lc}){
        if ($request->{chart}){
            my ($reauth, $database) = _get_database($request);
            return $reauth if $reauth;

            $database->load_coa(
                {
                    country => $request->{coa_lc},
                    chart => $request->{chart},
                    gifi => $request->{gifi},
                    sic => $request->{sic}
                });

           return template_screen($request);
        } else {
            opendir(CHART, "sql/coa/$request->{coa_lc}/chart");
            @{$request->{charts}} =
                map +{ name => $_ },
                sort(grep !/^(\.|[Ss]ample.*)/,
                      readdir(CHART));
            closedir(CHART);

            opendir(GIFI, "sql/coa/$request->{coa_lc}/gifi");
            @{$request->{gifis}} =
                map +{ name => $_ },
                sort(grep !/^(\.|[Ss]ample.*)/,
                      readdir(GIFI));
            closedir(GIFI);

            if (-e "sql/coa/$request->{coa_lc}/sic") {
                opendir(SIC, "sql/coa/$request->{coa_lc}/sic");
                @{$request->{sics}} =
                    map +{ name => $_ },
                    sort(grep !/^(\.|[Ss]ample.*)/,
                         readdir(SIC));
                closedir(SIC);
            }
            else {
                @{$request->{sics}} = ();
            }
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

    my $template = LedgerSMB::Template->new_UI(
        $request,
        template => 'setup/select_coa',
    );
    return $template->render($request);
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

    return template_screen($request);
}


=item _render_user

Renders the new user screen. Common functionality to both the
select_coa and skip_coa functions.

=cut

sub _render_user {
    my ($request) = @_;

    @{$request->{salutations}} = $request->call_procedure(
        funcname => 'person__list_salutations'
    );

    @{$request->{countries}} = $request->call_procedure(
        funcname => 'location_list_country'
    );
    my $locale = $request->{_locale};

    @{$request->{perm_sets}} = (
        {id => '0', label => $locale->text('Manage Users')},
        {id => '1', label => $locale->text('Full Permissions')},
        {id => '-1', label => $locale->text('No changes')},
        );

    my $template = LedgerSMB::Template->new_UI(
        $request,
        template => 'setup/new_user',
        );

    return $template->render($request);
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

    if ( $request->{coa_lc} ) {
        LedgerSMB::Setting->set('default_country',$request->{coa_lc});
    }
    return _render_user($request);
}



=item save_user

Saves the administrative user, and then directs to the login page.

=cut

sub save_user {
    my ($request) = @_;
    $request->{entity_class} = EC_EMPLOYEE;
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
    try { $user->create($request->{password}); }
    catch {
        if ($_ =~ /duplicate user/i){
           $request->{dbh}->rollback;
           $request->{notice} = $request->{_locale}->text(
                       'User already exists. Import?'
            );
           $request->{pls_import} = 1;

           return _render_user($request);
       } else {
           die $_;
       }
    };
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
                                           'users_manage',
                                         ]
        );
   }
   $request->{dbh}->commit;

   return rebuild_modules($request);
}


=item process_and_run_upgrade_script

=cut

sub process_and_run_upgrade_script {
    my ($request, $database, $src_schema, $template) = @_;
    my $dbh = $database->connect({ PrintError => 0, AutoCommit => 0 });
    my $temp = $database->loader_log_filename();

    $dbh->do("CREATE SCHEMA $LedgerSMB::Sysconfig::db_namespace")
    or die "Failed to create schema $LedgerSMB::Sysconfig::db_namespace (" . $dbh->errstr . ')';
    $dbh->commit;

    $database->load_base_schema(
        log     => $temp . '_stdout',
        errlog  => $temp . '_stderr',
        upto_tag=> 'migration-target'
        );

    $dbh->do(q(
       INSERT INTO defaults (setting_key, value)
                     VALUES ('migration_ok', 'no')
     ));
    $dbh->do(qq(
       INSERT INTO defaults (setting_key, value)
                     VALUES ('migration_src_schema', '$src_schema')
     ));
    $dbh->commit;

    my $dbtemplate = LedgerSMB::Template->new(
        user => {},
        path => 'sql/upgrade',
        template => $template,
        format_options => {extension => 'sql'},
        format => 'TXT' );

    $dbtemplate->render($request, {VERSION_COMPARE => \&Version::Compare::version_compare});

    my $tempfile = File::Temp->new();
    print $tempfile $dbtemplate->{output}
       or die q{Failed to create upgrade instructions to be sent to 'psql'};
    close $tempfile
       or warn 'Failed to close temporary file';

    $database->run_file(
        file => $tempfile->filename,
        stdout_log => $temp . '_stdout',
        errlog => $temp . '_stderr'
        );

    my $sth = $dbh->prepare(q(select value='yes'
                                 from defaults
                                where setting_key='migration_ok'));
    $sth->execute();

    my ($success) = $sth->fetchrow_array();
    $sth->finish();

    $request->error(qq(Upgrade failed;
           logs can be found in
           ${temp}_stdout and ${temp}_stderr))
    if ! $success;

    $dbh->do(q{delete from defaults where setting_key like 'migration_%'});
    $dbh->commit;

    # the schema was left incomplete when we created it, in order to provide
    # a frozen (fixed) migration target. Now, however, we need to apply the
    # changes from the remaining database schema management scripts to
    # make the schema a complete one.
    rebuild_modules($request,$database);

    # If users are added to the user table, and appropriat roles created, this
    # then grants the base_user permission to them.  Note it only affects users
    # found also in pg_roles, so as to avoid errors.  --CT
    $dbh->do(q{SELECT admin__add_user_to_role(username, 'base_user')
                from users WHERE username IN (select rolname from pg_roles)});

    $dbh->commit;
    return $dbh->disconnect;
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
    $dbh->do("ALTER SCHEMA $LedgerSMB::Sysconfig::db_namespace
                RENAME TO lsmb$v")
        or die "Can't rename schema '$LedgerSMB::Sysconfig::db_namespace': "
        . $dbh->errstr();
    $dbh->commit;

    process_and_run_upgrade_script($request, $database, "lsmb$v",
                   "$dbinfo->{version}-$CURRENT_MINOR_VERSION");

    if ($v ne '1.2'){
        $request->{only_templates} = 1;
    }

    my $templates = LedgerSMB::Setting->get('templates');
    if ($templates){
       $request->{template_dir} = $templates;
       return load_templates($request);
    } else {
       return template_screen($request);
    }
}

=item run_sl28_migration


=cut

sub run_sl28_migration {
    my ($request) = @_;
    my $database = _init_db($request);

    my $dbh = $request->{dbh};
    $dbh->do('ALTER SCHEMA public RENAME TO sl28');
    $dbh->commit;

    process_and_run_upgrade_script($request, $database, 'sl28', 'sl3.0');

    return create_initial_user($request);
}

=item run_sl30_migration


=cut

sub run_sl30_migration {
    my ($request) = @_;
    my $database = _init_db($request);

    my $dbh = $request->{dbh};
    $dbh->do('ALTER SCHEMA public RENAME TO sl30');
    $dbh->commit;

    process_and_run_upgrade_script($request, $database, 'sl30', 'sl3.0');

    return create_initial_user($request);
}


=item create_initial_user

=cut

sub create_initial_user {
    my ($request) = @_;
    return _render_new_user($request);
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

    my $template = LedgerSMB::Template->new_UI(
        $request,
        template => 'setup/edit_user',
    );
    my $template_data = {
                        request => $request,
                           user => $user_obj,
                          roles => $all_roles,
            };

    return $template->render($template_data);
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

    return edit_user_roles($request);
}


=item reset_password

=cut

sub reset_password {
    my ($request) = @_;

    _init_db($request);
    my $user = LedgerSMB::DBObject::User->new(base => $request, copy=>'all');
    my $result = $user->save();

    $request->{password} = '';

    return edit_user_roles($request);
}



=item cancel

Cancels work.  Returns to login screen.

=cut
sub cancel{
    return __default(@_);
}

=item force

Force work.  Forgets unmatching tests, applies a curing statement and move on.

=cut

sub force{
    my ($request) = @_;
    my $database = _init_db($request);

    my $test = first { $_->name eq $request->{check} }
                    LedgerSMB::Upgrade_Tests->get_tests();

    for my $force_query ( @{$test->{force_queries}}) {
        my $dbh = $request->{dbh};
        $dbh->do($force_query);
        $dbh->commit;
    }
    return upgrade($request);
}

=item skip

Mark the test to be skipped

=cut

sub skip {
    my ($request) = @_;

    $request->{"skip_$request->{check}"} = 'On';
    return upgrade($request);
}

=item rebuild_modules

This method rebuilds the modules and sets the version setting in the defaults
table to the version of the LedgerSMB request object.  This is used when moving
between versions on a stable branch (typically upgrading)

=cut

sub rebuild_modules {
    my ($request, $database) = @_;
    $database //= _init_db($request);

    # The order is important here:
    #  New modules should be able to depend on the latest changes
    #  e.g. table definitions, etc.

    my $HTML = html_formatter_context {
        return ! $database->apply_changes( checks => 1 );
    } $request;

    return [ HTTP_OK,
             [ 'Content-Type' => 'text/html; charset=UTF-8' ],
             [ map { encode_utf8($_) } @$HTML ]
        ]
        if $HTML;

    $database->upgrade_modules('LOADORDER', $LedgerSMB::VERSION)
        or die 'Upgrade failed.';
    return complete($request);
}

=item complete

Gets the statistics info and shows the complete screen.

=cut

sub complete {
    my ($request) = @_;
    my $database = _init_db($request);
    my $temp = $database->loader_log_filename();
    $request->{lsmb_info} = $database->stats();
    my $template = LedgerSMB::Template->new_UI(
        $request,
        template => 'setup/complete',
    );
    return $template->render($request);
}

=item system_info

Asks the various modules for system and version info, showing the result

=cut

sub system_info {
    my ($request) = @_;
    my $database = _init_db($request);

    # the intent here is to get a much more sophisticated system which
    # asks registered modules for their system and dependency info
    my $info = {
        db => $database->get_info->{system_info},
        system => LedgerSMB::system_info()->{system},
        environment => \%ENV,
        modules => \%INC,
    };
    $request->{info} = $info;
    return LedgerSMB::Template->new_UI(
        $request,
        template => 'setup/system_info',
        )->render($request);
}


=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011-2018 LedgerSMB Core Team.
This file is licensed under the GNU General Public License version 2,
or at your option any later version.  Please see the included
License.txt for details.

=cut


1;
