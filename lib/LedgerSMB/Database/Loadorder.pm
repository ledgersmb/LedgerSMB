
package LedgerSMB::Database::Loadorder;

=head1 NAME

LedgerSMB::Database::Loadorder - LOADORDER parsing

=head1 DESCRIPTION

Implements processing of LOADORDER files as used by the schema
change management infrastructure in C<sql/change/>.

The LOADORDER file contains

=over

=item comments

Lines with a hash (#) as the first non-space character are taken
to be comments.

=item tag-lines

Tag lines are comment lines with a special format:

  #tag: <tag>

Multiple tags may be specified as a comma-separated list.

=item script paths

Script paths are relative to the directory the LOADORDER file is in.
Each path may be prefixed by an exclamation mark (!) to signal that
the referenced script should always be considered succesfully processed,
even if the script processes with errors.

=back

=cut

use strict;
use warnings;

use Cwd;
use List::Util qw| any |;

use LedgerSMB::Database::Change;
use LedgerSMB::Database::ChangeChecks qw/load_checks run_checks/;

=head1 SYNOPSIS

my $loadorder = LedgerSMB::Database::Loadorder->new('path/to/loadorder');
my @scripts = $loadorder->scripts;

# to make an index of scripts and their sha hashes for db revision checking:

$loadorder->makeindex()

But see the notes about locking below

=head1 METHODS

=head2 new

Constructor. LedgerSMB::Database::Loadorder->new($path [, upto_tag => $tag]);

When a tag is specified, processing the LOADORDER file stops when a line
with that tag is encountered, e.g. specifying a tag 'the-tag' stops
processing the following at line 2.

   some/path/to/a/change1.sql
   #tags: the-tag, the-second-tag
   some/path/to/a/change2.sql
   #tag: b-tag
   some/path/to/a/change3.sql

specifying a tag 'the-second-tag' stops processing at line 2 as well, while
specifying a tag 'b-tag' stops processing at line 4. Not specifying a tag
processes all 5 lines

=cut

sub new {
    my ($package, $path, %options) = @_;
    return bless { _path => $path,
                   tag => $options{upto_tag} }, $package;
}

=head2 scripts

Returns a list of LedgerSMB::Database::Change objects

=cut

sub scripts {
    my ($self) = @_;
    return @{$self->{_scripts}} if $self->{_scripts};
    local $! = undef;
    local $@ = undef;
    open my $fh, '<', $self->{_path} or
        die 'FileError on ' . Cwd::abs_path($self->{_path}) . ": $!";
    my @scripts =
        map { $self->_process_script($_)}
        grep { $_ =~ /\S/ }
        map { my $string = $_; $string =~ s/#.*$//; $string }
        map { $self->_limit_by_tag($_) }
        <$fh>;
    close $fh or die "Cannot open file $self->{_path}";
    $self->{_scripts} = \@scripts;
    return @scripts;
}

sub _process_script {
    my ($self, $line) = @_;
    chomp($line);
    my $sigil = '';
    if ($line =~ /^(!+)/){
        $sigil = $1 if $1;
        $line =~ s/^\Q$sigil\E//;
    }
    my $no_transactions = ( $sigil =~ /\Q!\E/ );
    return LedgerSMB::Database::Change->new(
        $self->path($line),
        {
            no_transactions => $no_transactions
        },
    );
}

sub _limit_by_tag {
    my ($self, $line) = @_;

    return $line if !$self->{tag};
    return '' if $self->{tagged};

    my $tags = $line;
    return $line unless $tags =~ s/^#tags?://i;

    chomp $tags;
    $self->{tagged} =
        any { $_ eq $self->{tag} }
        map { my $s = $_; $s =~ s/\s//g; $s; }
        split /,/, $tags;
    return ($self->{tagged} ? $line : '');
}

=head2 init_if_needed($dbh)

Initializes the change tracking system if not doe so already.

Initially we only install the schema.  In future versions we may have our own
changesets to apply.

Returns 1 if applied.  Returns 0 if not.

=cut

sub init_if_needed {
    my ($self, $dbh) = @_;
    return 0 unless _needs_init($dbh);
    return LedgerSMB::Database::Change::init($dbh);
}

=head2 path

Gives a full path relative to the loadorder

=cut

sub path {
    my ($self, $furtherpart) = @_;
    my $path = $self->{_path};
    $path =~ s/LOADORDER$/$furtherpart/;
    return $path;
}

=head2 run_all($dbh)

Runs all files in the loadorder without applying tracking info.

=cut

sub run_all {
    my ($self, $dbh) = @_;
    $_->run($dbh) for $self->scripts;
    return;
}

=head2 apply_all($dbh, checks => $boolean)

Applies all files in the loadorder, with tracking info, locking until it
completes. Runs change precondition checks available, when C<checks> is true.

Returns true when successfully completed.

Returns false when change precondition checks fail.

Throws an exception upon error.

=cut

sub apply_all {
    my ($self, $dbh, %args) = @_;
    _lock($dbh);
    for ($self->scripts){
        if (! $_->is_applied($dbh)) {
            my $checks_file = $_->path . '.checks.pl';
            if ($args{checks} and -e $checks_file) {
                my @checks = load_checks($checks_file);

                if (not run_checks($dbh, checks => \@checks)) {
                    return 0;
                }
            }
            $_->apply($dbh);
        }
    }
    _unlock($dbh);

    return 1;
}

sub _lock {
    my ($dbh) = @_;
    # pg_advisory_lock() returns void; nothing to return here
    $dbh->do(
        q{ select pg_advisory_lock(
              'db_patches'::regclass::oid::int, 1) });
    return;
}

sub _unlock {
    my ($dbh) = @_;
    # pg_advisory_unlock() returns false when no lock was held,
    # however, pg_advisory_lock() blocks until there's one available...
    #  (so we're guaranteed to *have* a lock...)
    $dbh->do(
        q{ select pg_advisory_unlock(
               'db_patches'::regclass::oid::int, 1) });
    return;
}

sub _needs_init {
    my $dbh = pop @_;
    my $count = $dbh->prepare(q{
        select relname from pg_class
         where relname = 'db_patches'
               and pg_table_is_visible(oid)
    })->execute();
    return !int($count);
}


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2016-2018 The LedgerSMB Core Team

This file may be used under the terms of the GNU General Public License,
version 2 or at your option any later version.  This file may be moved to the
PGObject framework and licensed under the 2-clause BSD license if found to be
generally useful.

=cut

1;
