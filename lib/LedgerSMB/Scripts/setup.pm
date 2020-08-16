
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
use HTTP::Status qw( HTTP_OK HTTP_UNAUTHORIZED );
use Log::Log4perl;
use MIME::Base64;
use Scope::Guard;
use Try::Tiny;

use LedgerSMB;
use LedgerSMB::App_State;
use LedgerSMB::Database;
use LedgerSMB::Database::Config;
use LedgerSMB::DBObject::Admin;
use LedgerSMB::DBObject::User;
use LedgerSMB::Entity::User;
use LedgerSMB::Entity::Person::Employee;
use LedgerSMB::Locale;
use LedgerSMB::Magic qw( EC_EMPLOYEE HTTP_454 PERL_TIME_EPOCH );
use LedgerSMB::Mailer;
use LedgerSMB::PGDate;
use LedgerSMB::PSGI::Util;
use LedgerSMB::Setting;
use LedgerSMB::Setup::SchemaChecks qw( html_formatter_context );
use LedgerSMB::Sysconfig;
use LedgerSMB::Template::UI;
use LedgerSMB::Template::DB;
use LedgerSMB::Database::Upgrade;


my $logger = Log::Log4perl->get_logger('LedgerSMB::Scripts::setup');
my $CURRENT_MINOR_VERSION;
if ( $LedgerSMB::VERSION =~ /(\d+\.\d+)./ ) {
    $CURRENT_MINOR_VERSION = $1;
}

=item authenticate

This method is a remnant of authentication shared with
login.pl.

=cut

sub authenticate {
    my ($request) = @_;
    my $creds = $request->{_req}->env->{'lsmb.auth'}->get_credentials;

    return [ HTTP_UNAUTHORIZED,
             [ 'WWW-Authenticate' => 'Basic realm="LedgerSMB"',
               'Content-Type' => 'text/text; charset=UTF-8' ],
             [ 'Please enter your credentials' ] ]
        if ! defined $creds->{password};

    return [ HTTP_OK,
             [ 'Content-Type' => 'text/plain; charset=utf-8' ],
             [ 'Success' ] ];
}


sub __default {

    my ($request) = @_;
    my $template = LedgerSMB::Template::UI->new_UI;
    return $template->render($request, 'setup/credentials', $request);
}

sub _get_database {
    my ($request) = @_;
    my $creds = $request->{_req}->env->{'lsmb.auth'}->get_credentials;
    $request->{login} = $creds->{login};

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
                dbname   => $request->{database},
                schema   => LedgerSMB::Sysconfig::db_namespace(),
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

    return (undef, $database);
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
        version => '1.8',
        message => $request->{_locale}->text('LedgerSMB 1.8 db found.'),
        operation => $request->{_locale}->text('Rebuild/Upgrade?'),
        next_action => 'rebuild_modules' },
      { appname => 'ledgersmb',
        version => '1.9',
        message => $request->{_locale}->text('LedgerSMB 1.9 db found.'),
        operation => $request->{_locale}->text('Rebuild/Upgrade?'),
        next_action => 'rebuild_modules' },
      { appname => 'ledgersmb',
        version => undef,
        message => $request->{_locale}->text('Unsupported LedgerSMB version detected.'),
        operation => $request->{_locale}->text('Cancel'),
        next_action => 'cancel' } );
}


sub _sanity_checks {
    my $checks = LedgerSMB::Database->verify_helpers(helpers => [ 'psql' ]);

    die q{Unable to execute 'psql'} unless $checks->{psql};
}


sub login {
    my ($request) = @_;
    if (!$request->{database}){
        return list_databases($request);
    }
    my ($reauth, $database) = _get_database($request);
    return $reauth if $reauth;

    my $server_info = $database->server_version;

    my $version_info = $database->get_info();

    ($reauth) = _init_db($request);
    return $reauth if $reauth;

    _sanity_checks();
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
    my $template = LedgerSMB::Template::UI->new_UI;
    return $template->render($request, 'setup/confirm_operation', $request);
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

    my $template = LedgerSMB::Template::UI->new_UI;
    return $template->render($request, 'setup/list_databases', $request);
}

