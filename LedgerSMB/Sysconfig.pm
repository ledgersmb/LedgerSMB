#  This is the new configuration file for LedgerSMB.  Eventually all system 
# configuration directives will go here,  This will probably not fully replace
# the ledger-smb.conf until 1.3, however.

package LSMBConfig;

$session='DB';
$logging=0; # No logging on by default

@io_lineitem_columns = qw(unit onhand sellprice discount linetotal);


1;
