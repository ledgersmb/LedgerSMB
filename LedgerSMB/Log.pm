=head1 NAME

LedgerSMB::Log - LedgerSMB logging and debugging framework

=head1 SYOPSIS

This module maintains a connection to the LedgerSMB log file 
(Seperate from the apche error log, for now)

=head1 METHODS

This module is loosly based on Apache::Log.

Available methods: (in order, most to least severe)

=over 4

=item emerg

=item alert

=item crit

=item error

=item warn

=item notice

=item info

=item debug

=item longmess

This uses Carp to make a debug message with the full stack backtrace, including function arguments, where Carp can infer them.

=item dump

This uses Data::Dumper to dump the contents of a data structure as a debug message.

=back

=cut

package LedgerSMB::Log;
use strict;
use warnings;
use IO::File;
use Data::Dumper;
use LedgerSMB::Sysconfig;
use Carp ();

our $VERSION = '1.0.0';

our $fh;

sub print { 
	if (!$LedgerSMB::Sysconfig::logging){
		return 0;
	}
	shift;
	unless($fh) { 
		# TODO: this is grosly wrong, but so is this module in the first place.
		# the log messages *should* end up in the apache log, but that will
		# hopefully be corrected in the future.

		$fh=IO::File->new('>>users/ledger-smb.log');
		$fh->autoflush(1);
		__PACKAGE__->print('general',"Log file opened");
	}

	$fh->print(sprintf('[%s] [%s] %i %s',
				scalar(localtime),
				+shift,
				$$,
				join(' ',@_))."\n");
}


sub emerg { shift->print('emerg',@_) }
sub alert { shift->print('alert',@_) }
sub crit { shift->print('crit',@_) }
sub error { shift->print('error',@_) }
sub warn { shift->print('warn',@_) }
sub notice { shift->print('notice',@_) }
sub info { shift->print('info',@_) }
sub debug { shift->print('debug',@_) }

sub longmess { shift->print('debug',Carp::longmess(@_)) }

sub dump { 
	my $self = shift;
	my $d = Data::Dumper->new([@_]);
	$d->Sortkeys(1);
	$self->print('debug',$d->Dump());
}

1;
