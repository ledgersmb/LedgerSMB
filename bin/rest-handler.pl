#!/usr/bin/perl
package LedgerSMB::Rest;

=head1 NAME

LedgerSMB::Handlers::REST_Handler - REST handler for new code sections

=head1 SYNPOSIS

This is invoked via http, for example, to get a customer:

  GET www.myhost.com/ledgersmb/rest/1.4/my_company/customer/242.xml

To attach a new note, you might post an xml document to:

  POST www.myhost.com/ledgersmb/rest/1.4/my_company/customer/242/note.xml

Similarly to retrieve all notes for this customer:

  GET www.myhost.com/ledgersmb/rest/1.4/my_company/customer/242/note.xml

=head1 DESCRIPTION

=head2 URL Syntax

Everything before the /rest/ part of the URL is ignored.  After the /rest/
the url is given fixed semantic meaning based on the following pattern:
[company_name]/[object class][/id][/subresource][.format]

=head2 Authentication

Authentication information is provided using HTTP authentication headers.
Currently only HTTP Basic is supported though Kerberos could be supported with
a little effort. Please use it over SSL.

=head2 Delegated Format Parsing API

Every supported format handler supports two methods:  from_input and to_output.
The former transforms the format into a hashref, and the latter transforms a
hashref into a file of this format.  It could do so using Template Toolkit or
some other manner and so arbitrary formats are thus supported.

The format can be determined either by the CONTENT_TYPE header or the
extension.  Currently the system just checks the portion following the slash
and uses that.  Future versions may perform a lookup against the mime_types
table to look up handlers.  Sub-types can be indicated using an underscore, so
text/xml_mydialect would dispatch to the XML_mydialect handler if available and
if not to the XML handler.  This would be eqivaent to an extension of
.xml_mydialect.

The reason for the subtyping options is that this allows for one to create, for
example, an EDI handler and specify subtypes either as subclasses or as
additional options within the same class.

=head2 Delegated Object Handling API

Every supported object class MUST support the following methods (even if they
do nothing but throw an error):

=over

=item GET

Retrieves one or more records.

=item PUT

Insert or updates a record.

=item POST

If an ID is provided this should check to see if the record exists, and if so
throw an error.  If it does not, or if it does not exist, then create it.

=item DELETE (optional)

Deletes a resource if this is supported.

=back

If any of the above are not supported, and a request comes in that would hit
that method, a 403 Forbidden error is returned.

In addition each subresource should get its own method, optionally suffixed
with _GET, _PUT, _POST, or _DELETE.  These are deleaged first to the suffixed
version, and if that i snot found to the subresource name directly.  If that is
not found, we throw a 404 error.

Each method is pashed a hashref which contains:

=over

=item dbh

Database connection handle to the company db

=item class_name

Top level class.

=item id

ID field for that object

=item subresource

Subresource field name

=item args

Hashref of query string args

=item payload

This is a hashref returned from the format handler.

=back

=head2 Error Handling

Other scripts in this workflow should throw errors using die, and include both
the http error number and a brief description.  Examples might be:

 die '401  Unauthorized';

or

 die "500  Error from function: $DBH->errstr";

=head1 NOTES

This is currently only supported ober CGI.  Once the old code is eliminated, we
plan to port the entire application over to a more flexible framework.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 LedgerSMB Core Team.  This file is licensed under the GNU
General Public License version 2, or at your option any later version.  Please
see the included License.txt for details.

=cut

package LedgerSMB::REST_Handler;

use FindBin;
BEGIN {
  lib->import($FindBin::Bin) unless $ENV{mod_perl}
}

use DBI;
use CGI::Simple;
use Try::Tiny;
use LedgerSMB::App_State;
use LedgerSMB::Locale;
use LedgerSMB::Sysconfig;
use LedgerSMB::Template::TXT;
use strict;
use warnings;

# Some modules depend on locale being set for error handling, but we want to
# ensure that only the default language is used to ensure nothing strange
# happens.  So hard-coded to English here.  --CT
my $locale = LedgerSMB::Locale->get_handle('en');
$LedgerSMB::App_State::Locale = $locale;
$LedgerSMB::App_State::User = {numberformat => '1000.00',
                                 dateformat => 'YYYY-MM-DD'};

Log::Log4perl::init(\$LedgerSMB::Sysconfig::log4perl_config);
my $logger = Log::Log4perl->get_logger('LedgerSMB::Handler');
$logger->debug("Begin");

process_request();

$logger->debug("End");

