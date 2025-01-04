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

use v5.36;
use warnings;
use experimental 'try';

package LedgerSMB::old_code;

use CGI::Parse::PSGI qw(parse_cgi_output);
use IO::File;
use LedgerSMB::Form;
use Log::Any;
use POSIX 'SEEK_SET';
use Symbol;

use parent qw(Exporter);
our @EXPORT_OK = qw(dispatch);

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
    binmode $stdout, ':utf8';
    if (my $cpid = fork()) {
        waitpid $cpid, 0;
        seek($stdout, 0, SEEK_SET)
            or croak("Can't seek stdout handle: $!");

        return parse_cgi_output($stdout);
    }
    else {
        # Do not close the database handle at the end:
        #   the caller process may still need it.
        $form_args->{dbh}->{InactiveDestroy} = 1
            if $form_args->{dbh};

        # make 100% sure any "die"-s don't bubble up higher than this point in
        # the stack: we're a fork()ed process and should under no circumstance
        # end up acting like another worker. When we are done, we need to
        # exit() below.
        try {
            local *STDOUT = $stdout;
            my $script_module = $script;
            $script_module =~ s/\.pl//;
            $lsmb_legacy::form = Form->new();
            $lsmb_legacy::form->{$_} = $form_args->{$_} for (keys %$form_args);
            $lsmb_legacy::form->{script} = $script;
            $lsmb_legacy::logger = Log::Any->get_logger(category => "lsmb.$script_module.$lsmb_legacy::form->{__action}");
            %lsmb_legacy::myconfig = %$user;
            $lsmb_legacy::form->{_locale} =
                $lsmb_legacy::locale =
                LedgerSMB::Locale->get_handle( $user->{language} );

            # This is a forked process, but we're using the parent's
            # database handle. Don't destroy the database handle when
            # this forked process exits, so the parent can continue using it.
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
                &{*{$ref}}($lsmb_legacy::form, $lsmb_legacy::locale);
            }
            $form_args->{dbh}->commit if $form_args->{dbh};
        }
        catch ($e) {
            $form_args->{dbh}->rollback if $form_args->{dbh};
            warn "Error dispatching call to old code: $_\n";
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
