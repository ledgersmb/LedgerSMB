=head1 NAME

LedgerSMB::Template - Template support module for LedgerSMB 

=head1 SYOPSIS

This module renders templates to provide HTML interfaces.  LaTeX support
forthcoming.

=head1 METHODS

=item new(user => \%myconfig, template => $string, format => 'HTML', [language => $string,] [include_path => $path]);

	This command instantiates a new template:
	template is the file name of the template to be processed.
	format is the type of format to be used.  Currently only HTML is supported
	language (optional) specifies the language for template selection.
	include_path allows one to override the template directory and use this with user interface templates.

=item render($hashref)

This command renders the template and writes the result to standard output.  
Currently email and server-side printing are not supported.

=item my $bool = _valid_language()

This command checks for valid langages.  Returns 1 if the language is valid, 
0 if it is not.

=head1 Copyright 2007, The LedgerSMB Core Team

This file is licensed under the Gnu General Public License version 2, or at your
option any later version.  A copy of the license should have been included with
your software.

=cut
use Error qw(:try);
use Template;
use LedgerSMB::Sysconfig;

package LedgerSMB::Template;

sub new {
	my $class = shift;
	my $self = {};
	my %args = @_;

	$self->{myconfig} = $args{user};
	$self->{template} = $args{template};
	$self->{format} = $args{format};
	$self->{language} = $args{language};
	$self->{output} = '';
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
	my $template;

	$template = Template->new({
		INCLUDE_PATH => $self->{include_path},
		START_TAG => quotemeta('<?lsmb'),
		END_TAG => quotemeta('?>'),
		DELIMITER => ';',
		}) || throw Error::Simple Template->error(); 

	eval "require LedgerSMB::Template::$self->{format}";
	if ($@) {
		throw Error::Simple $@;
	}

	my $cleanvars = &{"LedgerSMB::Template::$self->{format}::preprocess"}($vars);
	if (UNIVERSAL::isa($self->{locale}, 'LedgerSMB::Locale')){
		$cleanvars->{text} = \&$self->{locale}->text();
	}
	if (not $template->process(
		&{"LedgerSMB::Template::$self->{format}::get_template"}($self->{template}), 
			$cleanvars, \$self->{output}, binmode => ':utf8')) {
		throw Error::Simple $template->error();
	}

	&{"LedgerSMB::Template::$self->{format}::postprocess"}($self);

	return $self->{output};
}

1;