=item list_users
Lists all users in the selected database

=cut

sub list_users {
    my ($request) = @_;
    my ($reauth) = _init_db($request);
    return $reauth if $reauth;

    my $user = LedgerSMB::DBObject::User->new();
    $user->set_dbh($request->{dbh});
    my $users = $user->get_all_users;
    $request->{users} = [];
    for my $u (@$users) {
        push @{$request->{users}}, {row_id => $u->{id}, name => $u->{username} };
    }
    my $template = LedgerSMB::Template::UI->new_UI;
    return $template->render($request, 'setup/list_users', $request);
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
    my $template = LedgerSMB::Template::UI->new_UI;
    return $template->render($request, 'setup/begin_backup', $request);
};


=item run_backup

Runs the backup.  If backup_type is set to email, emails the

=cut

sub run_backup {
    my $request = shift @_;
    my ($reauth, $database) = _get_database($request);
    return $reauth if $reauth;

    my $backuptype;
    my $backupfile;
    my $mimetype;

    if ($request->{backup} eq 'roles') {
        $backupfile = $database->backup_globals;
        $backuptype = 'roles';
        $mimetype = 'text/x-sql';
    }
    elsif ($request->{backup} eq 'db') {
        $backupfile = $database->backup;
        $backuptype = 'db';
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
            filename => "ledgersmb-$backuptype-" . time . '.sqlc',
            file     => $backupfile,
        );
        $mail->send;
        unlink $backupfile;
        my $template = LedgerSMB::Template::UI->new_UI;
        return $template->render($request, 'setup/complete', $request);
    }
    elsif ($request->{backup_type} eq 'browser') {
        my $attachment_name = "ledgersmb-$backuptype-" . time . '.sqlc';
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

    my $template = LedgerSMB::Template::UI->new_UI;

    return $template->render($request, 'setup/complete_migration_revert',
                             $request);
}

=item template_screen

Shows the screen for loading templates.  This should appear before loading
the user.

=cut

sub template_screen {
    my ($request, $entrypoint) = @_;
    $request->{template_dirs} =
        [ map { +{ text => $_, value => $_ } }
          keys %{ LedgerSMB::Database::Config->new->templates } ];
    return LedgerSMB::Template::UI->new_UI
        ->render($request, 'setup/template_info',
                 { %$request, templates_action => $entrypoint });
}

=item load_templates

