#=====================================================================
# LedgerSMB Small Medium Business Accounting
# Copyright (c) 2000
#
#  Author: DWS Systems Inc.
#     Web: http://sourceforge.net/projects/ledger-smb/
#
#  Contributors:
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
#======================================================================
#
# Accounts Receivable
#
#======================================================================

use SL::PE;
use SL::IS;

require "$form->{path}/arap.pl";
require "$form->{path}/arapprn.pl";
require "$form->{path}/aa.pl";

$form->{vc} = 'customer';
$form->{ARAP} = 'AR';

1;
# end of main

