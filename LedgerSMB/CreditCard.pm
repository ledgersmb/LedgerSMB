#=====================================================================
# LedgerSMB
# Small Medium Business Accounting software
# http://www.ledgersmb.org/
# Copyright (C) 2006
# This work contains copyrighted information from a number of sources all used
# with permission.
#
# This file contains source code included with or based on SQL-Ledger which
# is Copyright Dieter Simader and DWS Systems Inc. 2000-2005 and licensed
# under the GNU General Public License version 2 or, at your option, any later
# version.  For a full list including contact information of contributors,
# maintainers, and copyright holders, see the CONTRIBUTORS file.

# POS Credit card processing-- could be extended for ecommerce

package CreditCard;
use LedgerSMB;
use LedgerSMB::DBObject;

our @ISA qw(LedgerSMB::DBObject);

# use LedgerSMB::CreditCard::Config;  # moving elsewhere

## TODO:  Add code for credit card number validation and the like

1;

