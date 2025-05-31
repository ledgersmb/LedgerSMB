
use v5.36;
use warnings;
use experimental 'try';

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

use version;

use Carp;
use Digest::MD5 qw(md5_hex);
use Email::MessageID;
use Email::Sender::Simple;
use Email::Stuffer;
use Encode;
use File::Spec;
use HTML::Escape;
use HTTP::Status qw( HTTP_OK HTTP_INTERNAL_SERVER_ERROR HTTP_UNAUTHORIZED );
use Log::Any;
use MIME::Base64;
use Scope::Guard;

use LedgerSMB;
use LedgerSMB::App_State;
use LedgerSMB::Company;
use LedgerSMB::Database;
use LedgerSMB::Database::Config;
use LedgerSMB::Database::ConsistencyChecks;
use LedgerSMB::Entity::User;
use LedgerSMB::Entity::Person::Employee;
use LedgerSMB::I18N;
use LedgerSMB::Magic qw( EC_EMPLOYEE HTTP_454 PERL_TIME_EPOCH );
use LedgerSMB::PGDate;
use LedgerSMB::PSGI::Util;
use LedgerSMB::Setup::SchemaChecks qw( html_formatter_context );
use LedgerSMB::Template::DB;
use LedgerSMB::Database::Upgrade;
use LedgerSMB::User;



my $logger = Log::Any->get_logger(category => 'LedgerSMB::Scripts::setup');
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
    my $template = $request->{_wire}->get('ui');
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
            $request->{_wire}->get( 'db' )->instance(
                user     => $creds->{login},
                password => $creds->{password},
                dbname   => $request->{database},
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
        version => '1.10',
        message => $request->{_locale}->text('LedgerSMB 1.10 db found.'),
        operation => $request->{_locale}->text('Rebuild/Upgrade?'),
        next_action => 'rebuild_modules' },
      { appname => 'ledgersmb',
        version => '1.11',
        message => $request->{_locale}->text('LedgerSMB 1.11 db found.'),
        operation => $request->{_locale}->text('Rebuild/Upgrade?'),
        next_action => 'rebuild_modules' },
      { appname => 'ledgersmb',
        version => '1.12',
        message => $request->{_locale}->text('LedgerSMB 1.12 db found.'),
        operation => $request->{_locale}->text('Rebuild/Upgrade?'),
        next_action => 'rebuild_modules' },
      { appname => 'ledgersmb',
        version => '1.13',
        message => $request->{_locale}->text('LedgerSMB 1.13 db found.'),
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

    my $template = $request->{_wire}->get('ui');
    my $settings = $request->{_wire}->get( 'setup_settings' );
    my $auth_db = ($settings and $settings->{auth_db}) // 'postgres';
    # Schema search path set in upgrade() needs to match that set here
    $database->{connect_data}->{options} = "-c search_path=$database->{schema},public";

    my $version_info = $database->get_info($auth_db);

    my $server_version     = version->parse(
        $version_info->{system_info}->{'PostgreSQL (server)'}
        );
    my $server_min_version = version->parse('10.0.0');

    return $template->render($request,
                             'setup/mismatch',
                             {
                                 found    => "$server_version",
                                 required => "$server_min_version",
                             })
        if $server_version < $server_min_version;

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
    return $template->render($request, 'setup/confirm_operation', $request);
}

=item list_databases
Lists all databases as hyperlinks to continue operations.

=cut

sub list_databases {
    my ($request) = @_;
    my ($reauth, $database) = _get_database($request);
    return $reauth if $reauth;

    my @results = $database->list_dbs(
        $request->{_wire}->get('setup_settings')->{admin_db}
        );
    $request->{dbs} = [];
    # Ideally we would extend DBAdmin->list_dbs to accept an argument containing a list of databases to exclude using a method similar to that shown at https://git.framasoft.org/framasoft/OCB/commit/7a6e94edd83e9e73e56d2d148e3238618
    # also, we should add a new function DBAdmin->list_dbs_this_user which only returns db's the currently auth'd user has access to. Once again the framasoft.org link shows a method of doing this
    # for now we simply use a fixed regex. It will cover many if not most use cases.
    @{$request->{dbs}} = map {+{ row_id => $_, db  => $_ }} grep { ! m/^(postgres|template0|template1)$/ } @results ;

    my $template = $request->{_wire}->get('ui');
    return $template->render($request, 'setup/list_databases', $request);
}

