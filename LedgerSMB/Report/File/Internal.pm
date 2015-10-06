=head1 NAME

LedgerSMB::Report::File::Internal - Files for LSMB processes.

=head1 SYNPOSIS

 LedgerSMB::Report::File::Internal->new(%$request)->render($request);

=cut

package LedgerSMB::Report::File::Internal;
use Moose;
extends 'LedgerSMB::Report';
with 'LedgerSMB::Report::File', 'LedgerSMB::I18N';

sub _set_file_class { return 6; }
sub _set_ref_key { return 0; }

=head1 DESCRIPTION

This report lists internal files, and provides a form to upload additional
ones.  Files must be unique by name.

=head1 CRITERIA

None

=head1 STATIC METHODS

=head2 columns

=over

=back

=cut

sub columns {
    return [
     { col_id => 'file_name',
         type => 'href',
    href_base => 'file.pl?action=get&file_class=' . _set_file_class() .
                 "&id=",
         name => text('File Name'), },
     { col_id => 'description',
         type => 'text',
         name => text('Description'), },
     { col_id => 'mime_type',
         type => 'text',
         name => text('Mime Type'), },
     { col_id => 'uploaded_at',
         type => 'text',
         name => text('Uploaded At'), },
     { col_id => 'uploaded_by_name',
         type => 'text',
         name => text('Uploaded By'), },
    ];
}

=head2 header_lines

None

=cut

sub header_lines { return []; }

=head2 name

Internal Files (localized)

=cut

sub name { return text('Internal Files'); }

=head2 set_buttons

Single button, set to add a new file.

=cut

sub set_buttons {
    return [
        { name => 'action',
         value => 'add_internal_file',
          type => 'submit',
         class => 'submit',
          text => text('Add'),
        },
    ];
}

=head1 METHODS

=head2 run_report

Sets the rows.  This is just a wrapper around LedgerSMB::Report::File->list

=cut

sub run_report {
    my ($self) = $_;
    my @rows = $self->list;
    $_->{row_id} = $_->{id} for @rows;
    $self->rows(\@rows);
}

=head1 COPYRIGHT

Copyright (C) 2014 The LedgerSMB Core Team

This file may be re-used under the terms of the GNU General Public License
version 2 or at your option any later version.  Please see the included
LICENSE.txt file for more information.

=cut

__PACKAGE__->meta->make_immutable;

1;
