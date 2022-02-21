
package LedgerSMB::Scripts::email;

=head1 NAME

LedgerSMB:Scripts::email - web entry points for sending e-mail

=head1 DESCRIPTION

This module contains the workflows for sending e-mail; in order to do
so, it triggers actions in the C<Email> workflow. It doesn't do more than
map data from the web request to the workflow, execute a workflow action
and render the resulting state.

=head1 METHODS

=cut

use strict;
use warnings;

use HTTP::Status qw(HTTP_SEE_OTHER);
use Log::Log4perl;
use Workflow::Factory qw(FACTORY);


use LedgerSMB::Template::UI;


=head2 render

This workflow entrypoint renders the e-mail in the state it is currently
in. It also renders the available actions and handles actions when one
is submitted.

This function does *not* handle download of attachments, which is dealt
with through the C<file.pm> script module.

=cut

sub render {
    my ($request) = @_;

    my $wf = FACTORY()->fetch_workflow('Email', $request->{id});

    if ($request->{wf_action}) {
        for my $field (qw( from to cc bcc subject body )) {
            if (defined $request->{$field}) {
                $wf->context->param( $field => $request->{$field} );
            }
            else {
                $wf->context->delete_param( $field );
            }
        }

        my $upload = $request->{_uploads}->{attachment_content};
        if ($upload) {
            my $att = {
                mime_type => $upload->content_type,
                file_name => $upload->basename,
            };

            {
                open my $fh, '<', $upload->path
                    or die "Error opening uploaded file: $!";
                binmode $fh;
                local $/ = undef;
                $att->{content} = <$fh>;
                close $fh
                    or warn "Error closing uploaded file: $!";
            }

            $wf->context->param( attachment => $att );
        }
        # ignore the action if it's not allowed otherwise the BACK button
        #  doesn't work on completed workflows. Instead, just re-render
        #  the current (completed) state below.
        $wf->execute_action( $request->{wf_action} )
            if grep { $_ eq $request->{wf_action} } $wf->get_current_actions;

        if ($wf->state eq 'SUCCESS'
            or $request->{wf_action} eq 'Cancel') {
            return [ HTTP_SEE_OTHER,
                     [ Location => $request->{callback} ],
                     [ '' ]];
        }
    }


    my $template = LedgerSMB::Template::UI->new_UI;
    return $template->render($request, 'email', {
        callback    => $request->{callback},
        id          => $wf->id,
        ( map { $_ => scalar $wf->context->param($_) }
          qw( from to cc bcc notify subject body sent_date
              attachments expansions ) ),
        actions     => [ map { $_->name }
                         sort { $a->{order} <=> $b->{order} }
                         map { $wf->get_action($_) } $wf->get_current_actions ]
    });
}


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2020 The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
