=head1 NAME

LedgerSMB::Database::Change - Database change scripts for LedgerSMB

=cut

package LedgerSMB::Database::Change;

use strict;
use warnings;
use Digest::SHA;
use Cwd;

our $reloading = 0;

=head1 SYNOPSIS

my $dbchange = LedgerSMB::Database::Change->new(path => $path,
                                      properties => $properties);

my $content = $dbchange->content()
my $sha = $dbchange->sha();
my $content_wrapped = $dbchange->content_wrap($before, $after);

=head1 METHODS

=head2 new

Constructor. LedgerSMB::Database::Change->new($path, $properties);

$properties is optional and a hashref with any of the following keys set:

=over

=item no_transactions

Do not wrap this in a transaction

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

SQL content, wrapped in a transaction (unless no_transactions was set)

If $raw is set to a true value, we do not wrap in a transaction.

=cut

sub content {
    my ($self, $raw) = @_;
    unless ($self->{_content}) {
        local $!;
        open my $fh, '<', $self->path or
            die 'FileError: ' . Cwd::abs_path($self->path) . ": $!";
        binmode $fh, ':utf8';
        $self->{_content} = join '', <$fh>;
        close $fh or die "Cannot close file " .  $self->path();
    }
    my $content = $self->{_content};
    return $self->_wrap_transaction($content, $raw);
}

sub _wrap_transaction {
    my ($self, $content, $raw) = @_;
    $content = _wrap($content, 'BEGIN;', 'COMMIT;')
       unless $self->{properties}->{no_transactions} or $raw;
    return $content;
}

sub _wrap {
    my ($content, $before, $after) = @_;
    return "$before\n$content\n$after";
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

=head2 content_wrapped($before, $after)

Wrap a file with more statements in the same transaction.

So you get something like:

BEGIN;
$before
$self->content
$after
COMMIT;

Useful for db updates so you can update version numbers or the like.

=cut

sub content_wrapped {
    my ($self, $before, $after) = @_;
    $before //= "";
    $after //= "";
    return $self->_wrap_transaction(
        _wrap($self->content(1), $before, $after)
    );
}

=head2 is_applied($dbh)

Returns true if the current sha matches one that has been applied.

=cut

sub is_applied {
    my ($self, $dbh) = @_;
    my $sha = $self->sha;
    my $sth = $dbh->prepare(
        "SELECT * FROM db_patches WHERE sha = ?"
    );
    $sth->execute($sha);
    my $retval = int $sth->rows;
    $sth->finish;
    return $retval;
}

=head2 run($dbh)

Runs against the current dbh without tracking.

=cut

sub run {
    my ($self, $dbh) = @_;
    return $dbh->do($self->content); # not raw
}

=head2 apply($dbh)

Applies the current file to the db in the current dbh.

=cut

sub apply {
    my ($self, $dbh) = @_;
    my $need_commit = _need_commit($dbh);
    my $before = "";
    my $after;
    my $sha = $dbh->quote($self->sha);
    my $path = $dbh->quote($self->path);
    my $no_transactions = $self->{properties}->{no_transactions};
    if ($self->is_applied($dbh)){
        $after = "
              UPDATE db_patches
                     SET last_updated = now()
               WHERE sha = $sha;
        ";
    } else {
        $after = "
           INSERT INTO db_patches (sha, path, last_updated)
           VALUES ($sha, $path, now());
        ";
    }
    if ($no_transactions){
        $dbh->do($after);
        $after = "";
        $dbh->commit if $need_commit;
    }
    my $success = eval {
         $dbh->prepare($self->content_wrapped($before, $after))->execute();
    };
    die "$DBI::state: $DBI::errstr while applying $path"
        unless $success or $no_transactions;
    $dbh->commit if $need_commit;
    $dbh->prepare("
            INSERT INTO db_patch_log(when_applied, path, sha, sqlstate, error)
            VALUES(now(), $path, $sha, ?, ?)
    ")->execute($dbh->state, $dbh->errstr);
    $dbh->commit if $need_commit;
    return;
}

sub _need_commit{
    my ($dbh) = @_;
    return 1; # todo, detect existing transactions and autocommit status
}
=head1 Package Functions

=head2 init($dbh)

Initializes the tracking system

=cut

sub init {
    my ($dbh) = @_;
    return 0 unless needs_init($dbh);
    my $success = $dbh->prepare("
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
    ")->execute();
    die "$DBI::state: $DBI::errstr" unless $success;

    return 1;
}

=head2 needs_init($dbh)

Returns true if the tracking system needs to be initialized

=cut

sub needs_init {
    my ($dbh) = @_;
    local $@;
    my $rows = eval { $dbh->prepare(
       "select 1 from db_patches"
    )->execute(); };
    $dbh->rollback;
    return 0 if $rows;
    return 1;
}

=head1 TODO

Future versions will allow properties to be specified in comment headers in
the scripts themselves.  This will pose some backwards-compatibility issues and
therefore will be 2.0 material.

=head1 COPYRIGHT

Copyright (C) 2016 The LedgerSMB Core Team

This file may be used under the GNU General Public License version 2 or at your
option any later version.  As part of the database framework of LedgerSMB it
may also be moved out to the PGObject distribution on CPAN and relicensed under
the same BSD license as the rest of that framework.

=cut

1;
