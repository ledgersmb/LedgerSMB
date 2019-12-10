=head1 NAME

LedgerSMB::old_code - dispatching from new code to old code

=head1 SYNPOSIS

 return LedgerSMB::old_code::dispatch('ar.pl', 'print', $request);

 return LedgerSMB::old_code::dispatch('ar.pl', 'print', { id => 1, ... });



 use LedgerSMB::old_code qw(dispatch);

 return dispatch('ar.pl', 'print', $request);


=head1 FUNCTIONS

=over

=cut

package LedgerSMB::old_code;


use strict;
use warnings;
use CGI::Parse::PSGI qw(parse_cgi_output);
use IO::File;
use LedgerSMB::Form;
use POSIX 'SEEK_SET';
use Symbol;
use Try::Tiny;

use base qw(Exporter);
our @EXPORT_OK = qw(dispatch);

use LedgerSMB::App_State;

# make sure the package exists after 'use'-ing this module:

# We're doing dodgy things in the next line,
# but we're doing so deliberately; don't fail the criticism:
# It'll go away when we eliminate old code
package lsmb_legacy {  ## no critic
    our $form;
    our $locale;
    our %myconfig;
};


=item dispatch($script, $entrypoint, $form_keys [, entrypoint args... ])

Wraps a "call" to old code, returning a PSGI triplet for the response.

=cut

sub dispatch {
    my $script = shift;
    my $entrypoint = shift;
    my $user = shift;
    my $form_args = shift;
    my @entrypoint_args = @_;

    my $stdout = IO::File->new_tmpfile;
    if (my $cpid = fork()) {
        waitpid $cpid, 0;
        seek($stdout, 0, SEEK_SET)
            or croak("Can't seek stdout handle: $!");

        return parse_cgi_output($stdout);
    }
    else {
        # make 100% sure any "die"-s don't bubble up higher than this point in
        # the stack: we're a fork()ed process and should under no circumstance
        # end up acting like another worker. When we are done, we need to
        # exit() below.
        try {
            local *STDOUT = $stdout;
            $lsmb_legacy::form = Form->new();
            $lsmb_legacy::form->{$_} = $form_args->{$_} for (keys %$form_args);
            %lsmb_legacy::myconfig = %$user;

            # This is a forked process, but we're using the parent's
            # database handle. Don't destroy the database handle when
            # this forked process exits, so the parent can continue using it.
            $LedgerSMB::App_State::DBH->{AutoInactiveDestroy} = 1;

            {
                # Note that we're only loading this code *after* the fork,
                # so, we're only ever "polluting" the namespaces of the
                # child Perl process which we'll ditch right after.
                local ($!, $@);
                my $do_ = "old/bin/$script";

                no strict;
                no warnings 'redefine';

                unless ( do $do_ ) {
                    if ($! or $@) {
                        print "Status: 500 Internal server error (old_code.pm)\n\n";
                        warn "Failed to execute $do_ ($!): $@\n";
                    }
                }
            }
            if (ref $entrypoint eq "CODE") {
                $entrypoint->(@entrypoint_args);
            }
            else {
                my $ref = qualify_to_ref $entrypoint, 'lsmb_legacy';
                &{$ref}($lsmb_legacy::form, $lsmb_legacy::locale);
            }
        };
        exit;
    }
}

=back

=head1 Copyright (C) 2016, The LedgerSMB core team.

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

1;
