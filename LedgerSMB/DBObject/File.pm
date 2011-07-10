=pod

=head1 NAME

LedgerSMB::DBOBject::File

=head1 SYNPSIS

This provides routines for managing file attachments.  Subclasses may be used
to provide functionality for specific types of file attachments.

=head1 METHODS

=open

=cut


package LedgerSMB::DBOBject::File;
use base qw(LedgerSMB::DBObject);
use Class::Struct;

struct LedgerSMB::DBObject::file_attachement => {
   content => '$',
   mime_type_id =>  '$',
   file_name   =>  '$',
   description =>  '$',
   id =>  '$',
   ref_key =>  '$',
   file_class =>  '$',
};

=back

=head1 COPYRIGHT

Copyright (C) 2011 The LedgerSMB Core Team

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
