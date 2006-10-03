
package CreditCard;
use LedgerSMB::CreditCard::Config;
BEGIN { 
	$gateway_module =  ${Config::gateway_module};
	require "LedgerSMB/CreditCard/$gateway_module.pm";
	import $gateway_module qw(sale credit); 
}

