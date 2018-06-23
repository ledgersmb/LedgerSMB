
package LedgerSMB::Database::Change;

=head1 NAME

LedgerSMB::Database::Change - Database change scripts for LedgerSMB

=head1 DESCRIPTION

Implements infrastructure to apply "schema-deltas" (schema-changes)
exactly once. Meaning that if a change has been applied succesfully,
it won't be applied again.

Note that this functionality isn't specific to LedgerSMB and mostly
mirrors PGObject::Util::DBChange and originates from that code.

=cut

use strict;
use warnings;
use Digest::SHA;
use Cwd;

=head1 SYNOPSIS

my $dbchange = LedgerSMB::Database::Change->new(path => $path,
                                      properties => $properties);

my $content = $dbchange->content()
my $sha = $dbchange->sha();
my $content_wrapped = $dbchange->content_wrap($before, $after);

=head1 METHODS

=head2 new($path, $properties)

Constructor.

$properties is optional and a hashref with any of the following keys set:

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
    my ($package, $path, $init_properties) = @_;
    my $self = bless { _path => $path }, $package;
    my @prop_names = qw(no_transactions reload_subsequent);
    $self->{properties} = { map { $_ => $init_properties->{$_} } @prop_names };
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

sub content {
    my ($self, $raw) = @_;
    unless ($self->{_content}) {
        local $! = undef;
        open my $fh, '<', $self->path or
            die 'FileError: ' . Cwd::abs_path($self->path) . ": $!";
        binmode $fh, 'encoding(:UTF-8)';
        $self->{_content} = join '', <$fh>;
        close $fh or die 'Cannot close file ' .  $self->path();
    }
    return $self->{_content};
}

=head2 sha

sha of sql content, stripped of comments and lines with only whitespace
characters

=cut

sub sha {
    my ($self) = @_;
    return $self->{_sha} if $self->{_sha};
    my $content = $self->content(1); # raw
    my $normalized = join "\n",
                     grep { /\S/ }
                     map { my $string = $_; $string =~ s/--.*//; $string }
                     split /\n/, $content;
    $self->{_sha} = Digest::SHA::sha512_base64($normalized);
    return $self->{_sha};
}


=head2 is_applied($dbh)

Returns true if the current sha matches one that has been applied.

=cut

sub is_applied {
    my ($self, $dbh) = @_;
    my $sha = $self->sha;
    my $sth = $dbh->prepare(
        'SELECT * FROM db_patches WHERE sha = ?'
    );
    $sth->execute($sha);
    my $retval = int $sth->rows;
    $sth->finish;
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

sub apply {
    my ($self, $dbh) = @_;
    return if $self->is_applied($dbh);

    my @after_params =  ( $self->sha );
    my $no_transactions = $self->{properties}->{no_transactions};

    my @statements = _combine_statement_blocks($self->_split_statements);
    my $last_stmt_rc;
    my ($state, $errstr);

    $dbh->do(q{set client_min_messages = 'warning';});
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
            if (!$last_stmt_rc) {
                $dbh->rollback;
            }
            else {
                $dbh->commit;
            }
        }
        elsif (not $no_transactions and not $last_stmt_rc) {
            $errstr = $dbh->errstr;
            $state = $dbh->state;
            last;
        }
    }

    # For transactionless processing, due to the commit and rollback
    # above, this starts in a clean transaction.
    # For with-transaction processing, this transaction runs in the
    # same transaction because above no commit was executed and higher up
    # a transaction started with 'begin_work()'

    $last_stmt_rc = $dbh->do(q{
           INSERT INTO db_patches (sha, path, last_updated)
           VALUES (?, ?, now());
        }, undef, $self->sha, $self->path);

    # When there is no auto commit, simulated it by committing after each
    # query
    # When there *is* auto commit, but a single transaction was requested,
    # we called 'begin_work()' above; close that by calling 'commit()' or
    # 'rollback()' here.
    if ((not $dbh->{AutoCommit})
        or (not $no_transactions and $dbh->{AutoCommit})) {
        if (!$last_stmt_rc) {
            $dbh->rollback;
        }
        else {
            $dbh->commit;
        }
    }

    $dbh->do(q{
            INSERT INTO db_patch_log(when_applied, path, sha, sqlstate, error)
            VALUES(now(), ?, ?, ?, ?)
    }, undef, $self->sha, $self->path, $state, $errstr);
    $dbh->commit if (! $dbh->{AutoCommit});

    if ($errstr) {
        die 'Error applying upgrade script ' . $self->path . ': ' . $errstr;
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
    $content =~ s/\s*--.*//g;
    my @statements = ();

    while ($content =~ m/
((?&Statement))
(?(DEFINE)
   (?<BareIdentifier>[a-zA-Z_][a-zA-Z0-9_]*)
   (?<QuotedIdentifier>"[^\"]+")
   (?<SingularIdentifier>(?&BareIdentifier)|(?&QuotedIdentifier))
   (?<Identifier>(?&SingularIdentifier)(\.(?&SingularIdentifier))*)
   (?<QuotedString>'[^\\']* (?: \\. [^\\']* )*')
   (?<DollarQString>\$(?<_dollar_block>(?&BareIdentifier)?)\$
                      [^\$]* (?: \$(?!\g{_dollar_block}\$) [^\$]*+)*
                      \$\g{_dollar_block}\$)
   (?<String> (?&QuotedString) | (?&DollarQString) )
   (?<Number>[+-]?[0-9]++(\.[0-9]*)? )
   (?<Operator> [=<>#^%?@!&~|*+-]+|::)
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
    return 0 unless needs_init($dbh);
    my $success = $dbh->prepare('
    CREATE TABLE db_patch_log (
       when_applied timestamp primary key,
       path text NOT NULL,
       sha text NOT NULL,
       sqlstate text not null,
       error text
    );
    CREATE TABLE db_patches (
       sha text primary key,
       path text not null,
       last_updated timestamp not null
    );
    ')->execute();
    die "$DBI::state: $DBI::errstr" unless $success;

    return 1;
}

=head2 needs_init($dbh)

Returns true if the tracking system needs to be initialized

=cut

sub needs_init {
    my ($dbh) = @_;
    local $@ = undef;
    my $rows = eval { $dbh->prepare(
       'select 1 from db_patches'
    )->execute(); };
    $dbh->rollback;
    return 0 if $rows;
    return 1;
}

=head1 TODO

Future versions will allow properties to be specified in comment headers in
the scripts themselves.  This will pose some backwards-compatibility issues and
therefore will be 2.0 material.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2016-2018 The LedgerSMB Core Team

This file may be used under the GNU General Public License version 2 or at your
option any later version.  As part of the database framework of LedgerSMB it
may also be moved out to the PGObject distribution on CPAN and relicensed under
the same BSD license as the rest of that framework.

=cut

1;
