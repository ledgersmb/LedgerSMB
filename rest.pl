#!/usr/bin/perl

use LedgerSMB::RESTXML::Handler;

# To Enable the REST API,  Delete these 3 lines.

print "Content-type: text/plain\n\n";
print "REST API disabled by default until authentication is working correctly";
exit;

LedgerSMB::RESTXML::Handler->cgi_handle();

=head1 NAME

rest.pl - RESTful interface to LedgerSMB

=head1 SUMMARY
	
	status
	[OK] GET rest.pl/Customer/12345
	[  ] GET rest.pl/Customer/CUSTOMERNUMBER
	[OK] GET rest.pl/Customer_Search?_keyword=FOO

	[OK] GET rest.pl/Part/12345
	[  ] GET rest.pl/Part/PARTNUMBER
	[  ] GET rest.pl/Part_Search?_keyword=red

	[  ] GET rest.pl/SalesOrder/12345


=cut

