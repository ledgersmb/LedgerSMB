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
# point of sale script
#
#######################################################################

use LedgerSMB::AA;
use LedgerSMB::IS;
use LedgerSMB::RP;

require "$form->{path}/ar.pl";
require "$form->{path}/is.pl";
require "$form->{path}/rp.pl";
require "$form->{path}/pos.pl";

# customizations
if (-f "$form->{path}/custom_pos.pl") {
  eval { require "$form->{path}/custom_pos.pl"; };
}
if (-f "$form->{path}/$form->{login}_pos.pl") {
  eval { require "$form->{path}/$form->{login}_pos.pl"; };
}

1;
# end
