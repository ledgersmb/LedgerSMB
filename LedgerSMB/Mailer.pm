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

package Mailer;

sub new {
	my ($type) = @_;
	my $self = {};

	bless $self, $type;
}


sub send {
	my ($self, $out) = @_;

	my $boundary = time;
	$boundary = "LedgerSMB-$self->{version}-$boundary";
	my $domain = $self->{from};
	$domain =~ s/(.*?\@|>)//g;
	my $msgid = "$boundary\@$domain";
  
	$self->{charset} = "ISO-8859-1" unless $self->{charset};

	if ($out) {
		open(OUT, $out) or return "$out : $!";
	} else {
		open(OUT, ">-") or return "STDOUT : $!";
	}

	$self->{contenttype} = "text/plain" unless $self->{contenttype};
  
	my %h;
	for (qw(from to cc bcc)) {
		$self->{$_} =~ s/\&lt;/</g;
		$self->{$_} =~ s/\&gt;/>/g;
		$self->{$_} =~ s/(\/|\\|\$)//g;
		$h{$_} = $self->{$_};
	}
 
	$h{cc} = "Cc: $h{cc}\n" if $self->{cc};
	$h{bcc} = "Bcc: $h{bcc}\n" if $self->{bcc};
	$h{notify} = "Disposition-Notification-To: $h{from}\n" 
		if $self->{notify};
	$h{subject} = 
		($self->{subject} =~ /([\x00-\x1F]|[\x7B-\xFFFF])/) 
		? "Subject: =?$self->{charset}?B?".
			&encode_base64($self->{subject},"")."?=" 
		: "Subject: $self->{subject}";
  
	print OUT "From: $h{from}\n".
		"To: $h{to}\n".
		"$h{cc}$h{bcc}$h{subject}\n".
		"Message-ID: <$msgid>\n".
		"$h{notify}X-Mailer: LedgerSMB $self->{version}\n".
		"MIME-Version: 1.0\n\n";


	if (@{ $self->{attachments} }) {
		print OUT 
			qq|Content-Type: multipart/mixed; |.
			qq|boundary="$boundary"\n\n|;
		if ($self->{message} ne "") {
			print OUT qq|--${boundary}\n|.
				qq|Content-Type: $self->{contenttype};|.
				qq| charset="$self->{charset}"\n\n|.
				qq|$self->{message}|;
	
		}

		foreach my $attachment (@{ $self->{attachments} }) {

			my $application = 
				($attachment =~ 
					/(^\w+$)|\.(html|text|txt|sql)$/) 
				? "text" 
				: "application";
      
			unless (open IN, $attachment) {
				close(OUT);
				return "$attachment : $!";
			}
      
			my $filename = $attachment;
			# strip path
			$filename =~ s/(.*\/|$self->{fileid})//g;
      
			print OUT qq|--${boundary}\n|.
				qq|Content-Type: $application/$self->{format}; |
				. qq|name="$filename"; |.
				qq|charset="$self->{charset}"\n|.
				qq|Content-Transfer-Encoding: BASE64\n|.
				qq|Content-Disposition: attachment; |.
				qq|filename="$filename"\n\n|;

			my $msg = "";
			while (<IN>) {;
				$msg .= $_;
			}
			print OUT &encode_base64($msg);

			close(IN);
      
		}
		print OUT qq|--${boundary}--\n|;

	} else {
		print OUT qq|Content-Type: $self->{contenttype}; |.
			qq|charset="$self->{charset}"\n\n|.
			qq|$self->{message}|;
	}

	close(OUT);

	return "";
  
}


sub encode_base64 ($;$) {
  use MIME::Base64;
  return MIME::Base64::encode($_[0], $_[1]);
  
}


1;

