
package LedgerSMB::File;

=head1 NAME

LedgerSMB::File - Provides routines for managing file attachments.

=head1 DESCRIPTION

This provides routines for managing file attachments.  Subclasses may be used
to provide functionality for specific types of file attachments.

=head1 PROPERTIES/ACCESSORS

=over

=cut


use strict;
use warnings;

use Moose;
use namespace::autoclean;
with 'LedgerSMB::PGObject';

use File::Temp;
use Log::Log4perl;
use MIME::Types;
use PGObject::Type::ByteString;
use LedgerSMB::Magic qw( FC_PART );
use LedgerSMB::MooseTypes;


PGObject::Type::ByteString->register(registry => 'default');

=item  uploaded_by

Entity id of the individual who attached the file.

=cut

has uploaded_by => (is => 'rw', isa => 'Maybe[Int]');

=item uploaded_by_name

Entity name of individual who attached file

=cut

has uploaded_by_name => (is => 'rw', isa => 'Maybe[Str]');

=item uploaded_at

Timestamp of attachment point.

=cut

has uploaded_at => (is => 'ro', isa => 'Maybe[Str]');

=item content

This property yields a reference to the binary content of the file.
Dereferencing it will yield the underlying raw content.

When setting, either a string, or a scalar reference to a string
may be used, either of which will be coerced into a reference.

Note: Important difference with the 1.4 series is that before
  1.5.0 this attribute stored the actual content instead of a
  string reference.

=cut

has content => (is => 'rw', isa => 'LedgerSMB::Moose::FileContent',
                coerce => 1);


=item mime_type_id

ID of the MIME type.  Undef if unknown.

=cut

has mime_type_id => (is => 'rw', isa => 'Maybe[Int]');

=item mime_type_text

Standard text code of the MIME type

=cut

has mime_type_text => (is => 'rw', isa => 'Maybe[Str]');

=item file_name

File name, user specified

=cut

has file_name => (is => 'rw', isa => 'Str');

=item description

Description, user specified

=cut

has description => (is => 'rw', isa => 'Maybe[Str]');

=item id

ID of file.  undef if unknown

=cut

has id => (is => 'rw', isa => 'Maybe[Int]');

=item ref_key

Referential key for the file to attach to.

=cut

has ref_key => (is => 'rw', isa => 'Int');

=item reference

Reference control code (text string) for attached financial database object.

=cut

has reference => (is => 'rw', isa => 'Maybe[Str]');

=item file_class

ID of the file class.

=cut

has file_class => (is => 'rw', isa => 'Int');

=item src_class

ID of class of the original attachment point (for a link)

=cut

has src_class => (is => 'rw', isa => 'Maybe[Int]');

=item file_path

Path where file data is stored (for LaTeX use of attached images).

The path is a temporary path which is cleaned up as soon as this
instance goes out of scope.

=cut

has file_path => (
    is => 'ro',
    isa => 'Maybe[Str]',
    lazy => 1,
    default => sub {
        my $self = shift;
        $self->_tempdir->dirname;
    },
);

=item _tempdir

Private property holding the File::Temp::Dir object created for the
get_for_template() method.

=cut

has _tempdir => (
    is => 'ro',
    isa => 'Maybe[Object]',
    lazy => 1,
    default => sub {
        File::Temp->newdir( CLEANUP => 1 );
    },
);

=back

=cut

my $logger = Log::Log4perl->get_logger('LedgerSMB::File');

=head1 METHODS

=over

=item get_mime_type

Sends the textual representation of the MIME type.  If not set, retrieves and
sets it.

=cut

sub get_mime_type {
    my ($self) = @_;
    if (!($self->mime_type_id || $self->mime_type_text)){
       $self->mime_type_text(
            MIME::Types->new->mimeTypeOf($self->file_name)->type
       );
    }
    if (!($self->mime_type_id && $self->mime_type_text)){
       my ($ref) = $self->call_dbmethod(funcname => 'file__get_mime_type');
       $self->mime_type_text($ref->{mime_type});
       $self->mime_type_id($ref->{id});
    }
    return $self->mime_type_text;
}

