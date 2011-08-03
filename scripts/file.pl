=pod

=head1 NAME

LedgerSMB::Scripts::file

=head1 SYNOPSIS

This supplies file retrival and attachment workflows
    
=head1 METHODS
        
=over

=item get

Retrieves a file and sends it to the web browser.

Requires that id and file_class be set.

=cut

package LedgerSMB::Scripts::file;
use LedgerSMB::File;
use LedgerSMB::File::Transaction;
use LedgerSMB::File::Order;
use strict;
use CGI::Simple;

our $fileclassmap = {
   1   => 'LedgerSMB::File::Transaction',
   2   => 'LedgerSMB::File::Order',
};

sub get {
    my ($request) = @_;
    my $file = LedgerSMB::File->new();
    $file->dbobject(LedgerSMB::DBObject->new({base => $request}));
    $file->id($request->{id});
    $file->file_class($request->{file_class});
    $file->get();

    my $cgi = CGI::Simple->new();

    print $cgi->header(
          -type       => $file->get_mime_type,
          -status     => '200',
          -charset    => 'utf-8',
          -attachment => $file->file_name,
    );
    print $file->content;
}

=item show_attachment_screen

Show the attachment or upload screen.

=cut

sub show_attachment_screen {
    my ($request) = @_;
    my $template = LedgerSMB::Template->new(
        user     => $request->{_user},
        locale   => $request->{_locale},
        path     => 'UI/file',
        template => 'attachment_screen',
        format   => 'HTML'
    );
    $template->render($request);
}

=item attach_file

Attaches a file to an object
        
=cut

sub attach_file {
    my ($request) = @_;
    my $file = $fileclassmap->{$request->{file_class}}->new();
    $file->dbobject(LedgerSMB::DBObject->new({base => $request}));
    my @fnames =  $request->{_request}->upload_info;
    $file->file_name($fnames[0]);
    $file->merge($request);
    if ($request->{url}){
	$file->mime_type_text('text/x-uri');
        $file->content($request->{url});
    } else {
        use File::MimeInfo;
        $file->file_name($fnames[0]);
        $file->get_mime_type;
        my $fh = $request->{_request}->upload('upload_data');
        my $fdata = join ("\n", <$fh>);
        $file->content($fdata);
    }
    $file->attach;
    my $cgi = CGI::Simple->new;
    print $cgi->redirect($request->{callback});
}

=back

=head1 COPYRIGHT

Copyright (C) 2011 LedgerSMB Core Team.  This file is licensed under the GNU 
General Public License version 2, or at your option any later version.  Please
see the included License.txt for details.

=cut


1;
