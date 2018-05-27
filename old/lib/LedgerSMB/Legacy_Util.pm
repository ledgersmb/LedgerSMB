
package LedgerSMB::Legacy_Util;

=head1 NAME

LedgerSMB::Legacy_Util - LedgerSMB Utility functions

=head1 DESCRIPTION

Functions for rendering templates and delivering the result via the
specified output method.

=cut

use strict;
use warnings;

use LedgerSMB::App_State;
use LedgerSMB::Mailer;
use LedgerSMB::Setting;
use LedgerSMB::Sysconfig;

use Log::Log4perl;



=head1 FUNCTIONS

=head2 render_template($template, $variables, [$method])

=over

=item template

A LedgerSMB::Template object.

=item variables

A hashref of variables which is passed to the template.

=item method (optional)

Determines where to send the output. Allowed values:

email|print|screen|<printer name>

=back

=cut

sub render_template {
    my $self = shift;
    my $vars = shift;
    my $method = shift;

    my $post = $self->_render($vars);

    output_template($self, (method => $method));
}


=head2 output_template($template, %args)

supported keys in C<%args>:

=over

=item method

Determines where to send the output. Allowed values:

email|print|screen|<printer name>

=item printmode + OUT

=item filename

=back

=cut

my $logger = Log::Log4perl->get_logger('LedgerSMB::Template');


sub output_template {
    my $template = shift;
    my %args = @_;

    for ( keys %args ) { $template->{output_options}->{$_} = $args{$_}; };

    my $method = $args{method} // '';

    if ('email' eq lc $method) {
        _output_template_email($template);
    } elsif (defined $args{OUT} and $args{printmode} eq '>'){ # To file
        open my $fh, '>', $args{OUT}
           or die "Can't write to file $args{OUT}";
        binmode $fh, ':raw';
        print $fh $template->{output}
           or die "Can't write to file $args{OUT}";
        close $fh
            or warn "Can't close handle of $args{OUT}";
    } elsif ('print' eq lc $method) {
        _output_template_lpr($template);
    } elsif (lc $method eq 'screen') {
        _output_template_http($template);
    } elsif (defined $method and $method ne '' ) {
        _output_template_lpr($template);
    } else {
        _output_template_http($template, %args);
    }
    return;
}



sub _output_template_http {
    my ($self) = @_;
    my $data = $self->{output};
    my $cache = 1; # default

    $logger->trace('Entering _http_output()');
    # the sub below is a performance optimization: we don't want to
    # concatenate the keys for every request when not logging.
    $logger->trace(sub {
        return 'output_options keys: ' . join '|', keys %{$self->{output_options}};
    });
    if ($LedgerSMB::App_State::DBH){
        # we have a db connection, so are logged in.
        # Let's see about caching.
        $cache = 0 if LedgerSMB::Setting->get('disable_back');
    }
    # clean up after getting the (last) setting
    LedgerSMB::App_State::cleanup();

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

sub _output_template_email {
    my $self = shift;
    my $args = $self->{output_options};
    my @mailmime;

    if (not $args->{attach}) {
        $args->{message} .= $self->{output};
        @mailmime = ('contenttype', $self->{mimetype});
    }

    # User default for email from
    $args->{from} ||= $self->{user}->{email};

    # Default addresses
    my $csettings = $LedgerSMB::Company_Config::settings;
    $args->{from} ||= $csettings->{default_email_from};
    $args->{to} ||= $csettings->{default_email_to};
    $args->{cc} ||= $csettings->{default_email_cc};
    $args->{bcc} ||= $csettings->{default_email_bcc};


    # Mailer stuff
    my $mail = LedgerSMB::Mailer->new(
        from => $args->{from},
        to => $args->{to},
        cc => $args->{cc},
        bcc => $args->{bcc},
        subject => $args->{subject},
        notify => $args->{notify},
        message => $args->{message},
        @mailmime,
    );
    if ($args->{attach} or $self->{mimetype} !~ m#^text/#) {
        $mail->attach(
            mimetype => $self->{mimetype},
            filename => $args->{filename},
            strip => $$,
            data => $self->{output},
        );
    }
    $mail->send;
    return;
}

sub _output_template_lpr {
    my ($self) = shift;
    my $args = $self->{output_options};
    if ($self->{format} ne 'LaTeX') {
        die 'Invalid Format';
    }
    my $lpr = $LedgerSMB::Sysconfig::printer{$args->{method}};

    open my $pipe, '|-', $lpr
        or die "Failed to open lpr pipe $lpr : $!";

   print $pipe $self->{output}
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