=item list_users
Lists all users in the selected database

=cut

sub list_users {
    my ($request) = @_;
    my ($reauth) = _init_db($request);
    return $reauth if $reauth;

    my @users = LedgerSMB::User->get_all_users($request);
    $request->{users} = [];
    for my $user (@users) {
        push @{$request->{users}}, {row_id => $user->{id}, name => $user->{username} };
    }
    my $template = $request->{_wire}->get('ui');
    return $template->render($request, 'setup/list_users', $request);
}

=item copy_db

Copies db to the name of $request->{new_name}

=cut

sub copy_db {
    my ($request) = @_;
    if (my $csrf = $request->verify_csrf) {
        return $csrf;
    }
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
    if (my $csrf = $request->verify_csrf) {
        return $csrf;
    }
    $request->{backup} = 'db';
    return _begin_backup($request);
}

=item backup_roles

Backs up roles only (for all db's)

=cut

sub backup_roles {
    my $request = shift @_;
    if (my $csrf = $request->verify_csrf) {
        return $csrf;
    }
    $request->{backup} = 'roles';
    return _begin_backup($request);
}

# Private method, basically just passes the inputs on to the next screen.
sub _begin_backup {
    my $request = shift @_;
    $request->{can_email} = eval {
        # when accessing an undefined service, an exception is thrown;
        # suppress the exception: all we want to know is if there is a value
        $request->{_wire}->get( 'miscellaneous/backup_email_from' );
    };
    my $template = $request->{_wire}->get('ui');
    return $template->render($request, 'setup/begin_backup', $request);
};


=item run_backup

Runs the backup.  If backup_type is set to email, emails the

=cut

sub run_backup {
    my $request = shift @_;
    if (my $csrf = $request->verify_csrf) {
        return $csrf;
    }
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

        my $mail = Email::Stuffer
            ->from( $request->{_wire}->get( 'miscellaneous/backup_email_from' ) )
            ->to( $request->{email} )
            ->subject( 'Email of Backup' )
            ->text_body( 'The Backup is Attached',
                         content_type => 'text/plain',
                         charset => 'utf-8' )
            ->header( Email::MessageID->new->in_brackets );
        $mail->attach_file(
            $backupfile,
            content_type => 'application/octet-stream',
            disposition => 'attachment',
            filename => "ledgersmb-$backuptype-" . time . '.sqlc',
            );
        Email::Sender::Simple->send(
            $mail->email,
            {
                transport => $request->{_wire}->get( 'mail' )->{transport},
            });

        unlink $backupfile;
        my $template = $request->{_wire}->get('ui');
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

=item consistency

=cut

sub consistency {
    my ($request) = @_;
    my ($reauth, $database) = _get_database($request);
    return $reauth if $reauth;

    my $dbh = $database->connect({PrintError => 0, AutoCommit => 0});
    my $paths = find_checks($request->{_wire}->get( 'paths/sql' ) );
    my $checks = load_checks( $paths );
    my $results = run_checks( $dbh, $checks );

    return $request->{_wire}->get('ui')->render(
        $request,
        'setup/consistency_results',
        {
            database => $request->{database},
            login    => $request->{login},
            results  => $results
        });
}


=item revert_migration

=cut

sub revert_migration {
    my ($request) = @_;
    if (my $csrf = $request->verify_csrf) {
        return $csrf;
    }
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

    my $template = $request->{_wire}->get('ui');

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
          sort keys %{ LedgerSMB::Database::Config->new(
                           templates_dir => $request->{_wire}->get( 'paths/templates' ),
                           )->templates } ];
    return $request->{_wire}->get('ui')
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
    my $templates = LedgerSMB::Database::Config->new(
        templates_dir => $request->{_wire}->get( 'paths/templates' ),
        )->templates;

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

    if (my $csrf = $request->verify_csrf) {
        return $csrf;
    }
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

    croak "Upgrade workflow error: no next step for '$step_name'";
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

    my $hdr = $request->{_req}->header( 'Accept-Language' );
    my $lang = $request->{_wire}->get( 'default_locale' )->from_header( $hdr );

    my $upgrade = LedgerSMB::Database::Upgrade->new(
        database => $database,
        type     => $type,
        language => $lang
        );
    try {
        my $info = $database->get_info();
        $upgrade->run_upgrade_script(
            {
                sl_version => version->parse($info->{full_version}),
                %{$request}{qw( default_country default_ap default_ar
                                slschema lsmbschema lsmbversion)}
            });
        $upgrade->run_post_upgrade_steps;
    }
    catch ($e) {
        my $error_text = escape_html( $e );
        local $/ = undef;
        my $stdout = '';
        if ( open( my $out, '<:encoding(UTF-8)', $upgrade->logfiles->{out} ) ) {
            $stdout = escape_html( <$out> );
        }
        else {
            $logger->warn(
                "Unable to open psql upgrade script STDOUT logfile: $!"
                );
        }

        my $stderr = '';
        if ( open( my $err, '<:encoding(UTF-8)', $upgrade->logfiles->{err} ) ) {
            $stderr = escape_html( <$err> );
        }
        else {
            $logger->warn(
                "Unable to open psql upgrade script STDERR logfile: $!"
                );
        }

        return [ HTTP_INTERNAL_SERVER_ERROR,
                 [ 'Content-Type' => 'text/html; charset=UTF-8' ],
                 [ <<~EMBEDDED_HTML ] ];
        <html>
          <body>
            <h1>Error!</h1>
            <p><b>$error_text</b></p>

            <h3>STDERR</h3>
            <pre style="max-height:30em;overflow:scroll">$stderr</pre>

            <h3>STDOUT</h3>
            <pre style="max-height:30em;overflow:scroll">$stdout</pre>
          </body>
        </html>
        EMBEDDED_HTML
    };

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

    $request->{template_dir} //= $request->setting->get('templates');
    return (_save_templates($request, '_load_templates')
            or _dispatch_upgrade_workflow($request, '_load_templates'));
}




sub upgrade {
    my ($request) = @_;
    if (my $csrf = $request->verify_csrf) {
        return $csrf;
    }
    my ($reauth, $database) = _init_db($request);
    return $reauth if $reauth;

    my $settings = $request->{_wire}->get( 'setup_settings' );
    my $auth_db = ($settings and $settings->{auth_db}) // 'postgres';
    # Schema search path needs to match that set in login()
    $database->{connect_data}->{options} = "-c search_path=$database->{schema},public";
    my $dbinfo = $database->get_info($auth_db);
    my $upgrade_type = "$dbinfo->{appname}/$dbinfo->{version}";
    my $locale = $request->{_locale};

    $request->{dbh}->{AutoCommit} = 0;

    my $hdr = $request->{_req}->header( 'Accept-Language' );
    my $lang = $request->{_wire}->get( 'default_locale' )->from_header( $hdr );
    my $upgrade = LedgerSMB::Database::Upgrade->new(
        database => $database,
        type     => $upgrade_type,
        language => $lang
        );

    my $rv;
    $logger->debug( "Running upgrade tests for '$upgrade_type'" );
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

    my $template = $request->{_wire}->get('ui');

    my $step = $upgrade_run_step{$upgrade_type};
    my $upgrade_action = $upgrade_next_steps{$step};
    $request->{upgrade_action} = $upgrade_action;

    die "Upgrade type $upgrade_type not associated with a next step (step: $step)"
        unless $upgrade_action;

    for my $key (keys %$required_vars) {
        my $val = $required_vars->{$key};
        $request->{$key} = (ref($val) eq 'ARRAY')
            ? ((@$val > 1) ? [ {}, @$val ]
                          : ($val->[0] ? $val->[0]->{value} : 'null'))
            : $val;
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
                 name => '__action',
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

    my $template = $request->{_wire}->get('ui');
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
           include_stylesheet => 'system/setup.css',
    });
}

