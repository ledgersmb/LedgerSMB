
package LedgerSMB::File::Internal;

=head1 NAME

LedgerSMB::File::Internal - Files for Internal processing

=head1 DESCRIPTION

Implements an internal file store to be used for files not linked to
anything as attachments. I.e. company logos could be stored through
this module.

=head1 SYNOPSIS

    use LedgerSMB::File::Internal;

    my $file = LedgerSMB::File::Internal->new(
        content     => 'This is the raw file content',
        description => 'This is the file description',
        file_name   => 'my_file.txt',
    );

    # Set mime type based on file extension
    $file->get_mime_type();

    my $result = $file->attach;
    print "Stored new file with id $result->{id}\n";

=head1 INHERITS

=over

=item  LedgerSMB::File

Provides all properties and accessors.  This subclass provides additional
methods only.

=back

=cut

use Moose;
use namespace::autoclean;
extends 'LedgerSMB::File';

=head1 METHODS

=over

=item attach

Stores the file content in the database, which is not attached or linked
to any other record. See other LedgerSMB::File::XXX modules which
allow linking files to other record types, such as contacts and transactions.

Requires content, mime_type_id, file_name properties to be set.

Optionally description may be set. Other properties are ignored.

If file_name matches an existing file, that file will be overwritten.

Returns a hashref representing the added file_internal database record
with keys:

  * id
  * uploaded_by   # entity_id of the user who uploaded the file
  * file_name
  * description
  * content       # A reference to the raw file content
  * mime_type_id  # links to the `mime_type` table
  * file_class    # Always set to 6 (FC_INTERNAL)
  * ref_key       # Always set to 0
  * uploaded_at   # date/time string YYYY-MM-DD HH:MM:SS.ssssss

=cut

sub attach {
    my ($self, $args) = @_;
    return $self->call_dbmethod(funcname => 'file__save_internal');
}

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011-2018 The LedgerSMB Core Team

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


__PACKAGE__->meta->make_immutable;


1;
