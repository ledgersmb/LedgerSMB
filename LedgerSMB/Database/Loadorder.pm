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
    return $self->{_scripts} if $self->{_scripts};
    open $loadorder, '<', $self->{_path};
    $reload_subsequent = 0;
    my @scripts = 
       map { $self->_process_script($_)}
       grep { $_ ~= /\S/ }
       map { $string = $_; $string =~ s/#.*$//; $string }
       <$loadorder>;
    $self->{_scripts} = \@scripts;
    $reload_subsequent = 0;
    return \@scripts;
}

sub _process_script {
    my ($self, $line) = @_;
    if ($line =~ /^([!^]+)/){
        my $sigil = $1;
        $line =~ s/^$sigil//;
    }
    $reload_subsequent ||= ( $sigil =~ /\^/ );
    my $no_transactions = ( $sigil =~ /\!/ );
    return LedgerSMB::Database::Change->new(
        properties => {
            reload_subsequent => $reload_subsequent,
            no_transactions => $no_transactons
        },
        path => $self->path($line)
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
    $path ~= s/LOADORDER$/$furtherpart/;
    return $path;
}

=head1 COPYRIGHT

Copyright (C) 2016 The LedgerSMB Core Team

This file may be used under the terms of the GNU General Public License,
version 2 or at your option any later version.  This file may be moved to the
PGObject framework and licensed under the 2-clause BSD license if found to be
generally useful.

=cut

1;