=item fix_tests

Handles input from the failed test function and then re-runs the migrate db
script.

=cut

sub fix_tests {
    my ($request) = @_;

    if (my $csrf = $request->verify_csrf) {
        return $csrf;
    }
    my ($reauth, $database) = _init_db($request);
    return $reauth if $reauth;

    my $settings = $request->{_wire}->get( 'setup_settings' );
    my $auth_db = ($settings and $settings->{auth_db}) // 'postgres';
    my $dbinfo = $database->get_info($auth_db);
    my $upgrade_type = "$dbinfo->{appname}/$dbinfo->{version}";
    my $dbh = $request->{dbh};
    $dbh->{AutoCommit} = 0;

    my $hdr = $request->{_req}->header( 'Accept-Language' );
    my $lang = $request->{_wire}->get( 'default_locale' )->from_header( $hdr );
    my $upgrade = LedgerSMB::Database::Upgrade->new(
        database => $database,
        type     => $upgrade_type,
        language => $lang
        );

    my $check = $upgrade->applicable_test_by_name($request->{check});
    die "Inconsistent state fixing data for $request->{check}: "
        . 'found no applicable tests for given identifier'
        unless $check;

    die "Inconsistent state fixing data for $request->{check}: "
        . 'found different test by the same name while fixing data'
        if $request->{verify_check} ne md5_hex($check->test_query);

    my @fixed_rows;
    for my $count (1 .. $request->{count}){
        my %row_data;
        for my $key (@{$check->columns}) {
            $row_data{$key} = $request->{"${key}_$count"};
            $logger->trace( "Setting row $count field $key to $row_data{$key}" );
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

    if (my $csrf = $request->verify_csrf) {
        return $csrf;
    }
    my ($reauth, $database) = _get_database($request);
    return $reauth if $reauth;

    my $settings = $request->{_wire}->get( 'setup_settings' );
    my $auth_db = ($settings and $settings->{auth_db}) // 'postgres';
    my $version_info = $database->get_info($auth_db);
    $request->{login_name} = $version_info->{username};
    if ($version_info->{status} ne 'does not exist') {
        $request->{message} = $request->{_locale}->text(
            'Database exists.');
        $request->{operation} =
            $request->{_locale}->text('Login?');
        $request->{next_action} = 'login';

        my $template = $request->{_wire}->get('ui');
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
    my $hdr = $request->{_req}->header( 'Accept-Language' );
    my $lang = $request->{_wire}->get( 'default_locale' )->from_header( $hdr );
    my $coa_data = LedgerSMB::Database::Config
        ->new( language =>  $lang )
        ->charts_of_accounts;

    my $step;
    if ($request->{coa_lc}) {
        my $coa_lc = $request->{coa_lc};
        if (not exists $coa_data->{$coa_lc}) {
            die $request->{_locale}->text('Invalid request');
        }

        for my $coa_type (qw( chart sic )) {
            if ($request->{$coa_type}) {
                if (! grep { $_ eq $request->{$coa_type} }
                    @{$coa_data->{$coa_lc}->{$coa_type}}) {
                    die $request->{_locale}->text('Invalid request');
                }
            }
        }

        if ($request->{chart}) {
            if (my $csrf = $request->verify_csrf) {
                return $csrf;
            }
            my ($reauth, $database) = _get_database($request);
            return $reauth if $reauth;

            my $c = LedgerSMB::Company->new(
                dbh => $database->connect(),
                )->configuration;
            my $fn = File::Spec->catdir('.', 'locale', 'coa',
                                        $request->{coa_lc}, $request->{chart});
            open my $fh, '<:encoding(UTF-8)', $fn
                or die "Failed to open $fn: $!";
            $c->from_xml($fh);
            $c->dbh->commit;
            $c->dbh->disconnect;
            close $fh
                or warn "Error closing $fn: $!";

            $database->load_sic(
                {
                    country => $request->{coa_lc},
                    sic => $request->{sic}
                });

            # successful completion returns 'undef'
            return _dispatch_upgrade_workflow($request, '_select_coa');
        } else {
            for my $select (qw( chart sic )) {
                $request->{"${select}s"} =
                    [ map { +{ name => $_ } }
                      @{$coa_data->{$request->{coa_lc}}->{$select}} ];
            }
       }
        $step = 'details';
    } else {
        $request->{coa_lcs} = [ sort { $a->{name} cmp $b->{name} }
                                values %$coa_data ];
        $step = 'country';
    }

    my $template = $request->{_wire}->get('ui');
    return $template->render($request, "setup/select_coa_$step", $request);
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

    $request->{countries} = $request->enabled_countries;
    my $locale = $request->{_locale};

    @{$request->{perm_sets}} = (
        {id => '0', label => $locale->text('Manage Users')},
        {id => '1', label => $locale->text('Full Permissions')},
        {id => '-1', label => $locale->text('No changes')},
        );

    my $template = $request->{_wire}->get('ui');
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
        $request->setting->set('default_country',$request->{coa_lc});
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
    my $emp = LedgerSMB::Entity::Person::Employee->new(
        %$request,
        dob => $request->parse_date( $request->{dob} ),
        start_date => $request->parse_date( $request->{start_date} ),
        end_date => $request->parse_date( $request->{end_date} ),
        );
    $emp->save;
    $request->{entity_id} = $emp->entity_id;
    my $user = LedgerSMB::Entity::User->new(%$request);

    try {
        $user->create($request->{password});
    }
    catch ($var) {
        if ($var =~ /duplicate user/i){
            $request->{dbh}->rollback;
            $request->{notice} = $request->{_locale}->text(
                'User already exists. Import?'
                );
            $request->{pls_import} = 1;

            # return from the 'catch' block
            return _render_user($request, $entrypoint);
        }
        else {
            die $var;
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
    if (my $csrf = $request->verify_csrf) {
        return $csrf;
    }

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

    my $template = $request->{_wire}->get('ui');
    my ($user) = $request->call_procedure(
        funcname => 'admin__get_user',
        args     => [ $request->{id} ]);
    return $template->render(
        $request,
        'setup/edit_user',
        {
            request => $request,
            roles   => [
                map {
                    +{
                        name => $_->{rolname},
                        description => ($_->{rolname} =~ s/_/ /gr),
                    }
                }
                $request->call_procedure(funcname => 'admin__get_roles')
                ],
            user    => {
                roles    => [
                    map { $_->{admin__get_roles_for_user} }
                    $request->call_procedure(
                        funcname => 'admin__get_roles_for_user',
                        args     => [ $request->{id} ])
                    ],
                user_id  => $request->{id},
                username => $user->{username},
            }
        });
}

=item save_user_roles

=cut

sub save_user_roles {
    my ($request) = @_;

    if (my $csrf = $request->verify_csrf) {
        return $csrf;
    }
    my ($reauth) = _init_db($request);
    return $reauth if $reauth;

    my ($user) = $request->call_procedure(
        funcname => 'admin__get_user',
        args => [ $request->{id} ] );
    my %active_roles = map {
        $_->{admin__get_roles_for_user} => 1
    } $request->call_procedure(
        funcname => 'admin__get_roles_for_user',
        args     => [ $request->{id} ]);

    for my $role (
        map { $_->{rolname} }
        $request->call_procedure( funcname => 'admin__get_roles' ) ) {
        if ($active_roles{$role} and not $request->{$role}) {
            # remove
            $request->call_procedure(
                funcname => 'admin__remove_user_from_role',
                args     => [ $user->{username}, $role ] );
        }
        elsif ($request->{$role} and not $active_roles{$role}) {
            # add
            $request->call_procedure(
                funcname => 'admin__add_user_to_role',
                args     => [ $user->{username}, $role ] );
        }
    }

    return edit_user_roles($request);
}


=item reset_password

=cut

sub reset_password {
    my ($request) = @_;

    if (my $csrf = $request->verify_csrf) {
        return $csrf;
    }
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
    if (my $csrf = $request->verify_csrf) {
        return $csrf;
    }
    my ($reauth, $database) = _init_db($request);
    return $reauth if $reauth;

    my $hdr = $request->{_req}->header( 'Accept-Language' );
    my $lang = $request->{_wire}->get( 'default_locale' )->from_header( $hdr );
    my $upgrade = LedgerSMB::Database::Upgrade->new(
        database => $database,
        type => '.../...',
        language => $lang
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

    # The order is important here:
    #  New modules should be able to depend on the latest changes
    #  e.g. table definitions, etc.

    $request->{resubmit_action} //= $entrypoint;
    my $HTML = html_formatter_context {
        return ! $database->apply_changes( checks => 1,
                                           run_id => $request->{run_id} );
    } $request;

    return [ HTTP_OK,
             [ 'Content-Type' => 'text/html; charset=UTF-8' ],
             [ map { encode_utf8($_) } @$HTML ]
        ]
        if $HTML;

    $database->upgrade_modules('LOADORDER', $LedgerSMB::VERSION)
        or die 'Upgrade failed.';

    $logger->info('Completed database upgrade run ' . $database->upgrade_run_id);
    return;
}

sub rebuild_modules {
    my ($request) = @_;

    if (my $csrf = $request->verify_csrf) {
        return $csrf;
    }

    my ($reauth, $db) = _init_db($request);
    return $reauth if $reauth;

    if (my $rv = _rebuild_modules($request, 'rebuild_modules', $db)) {
        return $rv;
    }
    return _complete($request, $db);
}

=item complete

Gets the statistics info and shows the complete screen.

=cut

sub _complete {
    my ($request, $database) = @_;

    # the workflow state machine dispatches here (without database)
    if (not defined $database) {
        my ($reauth, $db) = _init_db($request);
        return $reauth if $reauth;

        $database = $db;
    }

    if ($database->upgrade_run_id) {
        $logger->debug('Collecting run information for upgrade run '
                       . $database->upgrade_run_id);
        $request->{run_id}   = $database->upgrade_run_id;
        $request->{run_info} =
            $database->list_changes( run_id => $database->upgrade_run_id );
        $logger->debug('Collected ' . scalar($request->{run_info})
                       . ' upgrade run items');
    }
    else {
        $request->{lsmb_info} = $database->stats();
    }
    my $template = $request->{_wire}->get('ui');
    return $template->render($request, 'setup/complete', $request);
}

sub complete {
    my ($request) = @_;
    if (my $csrf = $request->verify_csrf) {
        return $csrf;
    }

    return _complete($request);
};

=item system_info

Asks the various modules for system and version info, showing the result

=cut

sub system_info {
    my ($request) = @_;
    if (my $csrf = $request->verify_csrf) {
        return $csrf;
    }
    my ($reauth, $database) = _init_db($request);
    return $reauth if $reauth;

    # the intent here is to get a much more sophisticated system which
    # asks registered modules for their system and dependency info
    my $settings = $request->{_wire}->get( 'setup_settings' );
    my $auth_db = ($settings and $settings->{auth_db}) // 'postgres';
    my $info = {
        db     => $database->get_info($auth_db)->{system_info},
        system => LedgerSMB::system_info()->{system},
        environment => \%ENV,
        modules => \%INC,
    };
    $request->{info} = $info;
    return $request->{_wire}->get('ui')
        ->render($request, 'setup/system_info', $request);
}

=item db_patches_log

Lists all database schema patches that have been applied.

=cut

sub db_patches_log {
    my ($request) = @_;
    if (my $csrf = $request->verify_csrf) {
        return $csrf;
    }

    my ($reauth, $db) = _init_db($request);
    return $reauth if $reauth;

    $logger->debug('Collecting run information for all db patches');
    $request->{run_info} = $db->list_changes;
    $logger->debug('Collected ' . scalar($request->{run_info})
                   . ' upgrade run items');

    my $template = $request->{_wire}->get('ui');
    return $template->render($request, 'setup/db-patches-log', $request);
};


=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011-2024 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
