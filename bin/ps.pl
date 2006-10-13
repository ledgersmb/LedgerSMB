######################################################################
# LedgerSMB Small Medium Business Accounting
# http://www.ledgersmb.org/
#

# Copyright (C) 2006
# This work contains copyrighted information from a number of sources all used
# with permission.
#
# This file contains source code included with or based on SQL-Ledger which
# is Copyright Dieter Simader and DWS Systems Inc. 2000-2005 and licensed 
# under the GNU General Public License version 2 or, at your option, any later 
# version.  For a full list including contact information of contributors, 
# maintainers, and copyright holders, see the CONTRIBUTORS file.
#
# Original Copyright Notice from SQL-Ledger 2.6.17 (before the fork):
# Copyright (c) 1999 - 2005
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.org
#
#
#  Author: DWS Systems Inc.
#     Web: http://www.ledgersmb.org/
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
#######################################################################
#
# point of sale script
#
#######################################################################

use LedgerSMB::AA;
use LedgerSMB::IS;
use LedgerSMB::RP;

require "bin/ar.pl";
require "bin/is.pl";
require "bin/rp.pl";
require "bin/pos.pl";
require "pos.conf.pl";

# customizations
if (-f "bin/custom/pos.pl") {
  eval { require "bin/custom/pos.pl"; };
}
if (-f "bin/custom/$form->{login}_pos.pl") {
  eval { require "bin/custom/$form->{login}_pos.pl"; };
}

1;
# end
