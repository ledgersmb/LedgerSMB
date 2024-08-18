
package LedgerSMB::Database::Change;

=head1 NAME

LedgerSMB::Database::Change - Database change scripts for LedgerSMB

=head1 SYNOPSIS

my $dbchange = LedgerSMB::Database::Change->new(path => $path,
                                      properties => $properties);

my $content = $dbchange->content()
my $sha = $dbchange->sha();
my $content_wrapped = $dbchange->content_wrap($before, $after);

=head1 DESCRIPTION

Implements infrastructure to apply "schema-deltas" (schema-changes)
exactly once. Meaning that if a change has been applied succesfully,
it won't be applied again.

Note that this functionality isn't specific to LedgerSMB and mostly
mirrors PGObject::Util::DBChange and originates from that code.

=head2 Determination of 'has been applied before'

The criterion 'has been applied before' is determined by
the SHA512 of the content of the schema change file.  This leaves no
room for fixing the content of the schema change file as changing
the content means the schema change will be applied in all upgrades,
even if the older variant was succesfully applied (because the bug
which the fixed content addresses wasn't triggered on some upgrades).

To address the immutability concern, the following extension to the
immutability has been devised.  When a schema change file must be
changed/fixed, the original must be copied to a new file with an
added suffix of an at-sign and a sequence number. Here's an example:

   sql/changes/1.4/abc.sql -copy-> sql/changes/1.4/abc.sql@1
   sql/changes/1.4/abc.sql (changed).

The new file (C<abc.sql@1>) must not be added to the change mechanism's
LOADORDER file. If another change to C<abc.sql> is required, the
following happens:

   sql/changes/1.4/abc.sql -copy-> sql/changes/1.4/abc.sql@2
   sql/changes/1.4/abc.sql (changed again).

On upgrade, this module will detect that older versions of the file
exist and have been succesfully applied.  If that's the case, the
schema change file will be considered to be applied.

=head2 Receiving values from the driver in SQL

The SQL code can query properties of the LedgerSMB execution environment
using the C< current_setting() > function insofar as they are not available
in the C< defaults > table.  Setting names are prefixed
with C< lsmb_upgrade. >.

Currently, this module doesn't export any properties of the execution
environment.

=head2 Communication from SQL to driver

The driver (this module) listens on a channel named
C<< upgrade.<current database name> >> to receive messages from
the SQL script issued using the C< NOTIFY > statement or
C< pg_notify() > function.  The notify payload is a JSON structure
defining a message.  Each message has a C< type > field; types contain
additional fields as specified below.

Please do note that notify payloads are limited to 8000 characters.

=head3 feedback

This message type allows the upgrade script to indicate feedback to
be sent to the admin running the upgrade. It supports the following
fields:

=over

=item * content (string)

Contains the text of the feedback to the user. Contents of messages
with subsequent C<seq> values, will be appended before interpreting
this field.

The resulting string consists of a header followed by two newlines
and the actual content.  Contents without a header immediately starts
with two newline characters.

The header uses the same structure as MIME. A C< Content-Type > header
may be used to indicate the formatting of the content.  When no
content type is specified, it defaults to C< text/plain >.

=item * seq (integer)

Sequence number of the feedback message, in case content is split
across multiple messages (in order to stay below the 8,000 character
payload limit).

=item * id (string)

Required field in case the C<seq> field is used to marshall a set
of message parts.  All parts share the same C<id> value, with
different values across unrelated messages.

This value may be empty if C<seq> is null.

=item * roles (string[])

The list of roles (without their company prefix, i.e. as listed in
C< sql/modules/Roles.sql >) used to determine for which users this
feedback is applicable; users being assigned at least one of the
roles will be in the list of those notified. If this field is C<null>,
the feedback will not be shown in the application, instead being
restricted to admins through C< setup.pl > and C< ledgersmb-admin >.

=back

=head3 cleanup

B<NOTE> This message type is envisioned but not implemented yet.

This message type allows the upgrade script to indicate that - once
the upgrade has been tested and approved by the admin - a cleanup
step is required.

=over

=item * script (string)

The SQL command(s) to be executed to clean up after the upgrade.

=item * feedback_id (string)

The C< id > of the feedback describing the cleanup action to the user.

=back

=cut

use strict;
use warnings;

use Cwd;
use Digest::SHA;
use File::Basename;
use File::Find;
use JSON::PP;
use Log::Any qw($log);

my $json = JSON::PP->new;

=head1 METHODS

=head2 new($path, $properties, $run_id)

Constructor.

C<$run_id> is an optional UUID and may contain an identifier for the upgrade
run this change is invoked from.

C<$properties> is optional and a hashref with any of the following keys set:

=over

=item no_transactions

Do not group statements into a single transaction.

Note: as DBI/DBD::Pg never runs statements outside of transactions;
  code running in C<no_transactions> mode will run each statement
  in its own transaction.

=item reload_subsequent

If this one has changed, then reload further modules

=back

=cut

sub new {
    my ($package, $path, $init_properties, $run_id) = @_;
    my $self = bless { _path => $path }, $package;
    my @prop_names = qw(no_transactions reload_subsequent);
    $self->{properties} = { map { $_ => $init_properties->{$_} } @prop_names };
    $self->{run_id} = $run_id;
    return $self;
}

=head2 path

Path to the module (read-only accessor)

=cut

sub path {
    my ($self) = @_;
    return $self->{_path};
}

=head2 content($raw)

SQL content read from the change file.

=cut

sub _slurp {
    my ($path) = @_;

    local $! = undef;
    open my $fh, '<', $path or
        die 'FileError: ' . Cwd::abs_path($path) . ": $!";
    binmode $fh, 'encoding(:UTF-8)';
    my $content = join '', <$fh>;
    close $fh or die 'Cannot close file ' . $path;

    return $content;
}

sub content {
    my ($self, $raw) = @_;
    unless ($self->{_content}) {
        $self->{_content} = _slurp($self->path);
    }
    return $self->{_content};
}

=head2 sha

sha of sql content, stripped of comments and lines with only whitespace
characters

=cut

sub _normalized_sha {
    my ($content) = @_;

    my $normalized =
        join "\n",
        grep { /\S/ }
        map { s/--.*//r }
        split /\n/, ($content =~ s{/\*.*?\*/}{}gsr);

    return Digest::SHA::sha512_base64($normalized);
}

sub sha {
    my ($self) = @_;

    return $self->{_sha} if $self->{_sha};

    my $content = $self->content(1); # raw
    $self->{_sha} = _normalized_sha($content);
    return $self->{_sha};
}


=head2 is_applied($dbh)

Returns true if the current sha matches one that has been applied.

=cut

sub is_applied {
    my ($self, $dbh) = @_;

    my @shas = ($self->sha);
    my $path = $self->path;
    my $want_old_scripts = sub {
        my $file = $File::Find::name;

        if ($file =~ /^\Q$path@\E/) {
            if (-f $file) {
                push @shas, _normalized_sha(_slurp($file));
            }
        }
    };
    find({ wanted => $want_old_scripts,
           follow => 0,
           no_chdir => 1 }, dirname($path));

    my $sth = $dbh->prepare(
        'SELECT * FROM db_patches WHERE sha = ?'
        );

    my $retval = 0;
    for my $sha (@shas) {
        $sth->execute($sha)
            or die $sth->errstr;
        my $rv = $sth->fetchall_arrayref
            or die $sth->errstr;
        $sth->finish
            or die $sth->errstr;

        $retval = scalar @$rv;
        last if $retval;
    }

    return $retval;
}

=head2 run($dbh)

Runs against the current dbh without tracking, in a single
transaction.

=cut

sub run {
    my ($self, $dbh) = @_;
    return $dbh->do($self->content); # not raw
}

=head2 apply($dbh)

Applies the current file to the db in the current dbh. May issue
one or more C<$dbh->commit()>s; if there's a pending transaction on
a handle, C<$dbh->clone()> can be used to create a separate copy.

Returns no value in particular.

Throws an error in case of failure.

=cut

sub _collect_script_messages {
    my ($self, $dbh) = @_;
    my @msgs;

    while (my $notification = $dbh->pg_notifies) {
        my ($chan, $pid, $payload) = @$notification;
        my $msg = $json->decode( $payload );
        push @msgs, $msg;
    }
    return undef unless (@msgs);

    my @feedback = grep { $_->{type} eq 'feedback' } @msgs;
    my @sorted = (
        (# sort is stable, so this sorts seq within id.
         sort { $a->{id} cmp $b->{id} }
         sort { $a->{seq} <=> $b->{seq} }
         grep { defined $_->{seq} } @feedback),
        );

    my @merged = grep { not defined $_->{seq} } @feedback;
    if (@sorted) {
        my $wip = pop @sorted;
        do {
            my $next = pop @sorted;
            if (not $next
                or $next->{id} ne $wip->{id}) {
                push @merged, $wip;
                $wip = $next;
            }
            elsif ($next
                   and $next->{id} eq $wip->{id}) {
                $wip->{content} .= $next->{content};
            }
        } while (@sorted);
    }
    return @merged ? \@merged : undef;
}

sub apply {
    my ($self, $dbh) = @_;
    return if $self->is_applied($dbh);

    my $channel = $dbh->quote_identifier( 'upgrade.' . $dbh->{pg_db} );
    my @after_params =  ( $self->sha );
    my $no_transactions = $self->{properties}->{no_transactions};

    my @statements = _combine_statement_blocks($self->_split_statements);
    my $last_stmt_rc;
    my ($state, $errstr);

    $dbh->do(<<~SQL);
       set client_min_messages = 'warning';
       listen $channel;
       SQL
    $dbh->commit if ! $dbh->{AutoCommit};

    # If we're in auto-commit mode, but we want 1 lengthy transaction,
    # open one.
    $dbh->begin_work if not $no_transactions and $dbh->{AutoCommit};
    for my $stmt (@statements) {
        $last_stmt_rc = $dbh->do($stmt);

        # in case the caller wanted 'transactionless' execution of the
        # statements, either commit or roll back after each statement(group)
        # **when the $dbh isn't itself already set to do so!**

        # Note that we don't need to commit in any case when the caller
        # requested with-transactions processing: all statements are
        # returned in a single block, which means 'single transaction' in
        # all modes.
        if (not $dbh->{AutoCommit} and $no_transactions) {
            if ($last_stmt_rc) {
                $dbh->commit;
            }
            else {
                $dbh->rollback;
                $last_stmt_rc = '0E0';
            }
        }
        elsif (not $no_transactions and not $last_stmt_rc) {
            $errstr = $dbh->errstr;
            $state = $dbh->state;
            last;
        }
    }

    # When there is no auto commit, simulated it by committing after each
    # query
    # When there *is* auto commit, but a single transaction was requested,
    # we called 'begin_work()' above; close that by calling 'commit()' or
    # 'rollback()' here.
    my $rolled_back;
    if (not $no_transactions) {
        if ($last_stmt_rc) { # success
            $dbh->commit;
        }
        else {
            $dbh->rollback;
            $rolled_back = 1;
        }
    }
    my $msgs = $self->_collect_script_messages($dbh);
    unless ($rolled_back) {
        $dbh->do(q{
           INSERT INTO db_patches (run_id, sha, path, last_updated, messages)
           VALUES (?, ?, ?, now(), ?);
        }, undef, $self->{run_id}, $self->sha, $self->path,
                 $msgs ? $json->encode($msgs) : undef)
            or die 'Failed to update database schema patch log: ' . $dbh->errstr;
    }

    $dbh->do(qq{
            unlisten $channel;
            INSERT INTO db_patch_log(
                run_id, when_applied, path, sha, sqlstate, error)
            VALUES(?, now(), ?, ?, ?, ?)
    }, undef, $self->{run_id}, $self->path,
             $self->sha, $state // 0, $errstr // '')
        or die 'Failed to update database schema detailed patch log: ' . $dbh->errstr;
    $dbh->commit if (! $dbh->{AutoCommit});

    if ($errstr) {
        $last_stmt_rc //= ''; # suppress interpolation warning
        die "Error ($no_transactions:$last_stmt_rc) applying upgrade script " . $self->path . ': ' . $errstr;
    }

    return;
}

# $self->_split_statements()
#
# Returns an array of strings, where each string is one (or multiple)
# statement(s) to be run in a single transaction.

sub _split_statements {
    my ($self) = @_;

    # Early escape when the caller wants all statements to run in a
    # single transaction. No need to split and regroup statements...
    # Just run the entire block.
    return ($self->content)
        if ! $self->{properties}->{no_transactions};

    my $content = $self->content;
    $content =~ s{/\*.*?\*/}{}gs;
    $content =~ s/\s*--.*//g;
    my @statements = ();

    while ($content =~ m/
((?&Statement))
(?(DEFINE)
   (?<BareIdentifier>[a-zA-Z_][a-zA-Z0-9_]*)
   (?<QuotedIdentifier>"[^\"]+")
   (?<SingularIdentifier>(?&BareIdentifier)|(?&QuotedIdentifier)|\*)
   (?<Identifier>(?&SingularIdentifier)(\.(?&SingularIdentifier))*)
   (?<QuotedString>'([^\\']|\\.)*')
   (?<DollarQString>\$(?<_dollar_block>(?&BareIdentifier)?)\$
                      [^\$]* (?: \$(?!\g{_dollar_block}\$) [^\$]*+)*
                      \$\g{_dollar_block}\$)
   (?<String> (?&QuotedString) | (?&DollarQString) )
   (?<Number>[+-]?[0-9]++(\.[0-9]*)? )
   (?<Operator> [=<>#^%?@!&~|\/*+-]+|::|:=)
   (?<Array> \[ (?&WhiteSp)
                (?: (?&ComplexTokenSequence)
                    (?&WhiteSp) )?
             \] )
   (?<WhiteSp>[\s\t\n]*)
   (?<TokenSep>,)
   (?<Token>
           (?&String)
           | (?&Identifier)
           | (?&Number)
           | (?&Operator)
           | (?&TokenSep))
   (?<TokenGroup> \(
                  (?&WhiteSp)
                  (?: (?&ComplexTokenSequence)
                      (?&WhiteSp) )?
                  \) )
   (?<ComplexToken>(?&Token)
                 | (?&TokenGroup)
                 | (?&Array))
   (?<ComplexTokenSequence>
                   (?&ComplexToken)
                   (?: (?&WhiteSp) (?&ComplexToken) )* )
   (?<Statement> (?&BareIdentifier) (?&WhiteSp)
                 (?: (?&ComplexTokenSequence) (?&WhiteSp) )? ; )
)
           /gxms) {
        push @statements, $1;
    }
    return @statements;
}


sub _combine_statement_blocks {
    my @statements = @_;

    my @blocks = ();
    my $cum_stmt = '';
    my $in_transaction = 0;
    for my $stmt (@statements) {
        if ($stmt =~ m/^\s*BEGIN\s*;\s*$/i) {
          $in_transaction = 1;
          next;
       }
        elsif ($stmt =~ m/^\s*COMMIT\s*;\s*$/i) {
          push @blocks, $cum_stmt;
          $cum_stmt = '';
          $in_transaction = 0;
          next;
       }

       if ($in_transaction) {
          $cum_stmt .= $stmt;
       }
       else {
          push @blocks, $stmt;
       }
   }
   return @blocks;
}

=head1 Package Functions

=head2 init($dbh)

Initializes the tracking system

=cut

sub init {
    my ($dbh) = @_;
    $dbh->{private_LedgerSMB} //= {};
    $log->debug('Initializing database schema patch tracking');
    return 0 if $dbh->{private_LedgerSMB}->{db_change_initialized};
    $log->debug('Proceeding to create or update the patch tracking schema');
    my $success = $dbh->prepare('
    CREATE TABLE IF NOT EXISTS db_patch_log (
       when_applied timestamp primary key,
       path text NOT NULL,
       sha text NOT NULL,
       sqlstate text not null,
       error text
    );
    CREATE TABLE IF NOT EXISTS db_patches (
       sha text primary key,
       path text not null,
       last_updated timestamp not null
    );
    ALTER TABLE db_patch_log
        add column if not exists run_id uuid;
    ALTER TABLE db_patches
        add column if not exists run_id uuid,
        add column if not exists messages jsonb;
    ')->execute();
    die "$DBI::state: $DBI::errstr" unless $success;

    $dbh->{private_LedgerSMB}->{db_change_initialized} = 1;
    return 1;
}

=head1 TODO

Future versions will allow properties to be specified in comment headers in
the scripts themselves.  This will pose some backwards-compatibility issues and
therefore will be 2.0 material.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2016-2018 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