This bulk loads the templates.  Expectated inputs are template_dir and
optionally only_templates (which if true returns to the confirmation screen
and not the user creation screen.

=cut

sub _save_templates {
    my ($request, $entrypoint) = @_;
    my $templates = LedgerSMB::Database::Config->new->templates;

    return template_screen($request, $entrypoint)
        if not exists $templates->{$request->{template_dir}};

    my ($reauth) = _init_db($request);
    return $reauth if $reauth;

    my $dbh = $request->{dbh};

    for my $template (@{$templates->{$request->{template_dir}}}) {
       my $dbtemp = LedgerSMB::Template::DB->get_from_file($template);
       $dbtemp->save;
    }

    return;
}

sub load_templates {
    my ($request) = @_;

    return (_save_templates($request, 'load_templates')
            or login($request));
}


=item upgrade


=cut

my %upgrade_run_step = (
    'sql-ledger/2.7' => '_initial_sl27',
    'sql-ledger/2.8' => '_initial_sl28',
    'sql-ledger/3.0' => '_initial_sl30',
    'ledgersmb/1.2'  => '_initial_ls12',
    'ledgersmb/1.3'  => '_initial_ls13'
    );

# Note that by the time we get to these steps,
# all upgrade checks have already been executed
my %upgrade_next_steps = (
    # The protocol for each of the right-hand sides here:

    # * The right-hand sides are all subroutine names in this module
    # * Each subroutine returns either
    #   * a PSGI-triplet
    #     The returned page posts its interaction back to the entrypoint
    #   * the result of a call to _dispatch_upgrade_workflow
    #     called with two arguments: the request environment and its own name
    #
    # This makes sure that the steps in the workflow are correctly
    # "stepped through" without there being an explicit or hard-coded
    # dependency or sequence between steps.

    # new database
    _create_db             => '_select_coa',
    _select_coa            => '_select_templates',

    #sl28 specific
    _initial_sl28          => '_run_sl28_upgrade',
    _run_sl28_upgrade      => '_post_sl28_migration',
    _post_sl28_migration   => '_select_templates',

    #sl30 specific
    _initial_sl30          => '_run_sl30_upgrade',
    _run_sl30_upgrade      => '_post_sl30_migration',
    _post_sl30_migration   => '_select_templates',

    #lsmb12 specific
    _initial_ls12          => '_run_ls12_upgrade',
    _run_ls12_upgrade      => '_post_ls12_migration',
    _post_ls12_migration   => '_select_templates',

    #lsmb13 specific
    _initial_ls13          => '_run_ls13_upgrade',
    _run_ls13_upgrade      => '_post_ls13_migration',
    _post_ls13_migration   => '_load_templates',

    # common final steps
#   _migrate_users could be used to create sl and lsmb12 users
#   _select_templates      => '_migrate_users',
#   _migrate_users         => '_complete',
    _select_templates      => '_create_initial_user',
    _load_templates        => '_complete',
    _create_initial_user   => '_complete',
    );

sub _dispatch_upgrade_workflow {
    my ($request, $step_name) = @_;

    if (my $next = $upgrade_next_steps{$step_name}) {
        return __PACKAGE__->can($next)->($request);
    }

    die "Upgrade workflow error: no next step for '$step_name'";
}

sub _select_coa {
    my ($request) = @_;
    my ($reauth, $database) = _init_db($request);
    return $reauth if $reauth;

    return (select_coa($request)
            or _dispatch_upgrade_workflow($request, '_select_coa'));
}

sub _process_and_run_upgrade_script {
    my ($request, $type) = @_;
    my ($reauth, $database) = _init_db($request);
    return $reauth if $reauth;

    my $upgrade = LedgerSMB::Database::Upgrade->new(
        database => $database,
        type     => $type,
        );
    $upgrade->run_upgrade_script(
        {
            %{$request}{qw( default_country default_ap default_ar
                            slschema lsmbschema )}
        });
    $upgrade->run_post_upgrade_steps;

    return;
}

sub _run_sl28_upgrade {
    my ($request) = @_;

    return (_process_and_run_upgrade_script($request, 'sql-ledger/2.8')
            or _dispatch_upgrade_workflow($request, '_run_sl28_upgrade'));
}

sub _run_sl30_upgrade {
    my ($request) = @_;

    return (_process_and_run_upgrade_script($request, 'sql-ledger/3.0')
            or _dispatch_upgrade_workflow($request, '_run_sl30_upgrade'));
}

sub _run_ls12_upgrade {
    my ($request) = @_;

    return (_process_and_run_upgrade_script($request, 'ledgersmb/1.2')
            or _dispatch_upgrade_workflow($request, '_run_ls12_upgrade'));
}

sub _run_ls13_upgrade {
    my ($request) = @_;

    return (_process_and_run_upgrade_script($request, 'ledgersmb/1.3')
            or _dispatch_upgrade_workflow($request, '_run_ls13_upgrade'));
}


sub _post_sl28_migration {
    my ($request) = @_;
    my ($reauth, $database) = _init_db($request);
    return $reauth if $reauth;

    return (_post_migration_schema_upgrade($request, $database,
                                          '_post_sl28_migration')
            or _dispatch_upgrade_workflow($request, '_post_sl28_migration'));
}

sub _post_sl30_migration {
    my ($request) = @_;
    my ($reauth, $database) = _init_db($request);
    return $reauth if $reauth;

    return (_post_migration_schema_upgrade($request, $database,
                                          '_post_sl30_migration')
            or _dispatch_upgrade_workflow($request, '_post_sl30_migration'));
}

sub _post_ls12_migration {
    my ($request) = @_;
    my ($reauth, $database) = _init_db($request);
    return $reauth if $reauth;

    return (_post_migration_schema_upgrade($request, $database,
                                          '_post_ls12_migration')
            or _dispatch_upgrade_workflow($request, '_post_ls12_migration'));
}

sub _post_ls13_migration {
    my ($request) = @_;
    my ($reauth, $database) = _init_db($request);
    return $reauth if $reauth;

    return (_post_migration_schema_upgrade($request, $database,
                                          '_post_ls13_migration')
            or _dispatch_upgrade_workflow($request, '_post_ls13_migration'));
}


sub _select_templates {
    my ($request) = @_;
    my ($reauth, $database) = _init_db($request);
    return $reauth if $reauth;


    return (_save_templates($request, '_select_templates')
            or _dispatch_upgrade_workflow($request, '_select_templates'));
}

sub _load_templates {
    my ($request) = @_;
    my ($reauth, $database) = _init_db($request);
    return $reauth if $reauth;

    my $dbh = $request->{dbh};
    #### Suppress selecting templates!
    ### Suppress next steps in load templates!

    $request->{template_dir} //=
        LedgerSMB::Setting->new(dbh => $dbh)->get('templates');
    return (_save_templates($request, '_load_templates')
            or _dispatch_upgrade_workflow($request, '_load_templates'));
}




sub upgrade {
    my ($request) = @_;
    my ($reauth, $database) = _init_db($request);
    return $reauth if $reauth;

    my $dbinfo = $database->get_info();
    my $upgrade_type = "$dbinfo->{appname}/$dbinfo->{version}";
    my $locale = $request->{_locale};

    $request->{dbh}->{AutoCommit} = 0;

    my $upgrade = LedgerSMB::Database::Upgrade->new(
        database => $database,
        type => $upgrade_type,
        );

    my $rv;
    $upgrade->run_tests(
        sub {
            my ($check, $dbh, $sth) = @_;
            $rv = _failed_check($request, $check, $sth);
        });

    return $rv if $rv;

    my $required_vars = $upgrade->required_vars;
    if (not %$required_vars) {
        $request->{dbh}->rollback();

        return _dispatch_upgrade_workflow($request,
                                          $upgrade_run_step{$upgrade_type});
    }

    my $template = LedgerSMB::Template::UI->new_UI;

    my $step = $upgrade_run_step{$upgrade_type};
    my $upgrade_action = $upgrade_next_steps{$step};
    $request->{upgrade_action} = $upgrade_action;

    die "Upgrade type $upgrade_type not associated with a next step (step: $step)"
        unless $upgrade_action;

    for my $key (keys %$required_vars) {
        my $val = $required_vars->{$key};
        $request->{$key} = (@$val > 1) ? [ {}, @$val ]
            : ($val->[0] ? $val->[0]->{value} : 'null');
    }
    $request->{lsmbversion} = $CURRENT_MINOR_VERSION;
    return $template->render($request, 'setup/upgrade_info', $request);
}

sub _failed_check {
    my ($request, $check, $sth) = @_;

    my %selectable_values =
        %{$check->query_selectable_values($request->{dbh})};

    my $hiddens = {
       check => $check->name,
verify_check => md5_hex($check->test_query),
    database => $request->{database}
    };
    my @skip_keys = grep /^skip_/, keys %$request;
    $hiddens->{@skip_keys} = $request->{@skip_keys};

    my $cols = [];
    for my $column (@{$check->display_cols // []}) {
        my $selectable_value = $selectable_values{$column};

        if (grep { $column eq $_ } @{$check->columns // []}) {
            if ( defined $selectable_value && @$selectable_value ) {
                push @$cols, {
                    col_id => $column,
                    name => $column,
                    type => 'select',
                    options => $selectable_value,
                    default_blank => ( 1 != @$selectable_value ),
                };
            }
            else {
                push @$cols, {
                    col_id => $column,
                    name => $column,
                    type => 'input_text',
                };
            }
        }
        else {
            push @$cols, {
                col_id => $column,
                name => $column,
                type => 'text',
            };
        }
    };
    push @$cols, {
        col_id => 'id',
        type => 'hidden',
    };

    my $rows = [];
    while (my $row = $sth->fetchrow_hashref('NAME_lc')) {
        $row->{row_id} = 1+@$rows;
        $row->{id} =
            join(',', map { MIME::Base64::encode(($row->{$_} // ''), '')}
                 @{$check->id_columns});
        push @$rows, $row;
    }
    $hiddens->{count} = scalar(@$rows);
    $sth->finish();

    my %buttons = map { $_ => 1 } @{$check->buttons};
    my $enabled_buttons;
    for (
        { value => 'fix_tests', label => 'Save and Retry',
          cond => defined($check->{columns})},
        { value => 'cancel',    label => 'Cancel',
          cond => 1                         },
        { value => 'force',     label => 'Force',
          cond => $check->{force_queries}   },
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

    my $template = LedgerSMB::Template::UI->new_UI;
    return $template->render($request, 'setup/migration_step', {
           form               => $request,
           headers            => [
               $request->{_locale}->maketext($check->display_name),
               $request->{_locale}->maketext($check->instructions)
               ],
           columns            => $cols,
           rows               => $rows,
           buttons            => $enabled_buttons,
           hiddens            => $hiddens,
           include_stylesheet => 'setup.css',
    });
}

=item fix_tests

Handles input from the failed test function and then re-runs the migrate db
script.

=cut

sub fix_tests {
    my ($request) = @_;

    my ($reauth, $database) = _init_db($request);
    return $reauth if $reauth;

    my $dbinfo = $database->get_info();
    my $dbh = $request->{dbh};
    $dbh->{AutoCommit} = 0;

    my $upgrade = LedgerSMB::Database::Upgrade->new(
        database => $database,
        type => '.../...',
        );

    my $check = $upgrade->applicable_test_by_name($request->{check});
    die "Inconsistent state fixing data for $request->{check}: "
        . 'found no applicable tests for given identifier'
        unless $check;

    die "Inconsistent state fixing date for $request->{check}: "
        . 'found different test by the same name while fixing data'
        if $request->{verify_check} ne md5_hex($check->test_query);

    my @fixed_rows;
    for my $count (1 .. $request->{count}){
        my %row_data;
        for my $key (@{$check->columns}) {
            $row_data{$key} = $request->{"${key}_$count"};
        }
        @row_data{@{$check->id_columns}} =
            map {
                $_ ne '' ? MIME::Base64::decode($_) : undef
        } split(/,/, $request->{"id_$count"});

        push @fixed_rows, \%row_data;
    }

    $check->fix($dbh, \@fixed_rows);
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

        my $template = LedgerSMB::Template::UI->new_UI;
        return $template->render($request, 'setup/confirm_operation', $request);
    }

    my $rc = $database->create_and_load();
    $logger->info("create_and_load rc=$rc");

    return _dispatch_upgrade_workflow($request, '_create_db');
}

=item select_coa

Selects and loads the COA.

There are three distinct input scenarios here:

coa_lc and chart are set:  load the coa file specified (sql/coa/$coa_lc/$chart)
coa_lc set, chart not set:  select the chart
coa_lc not set:  Select the coa location code

=cut

sub select_coa {
    my ($request) = @_;
    my $coa_data = LedgerSMB::Database::Config->new->charts_of_accounts;

    if ($request->{coa_lc}) {
        my $coa_lc = $request->{coa_lc};
        if (not exists $coa_data->{$coa_lc}) {
            die $request->{_locale}->text('Invalid request');
        }

        for my $coa_type (qw( chart gifi sic )) {
            if ($request->{$coa_type}) {
                if (! grep { $_ eq $request->{$coa_type} }
                    @{$coa_data->{$coa_lc}->{$coa_type}}) {
                    die $request->{_locale}->text('Invalid request');
                }
            }
        }
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

            # successful completion returns 'undef'
            return _dispatch_upgrade_workflow($request, '_select_coa');
        } else {
            for my $select (qw(chart gifi sic)) {
                $request->{"${select}s"} =
                    [ map { +{ name => $_ } }
                      @{$coa_data->{$request->{coa_lc}}->{$select}} ];
            }
       }
    } else {
        $request->{coa_lcs} = [ sort { $a->{name} cmp $b->{name} }
                                values %$coa_data ];
    }

    my $template = LedgerSMB::Template::UI->new_UI;
    return $template->render($request, 'setup/select_coa', $request);
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

    return _dispatch_upgrade_workflow($request, '_select_coa')
}


=item _render_user

Renders the new user screen. Common functionality to both the
select_coa and skip_coa functions.

=cut

sub _render_user {
    my ($request, $entrypoint) = @_;

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

    my $template = LedgerSMB::Template::UI->new_UI;
    return $template->render($request, 'setup/new_user',
                             { %$request, save_action => $entrypoint });
}

=item _render_new_user

Renders the new user screen. Common functionality to both the
select_coa and skip_coa functions.

=cut

sub _render_new_user {
    my ($request, $entrypoint) = @_;

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


    my ($reauth) = _init_db($request);
    return $reauth if $reauth;

    $request->{dbh}->{AutoCommit} = 0;

    if ( $request->{coa_lc} ) {
        LedgerSMB::Setting->new(%$request)->set('default_country',$request->{coa_lc});
    }
    return _render_user($request, $entrypoint);
}



=item _save_user

Saves the administrative user, and then directs to the login page.

=cut

sub _save_user {
    my ($request, $entrypoint) = @_;
    $request->{entity_class} = EC_EMPLOYEE;
    $request->{name} = "$request->{last_name}, $request->{first_name}";

    my ($reauth) = _init_db($request);
    return $reauth if $reauth;

    $request->{dbh}->{AutoCommit} = 0;

    $request->{control_code} = $request->{employeenumber};
    $request->{dob} = LedgerSMB::PGDate->from_input($request->{dob});
    my $emp = LedgerSMB::Entity::Person::Employee->new(%$request);
    $emp->save;
    $request->{entity_id} = $emp->entity_id;
    my $user = LedgerSMB::Entity::User->new(%$request);

    my $rerendered_user =
        try { $user->create($request->{password}); 0 }
    catch {
        if ($_ =~ /duplicate user/i){
           $request->{dbh}->rollback;
           $request->{notice} = $request->{_locale}->text(
                       'User already exists. Import?'
            );
           $request->{pls_import} = 1;

           # return from the 'catch' block
           return _render_user($request, $entrypoint);
       } else {
           die $_;
       }
    };
    return $rerendered_user if $rerendered_user;


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

    return;
}



sub _post_migration_schema_upgrade {
    my ($request, $database, $entrypoint) = @_;
    my $dbh = $request->{dbh};
    my $guard = Scope::Guard->new(
        sub {
            if ($dbh) {
                $dbh->rollback;
                $dbh->disconnect;
            }
        });
    my $reauth;

    ($reauth, $database) = _init_db($request) if not $database;
    return $reauth if $reauth;


    if (my $rv = _rebuild_modules($request, $entrypoint, $database)) {
        ### should we *really* commit??
        ### or should we treat *any* return value as problematic
        ### (and leave committing the transaction to the inner scope?
        if ($rv->[0] == 200) {
            $dbh->commit;
            $guard->dismiss;
        }

        return $rv;
    }

    # If users are added to the user table, and appropriate roles created, this
    # then grants the base_user permission to them.  Note it only affects users
    # found also in pg_roles, so as to avoid errors.  --CT
    $guard->dismiss;
    $dbh->do(q{SELECT admin__add_user_to_role(username, 'base_user')
                 FROM users WHERE username IN (select rolname from pg_roles)});

    $dbh->commit;
    $dbh->disconnect;

    return;
}

=item add_user

=cut

sub _create_initial_user {
    my ($request) = @_;
    return _render_new_user($request, '_create_initial_user')
        unless $request->{username};

    return (_save_user($request, '_create_initial_user')
            or _dispatch_upgrade_workflow($request, '_create_initial_user'));
}

sub add_user {
    my ($request) = @_;

    return (_create_initial_user($request)
            or login($request));
}

=item edit_user_roles

=cut

sub edit_user_roles {
    my ($request) = @_;

    my $reauth;
    ($reauth) = _init_db($request)
        unless $request->{dbh};
    return $reauth if $reauth;

    my $admin = LedgerSMB::DBObject::Admin->new();
    $admin->set_dbh($request->{dbh});
    my $all_roles = $admin->get_roles($request->{database});

    my $user_obj = LedgerSMB::DBObject::User->new();
    $user_obj->set_dbh($request->{dbh});
    $user_obj->get($request->{id});

    # LedgerSMB::DBObject::User doesn't retrieve the username
    # field from the users table (nor any of the other values from it,
    # really) and there's no stored procedure to do so.
    # The name 'admin__get_user' is already taken, but takes the entity_id
    # as its argument... So, we're going brute force here, for 1.4
    my @user_rec = grep { $_->{id} == $request->{id} }
          @{$user_obj->get_all_users};

    $user_obj->{username} = $user_rec[0]->{username};

    my $template = LedgerSMB::Template::UI->new_UI;
    my $template_data = {
                        request => $request,
                           user => $user_obj,
                          roles => $all_roles,
            };

    return $template->render($request, 'setup/edit_user', $template_data);
}

=item save_user_roles

=cut

sub save_user_roles {
    my ($request) = @_;

    my ($reauth) = _init_db($request);
    return $reauth if $reauth;

    $request->{user_id} = $request->{id};
    my $admin = LedgerSMB::DBObject::Admin->new(%$request);
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

    my ($reauth) = _init_db($request);
    return $reauth if $reauth;

    my $user = LedgerSMB::Entity::User->new(%$request);
    $user->reset_password($request->{password});

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

sub force {
    my ($request) = @_;
    my ($reauth, $database) = _init_db($request);
    return $reauth if $reauth;

    my $upgrade = LedgerSMB::Database::Upgrade->new(
        database => $database,
        type => '.../...',
        );

    my $test = $upgrade->applicable_test_by_name($request->{check});
    $test->force($request->{dbh});

    return upgrade($request);
}

=item rebuild_modules

This method rebuilds the modules and sets the version setting in the defaults
table to the version of the LedgerSMB request object.  This is used when moving
between versions on a stable branch (typically upgrading)

=cut

sub _rebuild_modules {
    my ($request, $entrypoint, $database) = @_;

    if (not defined $database) {
        my ($reauth, $db) = _init_db($request);
        return $reauth if $reauth;

        $database = $db;
    }

    # The order is important here:
    #  New modules should be able to depend on the latest changes
    #  e.g. table definitions, etc.

    $request->{resubmit_action} //= $entrypoint;
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

    return;
}

sub rebuild_modules {
    my ($request) = @_;

    if (my $rv = _rebuild_modules($request, 'rebuild_modules')) {
        return $rv;
    }
    return complete($request);
}

=item complete

Gets the statistics info and shows the complete screen.

=cut

sub _complete {
    my ($request) = @_;
    my ($reauth, $database) = _init_db($request);
    return $reauth if $reauth;

    my $temp = $database->loader_log_filename();
    $request->{lsmb_info} = $database->stats();
    my $template = LedgerSMB::Template::UI->new_UI;
    return $template->render($request, 'setup/complete', $request);
}

sub complete { return _complete(@_) };

=item system_info

Asks the various modules for system and version info, showing the result

=cut

sub system_info {
    my ($request) = @_;
    my ($reauth, $database) = _init_db($request);
    return $reauth if $reauth;

    # the intent here is to get a much more sophisticated system which
    # asks registered modules for their system and dependency info
    my $info = {
        db => $database->get_info->{system_info},
        system => LedgerSMB::system_info()->{system},
        environment => \%ENV,
        modules => \%INC,
    };
    $request->{info} = $info;
    return LedgerSMB::Template::UI->new_UI
        ->render($request, 'setup/system_info', $request);
}


=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011-2018 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
