package LedgerSMB::RESTXML::Handler;
use strict;
use warnings;
use Carp;
use LedgerSMB::User;
use LedgerSMB::Sysconfig;
use LedgerSMB::Log;
use Scalar::Util qw(blessed);
use DBI;

=head3 cgi_handle

CGI_handle is the gateway for the RESTful lsmb API.

=head3 NOTES


=cut

sub cgi_handle { 
	my $self = shift;
	
	my $method = $ENV{REQUEST_METHOD};
	my $pathinfo = $ENV{PATH_INFO};
	
	#pull off the leading slash, we need it in the form document/arguments/foo
	$pathinfo =~ s#^/##;
	

	my $function = 'handle_'.lc($method);
	my ($user, $module, @args) = split	'/',$pathinfo;
	$user  = LedgerSMB::User->fetch_config($user);	
	
	my $dbh = $self->connect_db($user);	

	# non-word characters are forbidden, usually a sign of someone being sneaky.
	$module =~ s#\W##;
	
	my $document_module = $self->try_to_load($module);

	if($document_module) { 
		if($document_module->can($function)) { 
			my $returnValue = $document_module->$function({dbh=>$dbh, args=>\@args, handler=>$self, user=>$user});	

			#return $self->return_serialized_response($returnValue);

		} else { 
			return $self->unsupported("$module cannot handle method $method");
		}
	} else { 
		return $self->not_found("Could not find a handler for document type $module: <pre>$@</pre>");
	}
}

sub cgi_report_error { 
	my $self = shift;
	my $message = shift;
	my $code = shift||500;
	
	print "Status: $code\n";
	print "Content-Type: text/html\n\n";
	print "<html><body>\n";
	print "<h1>REST API error</h1>";
	print "<blockquote>$message</blockquote>";
	print "</body></html>";
}
sub cgi_read_query { 
	my $self = shift;
	
	use CGI;
	my $cgi = CGI->new();

	return $cgi;
}
# ------------------------------------------------------------------------------------------------------------------------

=head3 try_to_load

try_to_load will try to load a RESTXML document handler module.  returns undef
if it cannot load the given module for any reason.  passed the type of RESTXML
document to try to load.  returns a blessed anonymous hashref if the module
*can*, and is successfully loaded.

=cut

sub try_to_load { 
	my $self = shift;
	my $module = shift;

	eval qq{ 
		use LedgerSMB::RESTXML::Document::$module;
	};
	if($@) { 
		warn "Cannot load $module: $@" unless $@ =~ /Can't locate LedgerSMB\//i;

		return undef;
	} else { 
		return bless {}, "LedgerSMB::RESTXML::Document::$module";
	} 
}

=head3 connect_db

Given  a user's config, returns a database connection handle.

=cut

sub connect_db { 
	my ($self, $myconfig) = @_;

	my $dbh = DBI->connect(
			$myconfig->{dbconnect}, $myconfig->{dbuser},
			$myconfig->{dbpasswd})
		or carp "Error connecting to the db :$DBI::errstr";

	return $dbh;
}

# lets see how far XML::Simple can take us.
use XML::Simple;
use Scalar::Util qw(blessed);

sub return_serialized_response { 
	my ($self, $response) = @_;

	print "Content-type: text/xml\n\n";

	if(blessed $response && $response->isa('XML::Twig::Elt')) { 
			print qq{<?xml version="1.0"?>\n};
			print $response->sprint();
	} else { 
		my $xs = XML::Simple->new(NoAttr=>1,RootName=>'LedgerSMBResponse',XMLDecl=>1);

		print $xs->XMLout($response);
	}

	return;
}

sub read_query { 
	my ($self) = @_;

	# for now.	
	return $self->cgi_read_query();
}

# =------------------------- POSSIBLE WAYS FOR MODULES TO RESPOND.
sub respond { 
	my ($self, $data) = @_;

	return $self->return_serialized_response($data);
}

sub not_found { 
	my ($self, $message) = @_;

	$self->cgi_report_error($message,404);
}

sub unsupported { 
	my ($self, $message) = @_;
	$self->cgi_report_error($message, 501)
}

sub error { 
	my ($self, $message) = @_;

	$self->cgi_report_error($message,500);
}

1;
