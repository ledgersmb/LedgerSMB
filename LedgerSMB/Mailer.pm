=head1 NAME

LedgerSMB::Mailer   Mail output for LedgerSMB

=head1 SYNOPSIS

=head1 COPYRIGHT

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
 #	 Web: http://www.sql-ledger.org
 #
 #  Contributors:
 #
 # Original Author and copyright holder:
 # Dieter Simader dsmimader@sql-ledger.com
 #====================================================================

=head1 METHODS

=cut

package LedgerSMB::Mailer;

use warnings;
use strict;
use Carp;

use Encode;
use MIME::Lite;
use LedgerSMB::Sysconfig;

our $VERSION = '0.13';

=head2 LedgerSMB::Mailer->new([%args])

Create a new Mailer object.  If any arguments are passed in, a message
that uses them will be automatically prepared.

=cut

sub new {
	my $type = shift;
	my $self = {};
	bless $self, $type;

	$self->prepare_message(@_) if @_;

	$self;
}

=head2 $mail->prepare_message

=cut

sub prepare_message {
	my $self = shift;
	my %args = @_;

	# Populate message fields
	for my $key (keys %args) {
		$self->{$key} = $args{$key};
	}

	my $domain = $self->{from};
	$domain =~ s/(.*?\@|>)//g;
	my $boundary = time;
	$boundary = "LSMB-$boundary";
	my $msg_id = "$boundary\@$domain";

	$self->{contenttype} = "text/plain" unless $self->{contenttype};

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
		'Message-ID' => $msg_id,
	);
	$self->{_message}->attr( 'Content-Type' => $self->{contenttype} );
	$self->{_message}->attr( 'Content-Type.charset' => 'UTF-8' ) if
		$self->{contenttype} =~ m#^text/#;
	# Annoy people with read receipt requests
	$self->{_message}->add( 'Disposition-Notification-To' => $self->{from} )
	  if $self->{notify};
	$self->{_message}->binmode(':utf8');
}

=head2 $mail->attach

=cut

sub attach {
	my $self = shift;
	my %args = @_;

	carp "Message not prepared" unless ref $self->{_message};

	# strip path from output name
	my $file;
	if ($args{filename}) {
		my $strip = quotemeta $args{strip};
		$file = $args{filename};
		$file =~ s/(.*\/|$strip)//g;
        }

	# handle both string and file types of input
	my @data;
	if ($args{data}) {
		@data = ('Data', $args{data});
	} else {
		@data = ('Path', $args{filename});
	}

	$self->{_message}->attach(
		'Type' => $args{mimetype},
		'Filename' => $file,
		'Disposition' => 'attachment',
		@data,
		);
}

=head2 $mail->send

Sends a prepared message using the method configured in ledgersmb.conf.

=cut

sub send {
	my $self = shift;
	carp "Message not prepared" unless ref $self->{_message};

	$self->{_message}->replace( 'X-Mailer' => "LedgerSMB::Mailer $VERSION" );
	if ( ${LedgerSMB::Sysconfig::smtphost} ) {
		$self->{_message}->send(
			'smtp',
			${LedgerSMB::Sysconfig::smtphost},
			Timeout => ${LedgerSMB::Sysconfig::smtptimeout}
			) || return $!;
	} else {
		$self->{_message}->send(
			'sendmail',
			${LedgerSMB::Sysconfig::sendmail}
			) || return $!;
	}
}

1;

