
=head1 NAME

LedgerSMB::Template - Template support module for LedgerSMB 

=head1 SYNOPSIS

This module renders templates.

=head1 METHODS

=over

=item new(user => \%myconfig, template => $string, format => 'HTML', [language => $string,] [include_path => $path]);

This command instantiates a new template:
template is the file name of the template to be processed.
format is the type of format to be used.  Currently only HTML is supported
language (optional) specifies the language for template selection.
include_path allows one to override the template directory and use this with user interface templates.

=item render($hashref)

This command renders the template and writes the result to standard output.  
Currently email and server-side printing are not supported.

=item output

This function outputs the rendered file in an appropriate manner.

=item my $bool = _valid_language()

This command checks for valid langages.  Returns 1 if the language is valid, 
0 if it is not.

=back

=head1 Copyright 2007, The LedgerSMB Core Team

This file is licensed under the GNU General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut

package LedgerSMB::Template;

use Error qw(:try);
use LedgerSMB::Sysconfig;
use LedgerSMB::Mailer;

sub new {
	my $class = shift;
	my $self = {};
	my %args = @_;

	$self->{myconfig} = $args{user};
	$self->{template} = $args{template};
	$self->{format} = $args{format};
	$self->{language} = $args{language};
	if ($args{outputfile}) {
		$self->{outputfile} =
			"${LedgerSMB::Sysconfig::tempdir}/$args{outputfile}";
	} else {
		$self->{outputfile} =
			"${LedgerSMB::Sysconfig::tempdir}/$args{template}-output";
	}
	$self->{include_path} = $args{path};
	$self->{locale} = $args{locale};

	bless $self, $class;

	if (!$self->{include_path}){
		$self->{include_path} = $self->{'myconfig'}->{'templates'};
		if (defined $self->{language}){
			if (!$self->_valid_language){
				throw Error::Simple 'Invalid language';
				return undef;
			}
			$self->{include_path} = "$self->{'include_path'}"
					."/$self->{language}"
					.";$self->{'include_path'}"
		}
	}


	return $self;
}

sub _valid_language {
	my $self = shift;
	if ($self->{language} =~ m#(/|\\|:|\.\.|^\.)#){
		return 0;
	}
	return 1;
}

sub render {
	my $self = shift;
	my $vars = shift;
	my $format = "LedgerSMB::Template::$self->{format}";

	eval "require $format";
	if ($@) {
		throw Error::Simple $@;
	}

	my $cleanvars = $format->can('preprocess')->($vars);
	if (UNIVERSAL::isa($self->{locale}, 'LedgerSMB::Locale')){
		$cleanvars->{text} = $self->{locale}->text();
	}

	$format->can('process')->($self, $cleanvars);
	return $format->can('postprocess')->($self);
}

sub output {
	my $self = shift;
	my %args = @_;
	my $method = $args{method} || $args{media};

	if ('email' eq lc $method) {
		$self->_email_output;
	} elsif ('print' eq lc $method) {
		$self->_lpr_output;
	} else {
		$self->_http_output;
	}
}

sub _http_output {
	my $self = shift;
	my $FH;

	if ($self->{mimetype} =~ /^text/) {
		print "Content-Type: $self->{mimetype}; charset=utf-8\n\n";
	} else {
		print "Content-Type: $self->{mimetype}\n\n";
	}
	open($FH, '<', $self->{rendered}) or
		throw Error::Simple 'Unable to open rendered file';
	while (<$FH>) {
		print $_;
	}
	close($FH);
	unlink($self->{rendered}) or
		throw Error::Simple 'Unable to delete output file';
	exit;
}

sub _email_output {
	my $self = shift;
	my $mail = new LedgerSMB::Mailer;
	#TODO stub
}

sub _lpr_output {
	my $self = shift;
	#TODO stub
}
1;
