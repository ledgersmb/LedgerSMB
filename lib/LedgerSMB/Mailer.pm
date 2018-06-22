
package LedgerSMB::Mailer;

=head1 NAME

LedgerSMB::Mailer - Mail output for LedgerSMB

=head1 DESCRIPTION

Implements mail sending functionality

=head1 LICENSE AND COPYRIGHT

 #====================================================================
 # LedgerSMB
 # Small Medium Business Accounting software
 # http://www.ledgersmb.org/
 #
 # Copyright (C) 2006
 # This work contains copyrighted information from a number of sources
 # all used with permission.
 #
 # This file contains source code included with or based on SQL-Ledger
 # which # is Copyright Dieter Simader and DWS Systems Inc. 2000-2005
 # and licensed under the GNU General Public License version 2 or, at
 # your option, any later version.  For a full list including contact
 # information of contributors, maintainers, and copyright holders,
 # see the CONTRIBUTORS file.
 #
 # Original Copyright Notice from SQL-Ledger 2.6.17 (before the fork):
 # Copyright (C) 2002
 #
 #  Author: DWS Systems Inc.
 #     Web: http://www.sql-ledger.org
 #
 #  Contributors:
 #
 # Original Author and copyright holder:
 # Dieter Simader dsmimader@sql-ledger.com
 #====================================================================

=head1 METHODS

=cut

use warnings;
use strict;
use Carp;

use Digest::MD5 qw(md5_hex);
use Encode;
use MIME::Lite;
use LedgerSMB::Sysconfig;

our $VERSION = '0.13';

=head2 LedgerSMB::Mailer->new(...)

Create a new Mailer object.  If any arguments are passed in, a message
that uses them will be automatically prepared but not sent.

=cut

sub new {
    my $type = shift;
    my $self = {};
    bless $self, $type;

    $self->prepare_message(@_) if @_;

    return $self;
}

=head2 $mail->prepare_message(to => $to, from => $from, ...)

Prepares and encodes base message for sending or adding attachments.

=head3 Arguments

=over

=item to, from, cc, bcc

Address fields for the email.

=item subject

The subject for the email.

=item message

The message body for the email.

=item contenttype

The conttent type for the body of the message, not for any attachments.

=item notify

Sets the Disposition-Notification-To header (read receipt request) for the
message.  This header will only be added if a from address is set.

=back

=cut

sub prepare_message {
    my $self = shift;
    my %args = @_;

    # Populate message fields
    for my $key (keys %args) {
        $self->{$key} = $args{$key};
    }
    die 'No email from address' unless $self->{from};

    $self->{contenttype} = 'text/plain' unless $self->{contenttype};

    for (qw(from to cc bcc subject)) {
        next unless $self->{$_};
        $self->{$_} =~ s/(\/|\\|\$)//g;
        $self->{$_} =~ s/([\n\r\f])/$1 /g;
    }

    $self->{_message} = MIME::Lite->new(
        'From' => $self->{from},
        'To' => $self->{to},
        'Cc'  => $self->{cc},
        'Bcc'  => $self->{bcc},
        'Subject' => Encode::encode('MIME-Header', $self->{subject}),
        'Type' => 'TEXT',
        'Data' => Encode::encode_utf8($self->{message}),
        'Encoding' => '8bit',
        'Message-ID' => $self->generate_message_id,
    );
    $self->{_message}->attr( 'Content-Type' => $self->{contenttype} );
    $self->{_message}->attr( 'Content-Type.charset' => 'UTF-8' ) if
        $self->{contenttype} =~ m#^text/#;
    # Annoy people with read receipt requests
    $self->{_message}->add( 'Disposition-Notification-To' => $self->{from} )
      if $self->{notify};
    return $self->{_message}->binmode(':utf8');
}

=head2 $mail->attach(data => $data, file => $file,
                     filename => $name)

Add an attachment to the prepared message.  If $data is specified, use the
value of that variable as the attachment value, otherwise attach the file
given by $file.  If both a file and data are given, the data is attached.
filename must be given and is used to name the attachment.

=cut

sub attach {
    my $self = shift;
    my %args = @_;

    carp 'Message not prepared' unless ref $self->{_message};
    if (defined $args{file}) {
        if (!$args{file}){
            carp 'Invalid filename provided';
        } elsif (not defined $args{data}
             and not (-f $args{file} and -r $args{file})){
            carp "Cannot access file: $args{file}";
        }
    } else {
        carp 'No attachement supplied' unless defined $args{data};
    }

    # handle both string and file types of input
    my @data;
    if (defined $args{data}) {
        @data = ('Data', $args{data});
    } else {
        @data = ('Path', $args{file});
    }

    return $self->{_message}->attach(
        'Type' => $args{mimetype},
        'Filename' => $args{filename},
        'Disposition' => 'attachment',
        @data,
        );
}

=head2 $mail->send

Sends a prepared message using the method configured in ledgersmb.conf.

=cut

sub send {
    my $self = shift;
    carp 'Message not prepared' unless ref $self->{_message};

    # SC: Set the X-Mailer header here so that it will be the last
    #     header set.  This ensures that MIME::Lite will not rewrite
    #     it during the preparation of the message.
    $self->{_message}->replace( 'X-Mailer' => "LedgerSMB::Mailer $VERSION" );
    local $@ = undef;
    eval {
        my @send_options;

        if (defined $LedgerSMB::Sysconfig::smtphost) {
            @send_options = (
                'smtp',
                $LedgerSMB::Sysconfig::smtphost,
                Timeout => $LedgerSMB::Sysconfig::smtptimeout,
                Port => $LedgerSMB::Sysconfig::smtpport,
            );

            if (defined $LedgerSMB::Sysconfig::smtpuser) {
                push(@send_options, AuthUser => $LedgerSMB::Sysconfig::smtpuser);
            }

            if (defined $LedgerSMB::Sysconfig::smtppass) {
                push(@send_options, AuthPass => $LedgerSMB::Sysconfig::smtppass);
            }
        } else {
            @send_options = (
                'sendmail',
                SendMail => $LedgerSMB::Sysconfig::sendmail,
                SetSender => 1
            );
        }

        $self->{_message}->send(@send_options) or return "$!";
    };
    die "Could not send email: $@.  Please check your configuration." if $@;
    return;
}


=head2 $mail->generate_message_id

Generate and return a statistically unique rfc 2393 MIME Message-ID, based
on various message fields, time, process_id and a random component.

=cut

sub generate_message_id {

    my $self = shift;
    my $domain = $self->{from};
    $domain =~ s/(.*?\@|>)//g;

    # Make sure we generate a message id which has sufficient chance
    # of being unique. Note that the purpose of MD5 here isn't to be
    # cryptographically secure; it's a hash which provides sufficient
    # distribution across the number space.
    my $msg_random = md5_hex(
        'From' => $self->{from},
        'To' => $self->{to} // '',
        'Cc' => $self->{cc} // '',
        'Bcc' => $self->{bcc} // '',
        'Subject' => $self->{subject} // '',
        # To get better distribution, also take non-message related
        # components into account: time, pid and a random number
        'Date/Time' => time,
        'Process-id' => $$,
        'Random-component' => rand(),
        );
    my $msg_id = "<LSMB-$msg_random\@$domain>";

    return $msg_id;
}

1;
