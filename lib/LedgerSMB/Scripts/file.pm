
package LedgerSMB::Scripts::file;

=head1 NAME

LedgerSMB::Scripts::file - web entry points for file storage and retrieval

=head1 DESCRIPTION

This supplies file retrieval and attachment workflows

=head1 METHODS

=over

=item get

Retrieves a file and sends it to the web browser.

Requires that id and file_class be set.

=cut

use strict;
use warnings;

use DBD::Pg qw(:pg_types);
use HTTP::Status qw( HTTP_OK HTTP_SEE_OTHER );

use LedgerSMB::File;
use LedgerSMB::File::Transaction;
use LedgerSMB::File::Order;
use LedgerSMB::File::Part;
use LedgerSMB::File::Entity;
use LedgerSMB::File::ECA;
use LedgerSMB::File::Internal;
use LedgerSMB::File::Incoming;
use LedgerSMB::File::Reconciliation;
use LedgerSMB::Magic qw(  FC_TRANSACTION FC_ORDER FC_PART FC_ENTITY FC_ECA
    FC_INTERNAL FC_INCOMING FC_EMAIL FC_RECONCILIATION );
use LedgerSMB::Request::Helper::ParameterMap qw( input_map spec_for_dynatable );

our $fileclassmap = {
   FC_TRANSACTION()    => 'LedgerSMB::File::Transaction',
   FC_ORDER()          => 'LedgerSMB::File::Order',
   FC_PART()           => 'LedgerSMB::File::Part',
   FC_ENTITY()         => 'LedgerSMB::File::Entity',
   FC_ECA()            => 'LedgerSMB::File::ECA',
   FC_INTERNAL()       => 'LedgerSMB::File::Internal',
   FC_INCOMING()       => 'LedgerSMB::File::Incoming',
   FC_EMAIL()          => 'LedgerSMB::File::Email',
   FC_RECONCILIATION() => 'LedgerSMB::File::Reconciliation',
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

my @internal_files_columns = (
   {col_id => 'select',
       type => 'checkbox' },

    {col_id => 'file_name',
  href_base => 'file.pl?__action=get&file_class=6&id=',
href_target => '_blank',
       type => 'href' },

    {col_id => 'description',
       type => 'text' },
    );

my $internal_files_map =
    input_map(spec_for_dynatable(
                  path => '@files',
                  attributes => {},
                  columns => \@internal_files_columns
              ));


=item delete_internal_files

=cut

sub delete_internal_files {
    my ($request) = @_;

    my $params = $internal_files_map->({ %$request });
    for my $row (grep { $_->{select} }
                 @{$params->{files} // []}) {
        my $file = LedgerSMB::File->new(
            id         => $row->{row},
            ref_key    => 0,
            file_class => FC_INTERNAL(),
            );
        $file->remove;
    }
    $request->{__action} = 'list_internal_files';
    return list_internal_files($request);
}

=item list_internal_files

=cut

sub list_internal_files {
    my ($request) = @_;
    my $file = LedgerSMB::File->new(%$request);
    my @files = $file->list(
        {
            ref_key => 0,
            file_class => FC_INTERNAL()
        });

    my $translations = {
        file_name   => $request->{_locale}->text('File name'),
        description => $request->{_locale}->text('Description'),
    };

    my $columns = [
        map { {
            name => ($translations->{$_->{col_id}} // ''),
            %$_  }  } @internal_files_columns
    ];

    for my $f (@files) {
        $f->{row_id}                = $f->{id};
        $f->{file_name_href_suffix} = $f->{id};
    }
    my $template = $request->{_wire}->get('ui');
    return $template->render($request, 'file/internal-file-list',
                             {
                                 files => \@files,
                                 columns => $columns,
                             });
}

=item show_attachment_screen

Show the attachment or upload screen.

=cut

sub show_attachment_screen {
    my ($request) = @_;
    my @flds = split/\s/, $request->{additional};
    my $template = $request->{_wire}->get('ui');
    return $template->render($request, 'file/attachment_screen', $request);
}

=item attach_file

Attaches a file to an object

=cut

sub attach_file {
    my ($request) = @_;
    my $file = $fileclassmap->{$request->{file_class}}->new(%$request);

    if ($request->{url}){
        $file->file_name($request->{url});
        $file->mime_type_text('text/x-uri');
        $file->get_mime_type;
        $file->content($request->{url});
    }
    else {
        # Expecting a file upload.
        my $upload = $request->{_uploads}->{upload_data}
            or die $request->{_locale}->text('No file uploaded');

        # Slurp uploaded file.
        # Wrapped in a block to tightly localise $/, otherwise loading of
        # the mime database within the underlying MIME::Types module fails,
        # without raising an error.
        {
            open my $fh, '<', $upload->path or die "Error opening uploaded file $!";
            binmode $fh;
            local $/ = undef;
            $file->content(<$fh>);
            $file->file_name($upload->basename);
        }

        # If provided, use the content-type submitted by the browser.
        # Otherwise the underlying file module will guess the mime type
        # according to the uploaded file extension.
        $file->mime_type_text($upload->content_type) if $upload->content_type;
        $file->get_mime_type;
    }

    $file->attach;

    return [ HTTP_SEE_OTHER,
             [ 'Location' => $request->{callback} ],
             [ ] ];
}

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011-2018 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