# Note:  Indenting try/catch only two characters here because it wraps all
# substantive logic in the function.  -CT
sub process_request{

  try {
    my $request = get_request_properties();

    my $format = lc($request->{format});
    my $return_info;

    if (! eval "require LedgerSMB::REST_Format::" . $format) {
       eval "require LedgerSMB::REST_Format::" . $request->{format}
    }
    my $fmtpackage = "LedgerSMB::REST_Format::" . $format;

    if ($request->{payload}){
        if ($fmtpackage->can('from_input')){
            $request->{payload} = $fmtpackage->can('from_input')->($request);
        } else {
            die '415 Unsupported Media Type';
        }
    }

    my $classpkg = $request->{class_name};
    if (!eval "require $classpkg"){
       warn $!;
       warn $@;
       warn "failed require $classpkg";
       return error_handler('404 Class Not Found');
    }

    my $restobj = $classpkg;


    if ($classpkg->can(lc($request->{method}))){
        $return_info = $classpkg->can(lc($request->{method}))->($request);
    } else {
        die '405 Method Not Allowed';
    }

    my $content;
    my $ctype;

    # We are going to re-use template escaping logic here.  Since TXT generally
    # does not escape values but just returns a sanitized data tree (calling
    # to_output where appropriate, we will use that.  --CT

    $return_info = LedgerSMB::Template::TXT::preprocess($return_info);

    if ($return_info){
        if ($fmtpackage->can('to_output')){
            $content = $fmtpackage->can('to_output')->($request, $return_info);
        } else {
            warn 'cannot output';
            return error_handler('415 Unsupported Media Type');
        }
    }
    if ($fmtpackage->can('mime_type')){
        $ctype = $fmtpackage->can('mime_type')->();
    }

    return output({state => '200 Success',
                 content => $content,
                 content_type => $ctype});
  } catch {
    return error_handler($_);
  }
}

sub error_handler {
    my ($error) = @_;
    warn $error;
    # Sometimes the two lines below can be useful for debugging.  Note they
    # turn all errors into internal server errors and populate the logs with
    # all kinds of stuff --CT
    # use Carp;
    # Carp::confess();
    my $content = $error;
    $content =~ s/^\d\d\d\s//;
    $error =~ s/\n/: /m;
    $error =~ s/ at .*//;
    if ($error !~ /^\d\d\d/){
        $error = "500 $error";
    }
    output({state => $error, content => $content, });
}

# Isolating request-> hashref logic so that it is easier to port to other
# environments --CT

sub get_request_properties {
    my $cgi = CGI::Simple->new();
    use LedgerSMB::Auth;

    my $creds = LedgerSMB::Auth::get_credentials();
    my $request = {};
    my $url = $ENV{REQUEST_URI};

    $request->{args} = $cgi->Vars();
    $request->{method} = $ENV{REQUEST_METHOD};
    $request->{payload} = $cgi->param( "$request->{method}DATA" );
    $url =~ s#.*/(rest-handler.pl|rest)/(.*)#$2#;
    $url =~ s|\.([^/.?]*)(\?.*)?$||;
    $request->{format} = $1;

    my @components = split /\//, $url;
    my $version = shift @components;
    my $company = shift @components;
    die "400 Unsupported version ($version)" if ($version ne '1.4');
    $LedgerSMB::App_State::DBH = DBI->connect(
        "dbi:Pg:dbname=$company",
        "$creds->{login}", "$creds->{password}",
            { AutoCommit => 0 }
    );
    $request->{args}->{dbh} = $LedgerSMB::App_State::DBH;

    if (!$request->{args}->{dbh}) {
           die '401 Unauthorized';
    }

    if (!$request->{format}){
        my $fmt = $ENV{CONTENT_TYPE};
        $fmt =~ /([^\/]*$)/;
        $request->{format} = $1;
    }

    $request->{classes} = {};
    $request->{class_name} = 'LedgerSMB::REST_Class';
    while (@components) {
        my $class = shift @components;
        my $id = shift @components;
        $id = undef if $id eq 'all';
        $request->{class_name} .= "::$class";
        $request->{classes}->{$request->{class_name}} = $id;
    }

    return $request;
}

# Isolating output routine
sub output {
    my ($args) = @_;
    my $ctype;
    my $cgi = CGI::Simple->new();

    if ($args->{content_type}){
        $ctype = $args->{content_type};
    } else {
        $ctype = 'text/text';
    }
    print $cgi->header($ctype, $args->{state});
    $cgi->put($args->{content});
}

1;