=item get

Retrieves a file.  ID and file_class properties must be set.

=cut

sub get {
    my ($self) = @_;
    my ($ref) = $self->call_dbmethod(funcname => 'file__get');
    $self->{$_} = $ref->{$_} for keys %$ref;
    return;
}

=item get_for_template({ref_key => int, file_class => int})

This is a specialised query with rather opaque logic and transformations,
intended to extract a set of files for inclusion in LaTeX invoice templates.

If results are returned, a temporary directory is created by this method,
into which the returned files are written, for use by the template. The
path of this temporary directory is available as the `file_path` property.
This directory and its contents are removed when this object instance goes
out of scope.

The method returns as a list and writes to the temporary directory:

  1) All files matching the specified `file_class` and `ref_key`, having a
     `mime_type` with `invoice_include=TRUE`.

AND

  2) For every part on an invoice having `trans_id` equal to the specified
     `ref_key` argument (regardless of specified file_class), the most recent
     (by id) file associated with that part having mime_type matching
     'image*'.

If file_class is FC_PART, the returned file_name is a concatanation of
`ref_key` and `file_name` joined by '-', rather than the raw database
`file_name` field.

All file classes have underscores stripped from their `file_name` fields.
For FC_PART file classes, this happens after the concatanation of `ref_key`.

[For FC_PART file classes, as a final step before data is returned, the
`ref_key` field is replaced with part of the reconstructed `file_name`,
up to the first '-' character. As `ref_key` is an integer field, this
step appears only to restore the original `ref_key`.]

Returns an array containing a list of hashes, each comprising the
following keys:

  * id
  * uploaded_by_id    # entity_id of the user who uploaded the file
  * uploaded_by_name  # entity name of the user who uploaded the file
  * file_name         # NOT the filename from the database - see notes above
  * description
  * content           # A reference to the raw file content
  * mime_type         # The normalised mime type (e.g. 'text/plain')
  * file_class
  * ref_key
  * uploaded_at       # date/time string YYYY-MM-DD HH:MM:SS.ssssss

=cut

sub get_for_template{
    my ($self, $args) = @_;

    my @results = $self->call_procedure(
        funcname => 'file__get_for_template',
        args => [
            $args->{ref_key},
            $args->{file_class},
        ],
    );

    for my $result (@results) {
        $result->{file_name} =~ s/\_//g;
        my $full_path = $self->file_path . "/$result->{file_name}";
        open my $fh, '>', $full_path
            or die "Failed to open output file $full_path : $!";
        binmode $fh, ':bytes';
        print $fh ${$result->{content}} or die "Cannot print to file $full_path";
        close $fh or die "Cannot close file $full_path";

        if ($result->{file_class} == FC_PART){
           $result->{ref_key} = $result->{file_name};
           $result->{ref_key} =~ s/-.*//;
        }
        else {
           $result->{ref_key} = $args->{ref_key};
        }
    }
    return @results;
}

=item list({ref_key => int, file_class => int})

Returns a list of files directly attached to the object. No content is
returned, except for files with a mime type of 'text/x-uri'

Returns an array of hashrefs, each representing a file and comprising:

  * id
  * uploaded_by_id    # entity_id of the user who uploaded the file
  * uploaded_by_name  # entity name of the user who uploaded the file
  * file_name
  * description
  * content           # Reference to content, undef unless mime_type='text/x-uri'
  * mime_type         # The normalised mime type (e.g. 'text/plain')
  * file_class
  * ref_key
  * uploaded_at       # date/time string YYYY-MM-DD HH:MM:SS.ssssss

=cut

sub list{
    my ($self, $args) = @_;
    my @results = $self->call_procedure(
                 funcname => 'file__list_by',
                      args => [$args->{ref_key}, $args->{file_class}]
     );
    return @results;
}

=item list_links({ref_key => int, file_class => int})

Lists the links directly attached to the object.

=cut

sub list_links{
    my ($self, $args) = @_;
    my @results = $self->call_procedure(
                 funcname => 'file__list_links',
                      args => [$args->{ref_key}, $args->{file_class}]
     );
    return @results;
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
