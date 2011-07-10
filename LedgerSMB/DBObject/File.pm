=pod

=head1 NAME

LedgerSMB::DBOBject::File

=head1 SYNPSIS

This provides routines for managing file attachments.  Subclasses may be used
to provide functionality for specific types of file attachments.

=head1 PROPERTIES/ACCESSORS

=over

=cut


package LedgerSMB::DBOBject::File;
use base qw(LedgerSMB::DBObject);
use Class::Struct;

=item  attached_by_id

Entity id of the individual who attached the file.

=item attached_by

Entity name of individual who attached file

=item attached_at 

Timestamp of attachment point.

=item content

This stores the binary content of the file.

=item mime_type_id

ID of the MIME type.  Undef if unknown.

=item mime_type_text

Standard text code of the MIME type

=item file_name

File name, user specified

=item description

Description, user specified

=item id

ID of file.  undef if unknown

=item ref_key

Referential key for the file to attach to.

=item file_class

ID of the file class.

=item src_class

ID of class of the original attachment point (for a link)

=item x-info

A hash for extended information 

=back

=cut

struct LedgerSMB::DBObject::File => {
   attached_by_id =>  '$',
   attached_by    =>  '$',
   attached_at    =>  '$',
   reference      =>  '$',
   content        =>  '$',
   mime_type_id   =>  '$',
   mime_type_text =>  '$',
   file_name      =>  '$',
   description    =>  '$',
   id             =>  '$',
   ref_key        =>  '$',
   file_class     =>  '$',
   src_class      =>  '$',
   x_info         =>  '%'
};

=head1 METHODS

=over

=item get

Retrives a file.  ID and file_class properties must be set.

=cut

sub get{
    my ($self) = @_;
    my ($ref) = $self->exec_method({funcname => 'file__get'});
    $self->merge($ref);
}

=item list({ref_key => int, file_class => int})

Lists files directly attached to the object.

=cut

sub list{
    my ($self, $args) = @_;
    my @results = $self->exec_method(
                 {funcname => 'file__list', 
                      args => [$args->{ref_key}, $args->{file_class}]
                 }
     );
    return @results;
}

=item list_links({ref_key => int, file_class => int})

Lists the links directly attached to the object.

=back

=cut

sub list_links{
    my ($self, $args) = @_;
    my @results = $self->exec_method(
                 {funcname => 'file__list_links', 
                      args => [$args->{ref_key}, $args->{file_class}]
                 }
     );
    return @results;
}


=head1 COPYRIGHT

Copyright (C) 2011 The LedgerSMB Core Team

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
