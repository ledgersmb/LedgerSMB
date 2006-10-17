#=====================================================================
# LedgerSMB 
# Small Medium Business Accounting software
# http://www.ledgersmb.org/
# 
#
# Copyright (C) 2006
# This work contains copyrighted information from a number of sources all used
# with permission.  It is released under the GNU General Public License 
# Version 2 or, at your option, any later version.  See COPYRIGHT file for 
# details.

#  This is a simple abstraction layer allowing other session handling mechanisms
# (For example Kerberos tickets) as the application progresses.
package Session;

use LedgerSMB::Sysconfig;

if (!${LSMBConfig::session}){
	${LSMBConfig::session} = 'DB';
}

require "LedgerSMB/Session/".${LSMBConfig::session}.".pm";
