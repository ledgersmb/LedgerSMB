
=head1 NAME

LedgerSMB::Template - Template support module for LedgerSMB 

=head1 SYNOPSIS

This module renders templates.

=head1 METHODS

=over

=item new(user => \%myconfig, template => $string, format => $string, [language => $string], [include_path => $path], [no_auto_output => $bool], [method => $string], [no_escape => $bool], [debug => $bool] );

This command instantiates a new template:

=over

=item template

The name of the template file to be processed.

=item format

The format to be used.  Currently HTML, PS, PDF, TXT and CSV are supported.

=item language (optional)

The language for template selection.

=item include_path (optional)

Overrides the template directory.  Used with user interface templates.

=item no_auto_output (optional)

Disables the automatic output of rendered templates.

=item no_escape (optional)

Disables escaping on the template variables.

=item debug (optional)

Enables template debugging.

With the TT-based renderers, HTML, PS, PDF, TXT, and CSV, the portion of the
template to get debugging messages is to be surrounded by
<?lsmb DEBUG format 'foo' ?> statements.  Example:

    <tr><td colspan="<?lsmb columns.size ?>"></td></tr>
    <tr class="listheading">
  <?lsmb FOREACH column IN columns ?>
  <?lsmb DEBUG format '$file line $line : [% $text %]' ?>
      <th class="listtop"><?lsmb heading.$column ?></th>
  <?lsmb DEBUG format '' ?>
  <?lsmb END ?>
    </tr>

=item method/media (optional)

The output method to use, defaults to HTTP.  Media is a synonym for method

=back

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
	$self->{format} = 'PS' if lc $self->{format} eq 'postscript';
	$self->{language} = $args{language};
	$self->{no_escape} = $args{no_escape};
	$self->{debug} = $args{debug};
	if ($args{outputfile}) {
		$self->{outputfile} =
			"${LedgerSMB::Sysconfig::tempdir}/$args{outputfile}";
	} else {
		$self->{outputfile} =
			"${LedgerSMB::Sysconfig::tempdir}/$args{template}-output-$$";
	}
	$self->{include_path} = $args{path};
	$self->{locale} = $args{locale};
	$self->{noauto} = $args{noauto};
	$self->{method} = $args{method};
	$self->{method} ||= $args{media};

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

	my $cleanvars;
	if ($self->{no_escape}) {
		$cleanvars = $vars;
	} else {
		$cleanvars = $format->can('preprocess')->($vars);
	}

	if (UNIVERSAL::isa($self->{locale}, 'LedgerSMB::Locale')){
		$cleanvars->{text} = sub { return $self->{locale}->text(@_)};
	}

	$format->can('process')->($self, $cleanvars);
	#return $format->can('postprocess')->($self);
	my $post = $format->can('postprocess')->($self);
	if (!$self->{'noauto'}) {
		$self->output;
	}
	return $post;
}

sub output {
	my $self = shift;
	my %args = @_;
	my $method = $self->{method} || $args{method} || $args{media};

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
	open($FH, '<:bytes', $self->{rendered}) or
		throw Error::Simple 'Unable to open rendered file';
	my $data;
	{
		local $/;
		$data = <$FH>;
	}
	close($FH);
	binmode STDOUT, ':bytes';
	print $data;
	binmode STDOUT, ':utf8';
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
