=head1 NAME

LedgerSMB::Report::File - File role for querying files for a report

=head1 SYNPOSIS

  use Moose;
  with 'LedgerSMB::Report::File';

=cut

package LedgerSMB::Report::File;
use Moose::Role;
use LedgerSMB::File;
with 'LedgerSMB::I18N';

=head1 DESCRIPTION

This role adds a consistent handling of file query inputs.  The basic criteria
are lazy and can be set by functions overridden by the reporting class or
provided in the constructor.

=head1 PROPERTIES ADDED

=head2 ref_key

Builder is _set_ref_key

=cut

has ref_key => (is => 'ro', lazy => '1', builder => '_set_ref_key',
               isa => 'Int');

sub _set_ref_key {
    die text('No ref key set and no override provided');
}

=head2 file_class

builder is _set_file_class

=cut

has file_class => (is => 'ro', lazy => '1', builder => '_set_file_class',
                   isa => 'Int');

sub _set_file_class {
    die text('No File Class Specified');
}

sub _set_lazy {
    my ($self) = @_;
    $self->file_class;
    $self->ref_key;
}

=head1 METHODS ADDED

=head2 list_files

Returns a list of file entries for the report

=cut

sub list_files {
    my ($self) = @_;
    $self->_set_lazy;
    my $fh = LedgerSMB::File->new(%$self);
    return $fh->list($self);
}

=head2 list_links

Returns a list of link entries for the report

=cut

sub list_links {
    my ($self) = @_;
    $self->_set_lazy;
    my $fh = LedgerSMB::File->new(%$self);
    return $fh->list_links($self);
}

=head1 COPYRIGHT

Copyright (C) 2014 The LedgerSMB Core Team.

This file may be reused under the terms of the GNU General Public License
version 2, or at your option, any later version.  Please see the included
LICENSE.txt for details.

=cut

1;
