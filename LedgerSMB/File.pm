=pod

=head1 NAME

LedgerSMB::File - Provides routines for managing file attachments.

=head1 SYNPSIS

This provides routines for managing file attachments.  Subclasses may be used
to provide functionality for specific types of file attachments.

=head1 PROPERTIES/ACCESSORS

=over

=cut


package LedgerSMB::File;
use Moose;
with 'LedgerSMB::PGObject';
use File::MimeInfo;
use Log::Log4perl;
binmode STDIN, ':bytes';

=item  attached_by_id

Entity id of the individual who attached the file.

=cut

has attached_by_id => (is => 'rw', isa => 'Maybe[Int]');

=item attached_by

Entity name of individual who attached file

=cut

has attached_by => (is => 'rw', isa => 'Maybe[Str]');

=item attached_at

Timestamp of attachment point.

=item content

This stores the binary content of the file.

=cut

has content => (is => 'rw', isa => 'Any');

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

Path, relative to $LedgerSMB::tempdir, where file data is stored (for LaTeX use
of attached images).

=cut

has file_path => (is => 'rw', isa => 'Maybe[Str]');

=item sizex

X axis dimensions, if Image::Size is installed and file is image (only on files
retrieved for invoices).

=cut

has sizex => (is => 'rw', isa => 'Maybe[Int]');

=item sizey

Y axis dimensions, if Image::Size is installed and file is image (only on files
retrieved for invoices).

=cut

has sizey => (is => 'rw', isa => 'Maybe[Int]');

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
       $self->mime_type_text(mimetype($self->file_name));
    }
    if (!($self->mime_type_id && $self->mime_type_text)){
       my ($ref) = $self->call_dbmethod(funcname => 'file__get_mime_type');
       $self->mime_type_text($ref->{mime_type});
       $self->mime_type_id($ref->{id});
    }
    return $self->mime_type_text;
}

=item set_mime_type

Sets the mipe_type_id from the mime_type_text

=cut

sub set_mime_type {
    my ($self, $mime_type) = @_;
    $self->mime_type_text($mime_type);
    my ($ref) = $self->call_procedure(funcname => 'file__mime_type_text',
         args => [undef, $self->mime_type_text]);
    $self->mime_type_id($ref->{id});

}

=item detect_type

Auto-detects the type of the file.  Not yet implemented

=cut

sub detect_type {
    my ($self) = @_;
    $logger->warn("Stub LedgerSMB::File::detect_type\n");
};

=item get

Retrives a file.  ID and file_class properties must be set.

=cut

sub get{
    my ($self) = @_;
    my ($ref) = $self->call_dbmethod(funcname => 'file__get');
    $self->merge($ref);
}

=item get_for_template({ref_key => int, file_class => int})

Returns file data for invoices for embedded images, except that content is set
to a directive relative to tempdir where these files are stored.

=cut

sub get_for_template{
    my ($self, $args) = @_;
    warn 'entering get_for_template';

    my @results = $self->call_procedure(
                 funcname => 'file__get_for_template',
                      args => [$args->{ref_key}, $args->{file_class}]
     );
    if ( -d $LedgerSMB::Sysconfig::tempdir . '/' . $$){
        die 'directory exists';
    }
    mkdir $LedgerSMB::Sysconfig::tempdir . '/' . $$;
    $self->file_path($LedgerSMB::Sysconfig::tempdir . '/' . $$);

    for my $result (@results) {
        $result->{file_name} =~ s/\_//g;
        open FILE, '>', $self->file_path . "/$result->{file_name}";
        binmode FILE, ':bytes';
        print FILE $result->{content};
        close FILE;
        { #pre-5.14 compatibility block
            local ($@); # pre-5.14, do not die() in this block
            eval { # Block used so that Image::Size is optional
                require Image::Size;
                my ($x, $y);
                ($x, $y) = imgsize(\{$result->{content}});
                $result->{sizex} = $x;
                $result->{sizey} = $y;
            };
        }
        if ($result->{file_class} == 3){
           $result->{ref_key} = $result->{file_name};
           $result->{ref_key} =~ s/-.*//;
        } else {
           $result->{ref_key} = $args->{ref_key};
        }
    }
    return @results;
}

=item DEMOLISH

This is called by Moose on destruction of the object.  We just clean up any
files we have left around.

=cut

sub DEMOLISH {
   my ($self) = @_;
   return unless $self->{file_path}; # nothing to do
   opendir(TMP, $self->{file_path}) || return 1;
   for my $file (readdir(TMP)){
       unlink $self->{file_path} . '/' . $file;
   }
   closedir (TMP);
   rmdir $self->{file_path};
}

=item list({ref_key => int, file_class => int})

Lists files directly attached to the object.

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

=head1 COPYRIGHT

Copyright (C) 2011 The LedgerSMB Core Team

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

__PACKAGE__->meta->make_immutable;

1;
