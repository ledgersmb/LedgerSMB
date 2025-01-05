
package LedgerSMB::Legacy_Util;

=head1 NAME

LedgerSMB::Legacy_Util - LedgerSMB Utility functions

=head1 DESCRIPTION

Functions for rendering templates and delivering the result via the
specified output method.

=cut

use strict;
use warnings;

use Log::Any;



=head1 FUNCTIONS

=head2 render_psgi($psgi_response)

Renders a PSGI response from a C<LedgerSMB::Template::UI> as a CGI
response as required by legacy code.

=cut

sub render_psgi {
    my ($form, $psgi) = @_;

    binmode STDOUT, ':bytes';

    if (not $form->{header}) {
        print "Status: 200 OK\n";
        print "Content-Type: text/html; charset=UTF-8\n\n";
        $form->{header} = 1;
    }
    print join('', @{$psgi->[2]});
}

=head2 output_template($template, $form, %args)

supported keys in C<%args>:

=over

=item method

Determines where to send the output. Allowed values:

print|screen|<printer name>

=item printmode + OUT

=item filename

=back

=cut

my $logger = Log::Any->get_logger(category => 'LedgerSMB::Template');
our $csettings;

sub output_template {
    my $template = shift;
    my $form = shift;
    my %args = @_;

    for ( keys %args ) { $template->{output_options}->{$_} = $args{$_}; };

    my $method = $args{method} // '';

    if (defined $args{OUT} and $args{printmode} eq '>'){ # To file
        open my $fh, '>', $args{OUT}
           or die "Can't write to file $args{OUT}";
        binmode $fh, ':raw';
        print $fh $template->{output}
           or die "Can't write to file $args{OUT}";
        close $fh
            or warn "Can't close handle of $args{OUT}";
    } elsif ('print' eq lc $method) {
        _output_template_lpr($form->{_wire}, $template);
    } elsif (lc $method eq 'screen') {
        _output_template_http($template);
    } elsif (defined $method and $method ne '' ) {
        _output_template_lpr($form->{_wire}, $template);
    } else {
        _output_template_http($template, $form, %args);
    }
    return;
}



sub _output_template_http {
    my ($self, $form) = @_;
    my $data = $self->{output};
    my $cache = 1; # default

    $logger->trace('Entering _http_output()');
    # the sub below is a performance optimization: we don't want to
    # concatenate the keys for every request when not logging.
    $logger->trace(sub {
        return 'output_options keys: ' . join '|', keys %{$self->{output_options}};
    });
    if ($form->{dbh}){
        # we have a db connection, so are logged in.
        # Let's see about caching.
        $cache = 0 if $form->get_setting('disable_back');
    }

    my $disposition = '';
    my $name = $self->{output_options}{filename};
    if ($name) {
        $name =~ s#^.*/##;
        $disposition .= qq|\nContent-Disposition: attachment; filename="$name"|;
        $logger->debug("Adding disposition header: $disposition");
    }
    if (!$ENV{LSMB_NOHEAD}){
        if (!$cache){
            print "Cache-Control: no-store, no-cache, must-revalidate\n"
                . "Cache-Control: post-check=0, pre-check=0, false\n"
                . "Pragma: no-cache\n"
                or die 'Cannot print to STDOUT';
        }
        if ($self->{mimetype} =~ /^text/) {
            print "Content-Type: $self->{mimetype}; charset=utf-8$disposition\n\n"
                or die 'Cannot print to STDOUT';
        } else {
            print "Content-Type: $self->{mimetype}$disposition\n\n"
                or die 'Cannot print to STDOUT';
        }
    }
    binmode STDOUT, $self->{binmode};
    print $data or die 'Cannot print to STDOUT';
    # change global resource back asap
    binmode STDOUT, 'encoding(:UTF-8)';
    $logger->trace('end print to STDOUT');
    return;
}

sub _output_template_lpr {
    my ($wire, $template) = @_;
    my $args = $template->{output_options};
    if ($template->{format_plugin}->format ne 'PDF'
        and $template->{format_plugin}->format ne 'PS') {
        die 'Invalid Format';
    }
    my $lpr = $wire->get( 'printers' )->get( $args->{method} );

    open my $pipe, '|-', $lpr
        or die "Failed to open lpr pipe $lpr : $!";

   print $pipe $template->{output}
        or die "Cannot print to $lpr";

    close $pipe or die "Cannot close pipe to $lpr";
    return;
}

=head1 COPYRIGHT

Copyright (C) 2017-2018 The LedgerSMB Core Team

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut


1;
