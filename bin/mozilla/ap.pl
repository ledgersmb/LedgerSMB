#=====================================================================
# LedgerSMB 
# Small Medium Business Accounting software
# 
# See COPYRIGHT file for copyright information
#======================================================================
#
# This file has NOT undergone whitespace cleanup.
#
#======================================================================
#
# Accounts Payable
#
#======================================================================

use LedgerSMB::PE;
use LedgerSMB::IR;

require "$form->{path}/arap.pl";
require "$form->{path}/arapprn.pl";
require "$form->{path}/aa.pl";

$form->{vc} = 'vendor';
$form->{ARAP} = 'AP';

1;
# end of main

