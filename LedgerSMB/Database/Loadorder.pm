=head1 NAME

LedgerSMB::Database::Loadorder - LOADORDER parsing

=cut

package LedgerSMB::Database::Loadorder;
use strict;
use warnings;

use LedgerSMB::Database::Change;
use Fcntl;

=head1 SYNOPSIS

my $loadorder = LedgerSMB::Database::Loadorder->new('path/to/loadorder');
my @scripts = $loadorder->scripts;

# to make an index of scripts and their sha hashes for db revision checking:

$loadorder->makeindex()

But see the notes about locking below

=head1 METHODS

=head2 constructor

LedgerSMB::Database::Loadorder->new($path);

=cut

sub new {
    my ($package, $path) = @_;
    bless {_path => $path }, $package;
}

=head2 scripts

Returns a list of LedgerSMB::Database::Change objects

=cut

my $reload_subsequent;
sub scripts {
    my ($self) = @_;
    return @{$self->{_scripts}} if $self->{_scripts};
    my $loadorder;
    local $!;
    open LOAD, '<', $self->{_path};
    die 'FileError: ' . $! if tell(LOAD) == -1;
    $reload_subsequent = 0;
    my @scripts =
       map { $self->_process_script($_)}
       grep { $_ =~ /\S/ }
       map { my $string = $_; $string =~ s/#.*$//; $string }
       <$loadorder>;
    close LOAD;
    $self->{_scripts} = \@scripts;
    $reload_subsequent = 0;
    return @scripts;
}

sub _process_script {
    my ($self, $line) = @_;
    my $sigil = '';
    if ($line =~ /^([!^]+)/){
        $sigil = $1 if $1;
        $line =~ s/^\Q$sigil\E//;
    }
    $reload_subsequent ||= ( $sigil =~ /\Q^\E/ );
    my $no_transactions = ( $sigil =~ /\Q!\E/ );
    return LedgerSMB::Database::Change->new(
        $self->path($line),
        {
            reload_subsequent => $reload_subsequent,
            no_transactions => $no_transactions
        },
    );
}

=head2 makeindex

Creates an index of the files at $path/LOADORDER.idx and locks the file.

If the file is already locks throws an error "LockError"

The LOADORDER.idx remains empty.

=cut

sub makeindex {
    my ($self) = @_;
    die 'LockError' if -f $self->path('LOADORDER.idx');
    open TEMP, '>', $self->path('LOADORDER.idx');
    $self->{_locked} = 1;
    for my $script ($self->scripts){
        $script->load_contents;
    }
    close TEMP;
}

=head2 init_if_needed($dbh)

Initializes the change tracking system if not doe so already.

Initially we only install the schema.  In future versions we may have our own
changesets to apply.

Returns 1 if applied.  Returns 0 if not.

=cut

sub init_if_needed {
    my ($self, $dbh) = @_;
    return LedgerSMB::Database::Change::init($dbh);
}

sub DESTROY {
    my ($self) = @_;
    unlink $self->path('LOADORDER.idx') if $self->{_locked};
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
}

=head2 apply_all

Applies all files in the loadorder, with tracking info

=cut

sub apply_all {
    my ($self, $dbh) = @_;
    my $reloading = 0;
    for ($self->scripts){
        $_->apply if $reloading or not $_->is_applied;
    }
}

=head1 COPYRIGHT

Copyright (C) 2016 The LedgerSMB Core Team

This file may be used under the terms of the GNU General Public License,
version 2 or at your option any later version.  This file may be moved to the
PGObject framework and licensed under the 2-clause BSD license if found to be
generally useful.

=cut

1;
