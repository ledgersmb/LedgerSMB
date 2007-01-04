#!/usr/bin/perl

use LedgerSMB::RESTXML::Handler;

# To Enable the REST API,  Delete these 5 lines.
print "Content-type: text/plain\n\n";
print "REST API disabled by default until authentication is working correctly\n";
print "If you understand the security implications of this, and wish to enable the REST api\n";
print "Then open rest.pl, and remove these 5 lines";
exit;

LedgerSMB::RESTXML::Handler->cgi_handle();

=head1 NAME

rest.pl - RESTful interface to LedgerSMB

=head1 SUMMARY
	
	URLS that are working:
	[OK] GET rest.pl/Login/Customer/12345
	[  ] GET rest.pl/Login/Customer/CUSTOMERNUMBER
	[OK] GET rest.pl/Login/Customer_Search?_keyword=FOO

	[OK] GET rest.pl/Login/Part/12345
	[  ] GET rest.pl/Login/Part/PARTNUMBER
	[  ] GET rest.pl/Login/Part_Search?_keyword=red

	[  ] GET rest.pl/Login/SalesOrder/12345


=cut

