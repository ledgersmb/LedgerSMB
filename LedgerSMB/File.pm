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
use Class::Struct;
use LedgerSMB::DBObject;
use File::MimeInfo;
#use IO::Scalar;
use strict;

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

=item reference

Reference control code (text string) for attached financial database object.

=item file_class

ID of the file class.

=item src_class

ID of class of the original attachment point (for a link)

=item dbobject

Object for db interface.

=item x_info

A hash for extended information

Note additionally the $self hashref contains the basic required attributes for
DBObject, namely dbh, _roles, and _locale. 

=back

=cut

struct 'LedgerSMB::File' => {
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
   dbobject       =>  'LedgerSMB::DBObject',
   x_info         =>  '%'
};

my $logger = Log::Log4perl->get_logger('LedgerSMB::File');

=head1 METHODS

=over

=item new

Returns a blessed object

=item to_hashref

Returns a hashref of properties for the object.

=cut

sub to_hashref {
    my $self = shift @_;
    my $hashref = {    attached_by_id =>  $self->attached_by_id,
                       attached_by    =>  $self->attached_by,
                       attached_at    =>  $self->attached_at,
                       reference      =>  $self->reference,
                       content        =>  $self->content,
                       mime_type_id   =>  $self->mime_type_id,
                       mime_type_text =>  $self->mime_type_text,
                       file_name      =>  $self->file_name,
                       description    =>  $self->description,
                       id             =>  $self->id,
                       ref_key        =>  $self->ref_key,
                       file_class     =>  $self->file_class,
                       src_class      =>  $self->sec_class,
                       dbobject       =>  $self->dbobject,
                       x_info         =>  \{$self->x_info}
    };
    return $hashref;

}

=item new_dbobject

$file->new_dbobject({base => (LedgerSMB | LedgerSMB::Form), 
locale => LedgerSMB::Locale}); 

Creates a new file object.  Locale only needs to be specified when using
LedgerSMB::Form objects since these are not included.

Returns 0 on success.

Error codes on exit (OR'd):

1:  No database handle included
2:  No locale handle included
4:  Invalid base.

In most cases when working with new code it is simpler to just

$file->dbobject(LedgerSMB::DBObject->new({base => $request});

=cut

sub new_dbobject{
    use LedgerSMB;
    my ($self, $args)  = @_;
    my $dbobject;
    my $rc = 0; # Success
    $logger->debug("begin");
    $logger->trace("self=".Data::Dumper::Dumper(\$self)." args=".Data::Dumper::Dumper(\$args)." ref=".ref($args->{base}));
    if (ref $args->{base} eq 'Form'){
         #$ENV{LSMB_NOHEAD} = 1;
         use LedgerSMB::Locale;
         #HV trying to avoid msg:Issuing rollback() due to DESTROY without explicit disconnect() of DBD::Pg::db handle
         # new LedgerSMB will acquire dbh_handle.This newly created dbh_handle will be unset in merge() with dbh_handle from Form
         $logger->debug("LedgerSMB->new begin");
         my $lsmb = LedgerSMB->new($args->{base}->{dbh});
         $logger->debug("LedgerSMB->new end");
         $logger->debug("LedgerSMB->merge begin");
         $lsmb->merge($args->{base});
         $logger->debug("LedgerSMB->merge end");
         if ((ref $args->{locale}) =~ /^LedgerSMB::Locale/){
             $lsmb->{_locale} = $args->{locale};
             $dbobject = LedgerSMB::DBObject->new({base => $lsmb});
             $logger->debug("\$dbobject->{dbh}=$dbobject->{dbh}");
         } else {
             $rc | 2; # No locale
         }
    }
    elsif (LedgerSMB->isa($args->{base})){
         $dbobject = LedgerSMB::DBObject->new({base => $args->{base}});
    }
    else {
        $rc | 4; # Incorrect base type
    }
    $logger->debug("end");
    if (!$dbobject->{dbh}){
        $rc | 1; # No database handle
    }
    if ($rc){
        return $rc;  # Return error.
    } else {
        
        $self->dbobject($dbobject);
        return 0;
    }
}

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
       my ($ref) = $self->exec_method({funcname => 'file__get_mime_type'});
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
    my ($ref) = $self->exec_method({funcname => 'file__mime_type_text', 
         args => [undef, $self->mime_type_text]});
    $self->mime_type_id($ref->{id});

}

=item detect_type

Auto-detects the type of the file.  Not yet implemented

=cut

sub detect_type {
    my ($self) = @_;
    print STDERR "WARNING:  Stub LedgerSMB::File::detect_type\n";
};

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
                 {funcname => 'file__list_by', 
                      args => [$args->{ref_key}, $args->{file_class}]
                 }
     );
    return @results;
}

=item list_links({ref_key => int, file_class => int})

Lists the links directly attached to the object.

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

=item exec_method

Provides a compatible interface to LedgerSMB::DBObject::exec_method

=cut

sub exec_method{
    use DBD::Pg qw(:pg_types);
    my ($self, $args) = @_;
    if (!$args->{args}){
          $self->dbobject->{attached_by_id} = $self->attached_by_id;
          $self->dbobject->{attached_by}    = $self->attached_by;
          $self->dbobject->{attached_at}    = $self->attached_at;
          $self->dbobject->{reference}      = $self->reference;
          $self->dbobject->{content}        = {value => $self->content,
                                                type => DBD::Pg::PG_BYTEA};
          $self->dbobject->{mime_type_id}   = $self->mime_type_id;
          $self->dbobject->{mime_type_text} = $self->mime_type_text;
          $self->dbobject->{file_name}      = $self->file_name;
          $self->dbobject->{description}    = $self->description;
          $self->dbobject->{id}             = $self->id;
          $self->dbobject->{ref_key}        = $self->ref_key;
          $self->dbobject->{file_class}     = $self->file_class;
          $self->dbobject->{src_class}      = $self->src_class;
          $self->dbobject->{dbobject}       = $self->dbobject;
          $self->dbobject->{x_info}         = $self->x_info;
    }
    my @results = $self->dbobject->exec_method($args);
    return @results;
}

=item merge(hashref)

Merges in specific attributes from the ref.

=cut

sub merge {
    my ($self, $ref) = @_;
    $self->attached_by_id ($ref->{attached_by_id} || $self->attached_by_id);
    $self->attached_by    ($ref->{attached_by}    || $self->attached_by);
    $self->attached_at    ($ref->{attached_at}    || $self->attached_at);
    $self->reference      ($ref->{reference}      || $self->reference);
    $self->content        ($ref->{content}        || $self->content);
    $self->mime_type_id   ($ref->{mime_type_id}   || $self->mime_type_id);
    $self->mime_type_text ($ref->{mime_type_text} || $self->mime_type_text);
    $self->file_name      ($ref->{file_name}      || $self->file_name);
    $self->description    ($ref->{description}    || $self->description);
    $self->id             ($ref->{id}             || $self->id);
    $self->ref_key        ($ref->{ref_key}        || $self->ref_key);
    $self->file_class     ($ref->{file_class}     || $self->file_class);
    $self->src_class      ($ref->{src_class}      || $self->src_class);
    $self->dbobject       ($ref->{dbobject}       || $self->dbobject);
    $self->x_info         ($ref->{dbobject}       || $self->x_info);
}

=item commit()

Returns the value of DBI->commit

=cut

sub commit{
    my ($self) = @_;
    return $self->dbobject->{dbh}->commit;
}

=back

=head1 COPYRIGHT

Copyright (C) 2011 The LedgerSMB Core Team

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
