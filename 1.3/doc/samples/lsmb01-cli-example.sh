#!/bin/bash
#######################################################################
#
# lsmb01-cli-example.sh
# Copyright (C) 2006. Louis B. Moore
#
# $Id: $
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

NOW=`pwd`

echo -n "Ledger-SMB login: "
read LSLOGIN
echo

echo -n "Ledger-SMB password: "
stty -echo
read LSPWD
stty echo
echo

ARG="login=${LSLOGIN}&password=${LSPWD}&path=bin&action=search&db=customer"

LGIN="login=${LSLOGIN}&password=${LSPWD}&path=bin&action=login"
LGOT="login=${LSLOGIN}&password=${LSPWD}&path=bin&action=logout"

cd /usr/local/ledger-smb

./login.pl $LGIN 2>&1  > /dev/null
./ct.pl $ARG
./login.pl $LGOT 2>&1  > /dev/null

cd $NOW

exit 0


 	  	 
