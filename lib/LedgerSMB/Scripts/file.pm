=pod

=head1 NAME

LedgerSMB::Scripts::file - web entry points for file storage and retrieval

=head1 SYNOPSIS

This supplies file retrieval and attachment workflows

=head1 METHODS

=over

=item get

Retrieves a file and sends it to the web browser.

Requires that id and file_class be set.

=cut

package LedgerSMB::Scripts::file;

use strict;
use warnings;

use LedgerSMB::File;
use LedgerSMB::File::Transaction;
use LedgerSMB::File::Order;
use LedgerSMB::File::Part;
use LedgerSMB::File::Entity;
use LedgerSMB::File::ECA;
use LedgerSMB::File::Internal;
use LedgerSMB::File::Incoming;
use DBD::Pg qw(:pg_types);
use LedgerSMB::Magic qw(  FC_TRANSACTION FC_ORDER FC_PART FC_ENTITY FC_ECA 
            FC_INTERNAL FC_INCOMING);
use HTTP::Status qw( HTTP_OK HTTP_SEE_OTHER );

our $fileclassmap = {
   FC_TRANSACTION()   => 'LedgerSMB::File::Transaction',
   FC_ORDER()         => 'LedgerSMB::File::Order',
   FC_PART()          => 'LedgerSMB::File::Part',
   FC_ENTITY()        => 'LedgerSMB::File::Entity',
   FC_ECA()           => 'LedgerSMB::File::ECA',
   FC_INTERNAL()      => 'LedgerSMB::File::Internal',
   FC_INCOMING()      => 'LedgerSMB::File::Incoming',
};

sub get {
    my ($request) = @_;
    my $file = LedgerSMB::File->new(%$request);
    $file->id($request->{id});
    $file->file_class($request->{file_class});
    $file->get();

    $file->get_mime_type;
    if ($file->mime_type_text eq 'text/x-uri'){
        return [ HTTP_SEE_OTHER,
                 [ 'Location' => $file->content ],
                 [] ];
    }

    my $mime_type = $file->get_mime_type;
    $mime_type .= '; charset=utf-8'
        if $mime_type =~ /^text\//;

    return [ HTTP_OK,
             [ 'Content-Type' => $mime_type,
               'Content-Disposition' =>
                   'attachment; filename="' . $file->file_name . '"' ],
             [ ${$file->content} ] ];
}

=item show_attachment_screen

Show the attachment or upload screen.

=cut

sub show_attachment_screen {
    my ($request) = @_;
    my @flds = split/\s/, $request->{additional};
    my $template = LedgerSMB::Template->new(
        user     => $request->{_user},
        locale   => $request->{_locale},
        path     => 'UI/file',
        template => 'attachment_screen',
        format   => 'HTML'
    );
    return $template->render_to_psgi($request);
}

=item attach_file

Attaches a file to an object

=cut

sub attach_file {
    my ($request) = @_;
    my $file = $fileclassmap->{$request->{file_class}}->new(%$request);
    my @fnames =  $request->upload;
    $file->file_name($fnames[0]) if $fnames[0];
    if ($request->{url}){
        $file->file_name($request->{url});
    $file->mime_type_text('text/x-uri');
        $file->file_name($request->{url});
        $file->get_mime_type;
        $file->content($request->{url});
    } else {
        if (!$fnames[0]){
             $request->error($request->{_locale}->text(
                  'No file uploaded'
             ));
        }
        $file->file_name($fnames[0]);
        $file->get_mime_type;
        my $fh = $request->upload('upload_data');
        binmode $fh, ':raw';
        my $fdata = join ('', <$fh>);
        $file->content($fdata);
    }
    $file->attach;

    return [ HTTP_SEE_OTHER,
             [ 'Location' => $request->{callback} ],
             [ ] ];
}

=back

=head1 COPYRIGHT

Copyright (C) 2011-2016 LedgerSMB Core Team.  This file is licensed under the GNU
General Public License version 2, or at your option any later version.  Please
see the included License.txt for details.

=cut


1;
