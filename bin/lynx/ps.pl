######################################################################
# LedgerSMB Small Medium Business Accounting
# Copyright (c) 1999 - 2005
#
#  Author: DWS Systems Inc.
#     Web: http://sourceforge.net/projects/ledger-smb/
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

use SL::AA;
use SL::IS;
use SL::RP;

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
