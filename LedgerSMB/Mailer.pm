#=====================================================================
# LedgerSMB
# Small Medium Business Accounting software
# http://www.ledgersmb.org/
#
# Copyright (C) 2006
# This work contains copyrighted information from a number of sources all used
# with permission.
#
# This file contains source code included with or based on SQL-Ledger which
# is Copyright Dieter Simader and DWS Systems Inc. 2000-2005 and licensed
# under the GNU General Public License version 2 or, at your option, any later
# version.  For a full list including contact information of contributors,
# maintainers, and copyright holders, see the CONTRIBUTORS file.
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
#======================================================================
#
# This file has undergone whitespace cleanup.
#
#======================================================================
#
# mailer package
#
#======================================================================

package LedgerSMB::Mailer;

use MIME::Lite;
use MIME::Base64;
use LedgerSMB::Sysconfig;

sub new {
    my ($type) = @_;
    my $self = {};

    bless $self, $type;
}

sub send {
    my ($self) = @_;

    my $domain = $self->{from};
    $domain =~ s/(.*?\@|>)//g;
    my $msgid = "$boundary\@$domain";

    $self->{contenttype} = "text/plain" unless $self->{contenttype};

    my %h;
    for (qw(from to cc bcc)) {
        $self->{$_} =~ s/\&lt;/</g;
        $self->{$_} =~ s/\&gt;/>/g;
        $self->{$_} =~ s/(\/|\\|\$)//g;
        $h{$_} = $self->{$_};
    }

    $h{subject} =
      ( $self->{subject} =~ /([\x00-\x1F]|[\x7B-\xFFFF])/ )
      ? "Subject: =?$self->{charset}?B?"
      . MIME::Base64::encode( $self->{subject}, "" ) . "?="
      : "Subject: $self->{subject}";

    my $msg = MIME::Lite->new(
        'From'    => $self->{from},
        'To'      => $self->{to},
        'Cc'      => $self->{cc},
        'Bcc'     => $self->{bcc},
        'Subject' => $self->{subject},
        'Type'    => 'TEXT',
        'Data'    => $self->{message},
    );
    $msg->add( 'Disposition-Notification-To' => $self->{from} )
      if $self->{notify};
    $msg->replace( 'X-Mailer' => "LedgerSMB $self->{version}" );

    if ( @{ $self->{attachments} } ) {
        foreach my $attachment ( @{ $self->{attachments} } ) {

            my $application =
              ( $attachment =~ /(^\w+$)|\.(html|text|txt|sql)$/ )
              ? "text"
              : "application";

            my $filename = $attachment;

            # strip path
            $filename =~ s/(.*\/|$self->{fileid})//g;
            $msg->attach(
                'Type'        => "$application/$self->{format}",
                'Path'        => $attachment,
                'Filename'    => $filename,
                'Disposition' => 'attachment',
            );
        }

    }

    if ( ${LedgerSMB::Sysconfig::smtphost} ) {
        $msg->send(
            'smtp',
            ${LedgerSMB::Sysconfig::smtphost},
            Timeout => ${LedgerSMB::Sysconfig::smtptimeout}
        ) || return $!;
    }
    else {
        $msg->send( 'sendmail', ${LedgerSMB::Sysconfig::sendmail} )
          || return $!;
    }

    return "";

}

1;

